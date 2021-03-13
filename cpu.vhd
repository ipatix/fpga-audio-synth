-- TODO: implement lb and lhw


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
    port
    (
        clk : in std_logic;
        reset : in std_logic;

        gpi : in std_logic_vector (7 downto 0);
        gpo : out std_logic_vector (7 downto 0);

        uart_in : in std_logic;

        ac_adr0 : out std_logic;
        ac_adr1 : out std_logic;
        ac_gpio0 : out std_logic;  -- i2s miso
        ac_gpio1 : in std_logic;   -- i2s mosi
        ac_gpio2 : in std_logic;   -- i2s_bclk
        ac_gpio3 : in std_logic;   -- i2s_lr
        ac_mclk : out std_logic;
        ac_sck : out std_logic;
        ac_sda : inout std_logic
    );
end cpu;

architecture behav of cpu is
    -- main
    signal clk_48 : std_logic;

    -- component "pc"
    signal pc_en : std_logic;
    signal pc_load : std_logic;
    signal pc_load_val : std_logic_vector(31 downto 0);
    signal pc_addr : std_logic_vector(31 downto 0);

    -- component "regfile"
    signal rf_addr_reg_a : std_logic_vector(4 downto 0);
    signal rf_addr_reg_b : std_logic_vector(4 downto 0);
    signal rf_out_reg_a : std_logic_vector(31 downto 0);
    signal rf_out_reg_b : std_logic_vector(31 downto 0);
    signal rf_wr_addr : std_logic_vector(4 downto 0);
    signal rf_wr_en : std_logic;
    signal rf_wr_data : std_logic_vector(31 downto 0);

    -- component "alu"
    signal alu_input_a : std_logic_vector(31 downto 0);
    signal alu_input_b : std_logic_vector(31 downto 0);
    signal alu_ctrl : std_logic_vector(3 downto 0);
    signal alu_output : std_logic_vector(31 downto 0);
    signal alu_zero : std_logic;
    signal alu_not_negative : std_logic;

    -- component "data_mem"
    signal dmem_rd_addr : std_logic_vector(31 downto 0);
    signal dmem_rd_data : std_logic_vector(31 downto 0);
    signal dmem_rd_en : std_logic;
    signal dmem_wr_addr : std_logic_vector(31 downto 0);
    signal dmem_wr_data : std_logic_vector(31 downto 0);
    signal dmem_wr_en : std_logic;
    signal dmem_byte_read : std_logic;
    signal dmem_byte_write : std_logic;

    -- component "instr_mem"
    signal imem_rd_addr : std_logic_vector(31 downto 0);
    signal imem_rd_data : std_logic_vector(31 downto 0);
    signal imem_wr_en : std_logic;
    signal imem_wr_addr : std_logic_vector(31 downto 0);
    signal imem_wr_data : std_logic_vector(31 downto 0);

    -----------------------------------------------
    --------------- PIPELINE STAGES ---------------
    -----------------------------------------------

    -- stage inputs

    -------------------- ID -----------------------
    -- in
    signal id_instruction : std_logic_vector(31 downto 0);
    -- out
    signal id_branch : std_logic; -- WB
    signal id_mem_to_reg : std_logic;
    signal id_reg_write : std_logic;
    signal id_mem_write : std_logic; -- M
    signal id_mem_read : std_logic;
    signal id_reg_dst : std_logic; -- EX
    signal id_alu_op : std_logic_vector(3 downto 0);
    signal id_alu_src : std_logic;
    signal id_alu_src_shift : std_logic;
    signal id_imm_signed : std_logic;

    signal id_mem_byte_read : std_logic;
    signal id_mem_byte_write : std_logic;
    -- passthrough
    signal id_pc_addr : std_logic_vector(31 downto 0);

    -------------------- EX -----------------------
    -- in
    signal ex_alu_src : std_logic;
    signal ex_alu_src_shift : std_logic;
    signal ex_alu_op : std_logic_vector(3 downto 0);
    signal ex_reg_dst : std_logic;

    signal ex_reg_rs : std_logic_vector(4 downto 0); -- 25 downto 21
    signal ex_reg_rt : std_logic_vector(4 downto 0); -- 20 downto 16
    signal ex_reg_rd : std_logic_vector(4 downto 0); -- 15 downto 11

    signal ex_rf_out_reg_a : std_logic_vector(31 downto 0);
    signal ex_rf_out_reg_b : std_logic_vector(31 downto 0);
    signal ex_immediate : std_logic_vector(31 downto 0);
    -- out
    signal ex_branch_offset : std_logic_vector(31 downto 0);
    -- passthrough
    signal ex_branch : std_logic;
    signal ex_pc_addr : std_logic_vector(31 downto 0);
    signal ex_mem_to_reg : std_logic;

    signal ex_mem_write : std_logic;
    signal ex_mem_read : std_logic;
    signal ex_reg_write : std_logic;

    signal ex_mem_byte_read : std_logic;
    signal ex_mem_byte_write : std_logic;
    -------------------- MEM ----------------------
    -- in
    signal mem_branch : std_logic;
    signal mem_branch_offset : std_logic_vector(31 downto 0);
    signal mem_zero : std_logic;
    signal mem_mem_write : std_logic;
    signal mem_mem_read : std_logic;
    -- out
    --signal mem_pc_src : std_logic;
    -- passthrough
    signal mem_reg_write : std_logic;
    signal mem_alu_output : std_logic_vector(31 downto 0);
    signal mem_write_register : std_logic_vector(4 downto 0);
    signal mem_mem_to_reg : std_logic;
    -------------------- WB -----------------------
    -- in
    signal wb_mem_to_reg : std_logic;
    signal wb_alu_output : std_logic_vector(31 downto 0);

    component clk_wiz_0
    port 
    (
        clk_in_100 : in std_logic;
        clk_out_100 : out std_logic;
        clk_out_48 : out std_logic;
        reset : in std_logic;
        locked : out std_logic
    );
    end component;
begin
    zed_clk: clk_wiz_0 port map
    (
        clk_in_100 => clk,
        clk_out_100 => open,
        clk_out_48 => clk_48,
        reset => '0',
        locked => open
    );

    pc_instance: entity work.pc port map
    (
        en => pc_en,
        reset => reset,
        clk => clk_48,
        load => pc_load,
        load_val => pc_load_val,
        addr => pc_addr
    );

    rf_instance: entity work.regfile port map
    (
        addr_reg_a => rf_addr_reg_a,
        addr_reg_b => rf_addr_reg_b,
        out_reg_a => rf_out_reg_a,
        out_reg_b => rf_out_reg_b,
        wr_addr => rf_wr_addr,
        wr_en => rf_wr_en,
        wr_data => rf_wr_data,
        reset => reset,
        clk => clk_48
    );

    alu_instance: entity work.alu port map
    (
        input_a => alu_input_a,
        input_b => alu_input_b,
        ctrl => alu_ctrl,
        output => alu_output,
        zero => alu_zero,
        not_negative => alu_not_negative
    );

    sysbus_instance: entity work.system_bus port map
    (
        clk => clk_48,
        reset => reset,
        rd_addr => dmem_rd_addr,
        rd_data => dmem_rd_data,
        rd_en => dmem_rd_en,
        wr_addr => dmem_wr_addr,
        wr_data => dmem_wr_data,
        wr_en => dmem_wr_en,
        byte_read => dmem_byte_read,
        byte_write => dmem_byte_write,

        gpi => gpi,
        gpo => gpo,

        uart_in => uart_in,

        ac_adr0 => ac_adr0,
        ac_adr1 => ac_adr1,
        ac_gpio0 => ac_gpio0,
        ac_gpio1 => ac_gpio1,
        ac_gpio2 => ac_gpio2,
        ac_gpio3 => ac_gpio3,
        ac_mclk => ac_mclk,
        ac_sck => ac_sck,
        ac_sda => ac_sda
    );

    imem_instance: entity work.instr_mem port map
    (
        clk => clk_48,
        rd_addr => imem_rd_addr,
        rd_data => imem_rd_data,
        wr_en => imem_wr_en,
        wr_addr => imem_wr_addr,
        wr_data => imem_wr_data
    );

    -----------------------------------------------
    --------------- PIPELINE STAGES ---------------
    -----------------------------------------------


    ----------------- IF stage combinatorial ------
    pc_en <= '1';
    imem_rd_addr <= pc_addr;
    imem_wr_addr <= x"00000000";
    imem_wr_data <= x"00000000";
    imem_wr_en <= '0';




    ----------------- IF/ID stage clocked ---------

    id_instruction <= imem_rd_data; -- <= this is already clocked by imem
    process(clk_48)
    begin
        if (rising_edge(clk_48)) then
            if (reset = '1') then
                id_pc_addr <= x"00000000";
            else
                id_pc_addr <= std_logic_vector(unsigned(pc_addr) + 4);
            end if;
        end if;
    end process;




    ----------------- ID stage combinatorial ------
    rf_addr_reg_a <= id_instruction(25 downto 21); -- Rs
    rf_addr_reg_b <= id_instruction(20 downto 16); -- Rt

    -- TODO: write register, write data, decoding

    process(id_instruction)
    begin
        -- if not set, unset all signals
        id_branch <= '0';
        id_mem_to_reg <= '0';
        id_reg_write <= '0';
        id_mem_read <= '0';
        id_mem_write <= '0';
        id_reg_dst <= '0';
        id_alu_op <= "0000";
        id_alu_src <= '0';
        id_alu_src_shift <= '0';
        id_mem_byte_read <= '0';
        id_mem_byte_write <= '0';
        id_imm_signed <= '0';

        -- case of opcode type
        case id_instruction(31 downto 26) is
            when "000000" => -- R-Type 0x00
                id_reg_write <= '1';
                id_reg_dst <= '1';
                -- case of function type
                case id_instruction(5 downto 0) is
                    when "000000" => -- SLL 0x00
                        id_alu_op <= "1000";
                        id_alu_src_shift <= '1';
                    when "000011" => -- SRA 0x03
                        id_alu_op <= "1010";
                        id_alu_src_shift <= '1';
                    when "000010" => -- SRL 0x02
                        id_alu_op <= "1001";
                        id_alu_src_shift <= '1';
                    when "000100" => -- SLLV 0x04
                        id_alu_op <= "1000";
                    when "000110" => -- SRLV 0x06
                        id_alu_op <= "1001";
                    when "100100" => -- AND 0x24
                        id_alu_op <= "0000";
                    when "100101" => -- OR  0x25
                        id_alu_op <= "0001";
                    when "100000" => -- ADD 0x20
                        id_alu_op <= "0010";
                    when "100001" => -- ADDU 0x21
                        id_alu_op <= "0010";
                    when "100110" => -- XOR 0x26
                        id_alu_op <= "0101";
                    when "100010" => -- SUB 0x22
                        id_alu_op <= "0110";
                    when "101010" => -- SLT 0x2A
                        id_alu_op <= "0111";
                    when "100111" => -- NOR 0x27
                        id_alu_op <= "1100";
                    when others => -- illegal instruction
                        assert false report "illegal R type instruction";
                        id_alu_op <= "1111";
                end case;
            when "001111" => -- LUI 0x0F
                id_alu_op <= "0100";
                id_alu_src <= '1';
                id_reg_write <= '1';
            when "001000" => -- ADDI 0x08
                id_alu_op <= "0010";
                id_alu_src <= '1';
                id_reg_write <= '1';
                id_imm_signed <= '1';
            when "001001" => -- ADDIU 0x09
                id_alu_op <= "0010";
                id_alu_src <= '1';
                id_reg_write <= '1';
                id_imm_signed <= '1';
            when "001100" => -- ANDI 0x0C
                id_alu_op <= "0000";
                id_alu_src <= '1';
                id_reg_write <= '1';
            when "001101" => -- ORI 0x0D
                id_alu_op <= "0001";
                id_alu_src <= '1';
                id_reg_write <= '1';
            when "001110" => -- XORI 0x0E
                id_alu_op <= "0101";
                id_alu_src <= '1';
                id_reg_write <= '1';
            when "000100" => -- BEQ 0x04
                id_alu_op <= "0110";
                id_branch <= '1';
                id_imm_signed <= '1';
            when "100000" => -- LB 0x20
                id_alu_op <= "0010";
                id_alu_src <= '1';
                id_mem_to_reg <= '1';
                id_reg_write <= '1';
                id_mem_read <= '1';
                id_mem_byte_read <= '1';
            when "101000" => -- SB 0x28
                id_alu_op <= "0010";
                id_alu_src <= '1';
                id_mem_write <= '1';
                id_mem_byte_write <= '1';
            when "100011" => -- LW 0x23
                id_alu_op <= "0010";
                id_alu_src <= '1';
                id_mem_to_reg <= '1';
                id_mem_read <= '1';
                id_reg_write <= '1';
            when "101011" => -- SW 0x2B
                id_alu_op <= "0010";
                id_alu_src <= '1';
                id_mem_write <= '1';
            when "011100" => -- MUL 0x1C
                id_alu_op <= "1110";
                id_reg_write <= '1';
                id_reg_dst <= '1';
            when others => -- illegal instruction
                assert false report "illegal instruction";
                id_alu_op <= "1111";
        end case;
    end process;

    ----------------- ID/EX stage clocked ---------
    process(clk_48)
    begin
        if (rising_edge(clk_48)) then
            if (reset = '1') then
                ex_pc_addr <= x"00000000";
                ex_rf_out_reg_a <= x"00000000";
                ex_rf_out_reg_b <= x"00000000";
                ex_immediate <= x"00000000";
                ex_reg_rs <= "00000";
                ex_reg_rt <= "00000";
                ex_reg_rd <= "00000";

                ex_branch <= '0';
                ex_mem_to_reg <= '0';
                ex_reg_write <= '0';
                ex_mem_write <= '0';
                ex_mem_read <= '0';
                ex_reg_dst <= '0';
                ex_alu_op <= "0000";
                ex_alu_src <= '0';
                ex_alu_src_shift <= '0';

                ex_mem_byte_read <= '0';
                ex_mem_byte_write <= '0';
            else
                ex_pc_addr <= id_pc_addr;
                ex_rf_out_reg_a <= rf_out_reg_a;
                ex_rf_out_reg_b <= rf_out_reg_b;
                if (id_imm_signed = '1') then
                    ex_immediate <= std_logic_vector(resize(signed(id_instruction(15 downto 0)), 32));
                else
                    ex_immediate <= std_logic_vector(resize(unsigned(id_instruction(15 downto 0)), 32));
                end if;
                ex_reg_rs <= id_instruction(25 downto 21);
                ex_reg_rt <= id_instruction(20 downto 16);
                ex_reg_rd <= id_instruction(15 downto 11);

                ex_branch <= id_branch;
                ex_mem_to_reg <= id_mem_to_reg;
                ex_reg_write <= id_reg_write;
                ex_mem_write <= id_mem_write;
                ex_mem_read <= id_mem_read;
                ex_reg_dst <= id_reg_dst;
                ex_alu_op <= id_alu_op;
                ex_alu_src <= id_alu_src;
                ex_alu_src_shift <= id_alu_src_shift;

                ex_mem_byte_read <= id_mem_byte_read;
                ex_mem_byte_write <= id_mem_byte_write;
            end if;
        end if;
    end process;




    --------------- EX stage combinatorial ---------
    -- now including forward logic
    ex_branch_offset <= std_logic_vector(shift_left(signed(ex_immediate), 2) + signed(ex_pc_addr));

    alu_input_a <= "000000000000000000000000000" & ex_immediate(10 downto 6) when ex_alu_src_shift = '1'
                   else mem_alu_output when mem_reg_write = '1' and mem_write_register = ex_reg_rs
                   else rf_wr_data when rf_wr_en = '1' and rf_wr_addr = ex_reg_rs
                   else ex_rf_out_reg_a;

    alu_input_b <= ex_immediate when ex_alu_src = '1' 
                   else mem_alu_output when mem_reg_write = '1' and mem_write_register = ex_reg_rt
                   else rf_wr_data when rf_wr_en = '1' and rf_wr_addr = ex_reg_rt
                   else ex_rf_out_reg_b;

    alu_ctrl <= ex_alu_op;




    -------------- EX/MEM stage clocked -------------
    process (clk_48)
    begin
        if (rising_edge(clk_48)) then
            if (reset = '1') then
                mem_branch <= '0';
                mem_branch_offset <= x"00000000";
                mem_zero <= '1';
                dmem_wr_data <= x"00000000";
                dmem_wr_en <= '0';
                dmem_rd_en <= '0';
                dmem_wr_addr <= x"00000000";
                dmem_rd_addr <= x"00000000";
                dmem_byte_read <= '0';
                dmem_byte_write <= '0';

                mem_reg_write <= '0';
                mem_alu_output <= x"00000000";
                mem_write_register <= "00000";
                mem_mem_to_reg <= '0';

                mem_mem_read <= '0';    -- are these even used?
                mem_mem_write <= '0';  -- are these even used?
            else
                mem_branch <= ex_branch;
                mem_branch_offset <= ex_branch_offset;
                mem_zero <= alu_zero;
                dmem_wr_data <= ex_rf_out_reg_b;
                dmem_wr_en <= ex_mem_write;
                dmem_rd_en <= ex_mem_read;
                dmem_wr_addr <= alu_output;
                dmem_rd_addr <= alu_output;
                dmem_byte_read <= ex_mem_byte_read;
                dmem_byte_write <= ex_mem_byte_write;

                mem_reg_write <= ex_reg_write;
                mem_alu_output <= alu_output;
                if (ex_reg_dst = '0') then
                    mem_write_register <= ex_reg_rt;
                else
                    mem_write_register <= ex_reg_rd;
                end if;
                mem_mem_to_reg <= ex_mem_to_reg;

                mem_mem_read <= ex_mem_read;    -- are these even used?
                mem_mem_write <= ex_mem_write;  -- are these even used?
            end if;
        end if;
    end process;




    -------------- MEM stage combinatorial ----------
    pc_load <= mem_zero and mem_branch;
    pc_load_val <= mem_branch_offset;





    ------------- MEM/WB stage clocked -------------- 
    process (clk_48)
    begin
        if (rising_edge(clk_48)) then
            if (reset = '1') then
                rf_wr_en <= '0';
                rf_wr_addr <= "00000";
                wb_alu_output <= x"00000000";
                wb_mem_to_reg <= '0';
            else
                rf_wr_en <= mem_reg_write;
                rf_wr_addr <= mem_write_register;
                wb_alu_output <= mem_alu_output;
                wb_mem_to_reg <= mem_mem_to_reg;
            end if;
        end if;
    end process;





    ----------------- WB stage combinatorial --------
    rf_wr_data <= dmem_rd_data when wb_mem_to_reg = '1' else wb_alu_output;

end architecture;
