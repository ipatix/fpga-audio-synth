library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system_bus is
    port
    (
        clk : in std_logic;
        reset : in std_logic;
        rd_addr : in std_logic_vector(31 downto 0);
        rd_data : out std_logic_vector(31 downto 0);
        rd_en : in std_logic;
        wr_addr : in std_logic_vector(31 downto 0);
        wr_data : in std_logic_vector(31 downto 0);
        wr_en : in std_logic;
        byte_read : in std_logic;
        byte_write : in std_logic;

        gpi : in std_logic_vector(7 downto 0);
        gpo : out std_logic_vector(7 downto 0);
        
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
end system_bus;

architecture behav of system_bus is
    type BUS_SOURCE is (BUS_DMEM, BUS_GPIO, BUS_UART, BUS_SOUND, BUS_INVALID);
    signal read_select : BUS_SOURCE;
    signal read_select_byte : std_logic;
    signal read_select_byte_addr : std_logic_vector(1 downto 0);
    signal write_select : BUS_SOURCE;

    signal gpio_rd_addr : std_logic_vector(31 downto 0);
    signal gpio_rd_data : std_logic_vector(31 downto 0);
    signal gpio_rd_en : std_logic;
    signal gpio_wr_addr : std_logic_vector(31 downto 0);
    signal gpio_wr_en : std_logic;

    signal dmem_rd_addr : std_logic_vector(31 downto 0);
    signal dmem_rd_data : std_logic_vector(31 downto 0);
    signal dmem_rd_en : std_logic;
    signal dmem_wr_addr : std_logic_vector(31 downto 0);
    signal dmem_wr_en : std_logic;

    signal uart_rd_addr : std_logic_vector(31 downto 0);
    signal uart_rd_data : std_logic_vector(31 downto 0);
    signal uart_rd_en : std_logic;
    signal uart_wr_addr : std_logic_vector(31 downto 0);
    signal uart_wr_en : std_logic;

    signal audio_rd_addr : std_logic_vector(31 downto 0);
    signal audio_rd_data : std_logic_vector(31 downto 0);
    signal audio_rd_en : std_logic;
    signal audio_wr_addr : std_logic_vector(31 downto 0);
    signal audio_wr_en : std_logic;

    signal rd_data_buf : std_logic_vector(31 downto 0);
begin
    gpio_instance: entity work.gpio port map
    (
        clk => clk,
        reset => reset,
        rd_addr => gpio_rd_addr,
        rd_data => gpio_rd_data,
        rd_en => gpio_rd_en,
        wr_addr => gpio_wr_addr,
        wr_data => wr_data,
        wr_en => gpio_wr_en,
        byte_write => byte_write,

        gpi => gpi,
        gpo => gpo
    );
    data_mem_instance: entity work.data_mem port map
    (
        clk => clk,
        reset => reset,
        rd_addr => dmem_rd_addr,
        rd_data => dmem_rd_data,
        rd_en => dmem_rd_en,
        wr_addr => dmem_wr_addr,
        wr_data => wr_data,
        wr_en => dmem_wr_en,
        byte_write => byte_write
    );
    uart_if_instance: entity work.uart_interface port map
    (
        clk => clk,
        reset => reset,
        rd_addr => uart_rd_addr,
        rd_data => uart_rd_data,
        rd_en => uart_rd_en,
        wr_addr => uart_wr_addr,
        wr_data => wr_data,
        wr_en => uart_wr_en,
        byte_write => byte_write,

        uart_in => uart_in
    );
    audio_synth_instance: entity work.audio_synth port map
    (
        clk => clk,
        reset => reset,
        rd_addr => audio_rd_addr,
        rd_data => audio_rd_data,
        rd_en => audio_rd_en,
        wr_addr => audio_wr_addr,
        wr_data => wr_data,
        wr_en => audio_wr_en,
        byte_write => byte_write,

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

    dmem_rd_addr <= (31 downto 14 => '0') & rd_addr(13 downto 0);
    dmem_wr_addr <= (31 downto 14 => '0') & wr_addr(13 downto 0);

    gpio_rd_addr <= (31 downto 4 => '0') & rd_addr(3 downto 0);
    gpio_wr_addr <= (31 downto 4 => '0') & wr_addr(3 downto 0);

    uart_rd_addr <= (31 downto 4 => '0') & rd_addr(3 downto 0);
    uart_wr_addr <= (31 downto 4 => '0') & wr_addr(3 downto 0);

    audio_rd_addr <= (31 downto 11 => '0') & rd_addr(10 downto 0);
    audio_wr_addr <= (31 downto 11 => '0') & wr_addr(10 downto 0);

    -- out data selector
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (unsigned(rd_addr) < to_unsigned(16#4000#, 32)) then
                read_select <= BUS_DMEM;
            elsif (unsigned(rd_addr) < to_unsigned(16#4010#, 32)) then
                read_select <= BUS_GPIO;
            elsif (unsigned(rd_addr) < to_unsigned(16#4020#, 32)) then
                read_select <= BUS_UART;
            elsif (unsigned(rd_addr) < to_unsigned(16#5000#, 32)) then
                read_select <= BUS_INVALID;
            elsif (unsigned(rd_addr) < to_unsigned(16#5800#, 32)) then
                read_select <= BUS_SOUND;
            else
                read_select <= BUS_INVALID;
            end if;
            read_select_byte <= byte_read;
            read_select_byte_addr <= rd_addr(1 downto 0);
        end if;
    end process;

    rd_data <= rd_data_buf when read_select_byte = '0' else
               x"000000" & rd_data_buf(7 downto 0) when read_select_byte_addr = "00" else
               x"000000" & rd_data_buf(15 downto 8) when read_select_byte_addr = "01" else
               x"000000" & rd_data_buf(23 downto 16) when read_select_byte_addr = "10" else
               x"000000" & rd_data_buf(31 downto 24);

    rd_data_buf <= dmem_rd_data when read_select = BUS_DMEM else
               gpio_rd_data when read_select = BUS_GPIO else
               uart_rd_data when read_select = BUS_UART else
               audio_rd_data when read_select = BUS_SOUND else
               x"00000000";

    -- in data selector
    process (rd_addr, rd_en)
    begin
        gpio_rd_en <= '0';
        dmem_rd_en <= '0';
        uart_rd_en <= '0';
        audio_rd_en <= '0';

        if (rd_en = '1') then
            if (unsigned(rd_addr) < to_unsigned(16#4000#, 32)) then
                dmem_rd_en <= '1';
            elsif (unsigned(rd_addr) < to_unsigned(16#4010#, 32)) then
                gpio_rd_en <= '1';
            elsif (unsigned(rd_addr) < to_unsigned(16#4020#, 32)) then
                uart_rd_en <= '1';
            elsif (unsigned(rd_addr) < to_unsigned(16#5000#, 32)) then
                uart_rd_en <= '0'; -- this statement only exists to fix code indentation in vim
            elsif (unsigned(rd_addr) < to_unsigned(16#5800#, 32)) then
                audio_rd_en <= '1';
            end if;
        end if;
    end process;

    process (wr_addr, wr_en)
    begin
        gpio_wr_en <= '0';
        dmem_wr_en <= '0';
        uart_wr_en <= '0';
        audio_wr_en <= '0';

        if (wr_en = '1') then
            if (unsigned(wr_addr) < to_unsigned(16#4000#, 32)) then
                dmem_wr_en <= '1';
            elsif (unsigned(wr_addr) < to_unsigned(16#4010#, 32)) then
                gpio_wr_en <= '1';
            elsif (unsigned(wr_addr) < to_unsigned(16#4020#, 32)) then
                uart_wr_en <= '1';
            elsif (unsigned(wr_addr) < to_unsigned(16#5000#, 32)) then
                uart_wr_en <= '0';
            elsif (unsigned(wr_addr) < to_unsigned(16#5800#, 32)) then
                audio_wr_en <= '1';
            end if;
        end if;
    end process;
end architecture;
