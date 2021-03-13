library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
    port
    (
        addr_reg_a: in std_logic_vector(4 downto 0);
        addr_reg_b: in std_logic_vector(4 downto 0);
        out_reg_a: out std_logic_vector(31 downto 0);
        out_reg_b: out std_logic_vector(31 downto 0);
        wr_addr: in std_logic_vector(4 downto 0);
        wr_en: in std_logic;
        wr_data: in std_logic_vector(31 downto 0);
        reset: in std_logic;
        clk: in std_logic
    );
end regfile;

architecture behav of regfile is
    type REG_SET is array (0 to 31) of std_logic_vector(31 downto 0);

    signal registers : REG_SET := ((others => (others => '0')));

    signal sig_out_reg_a : std_logic_vector(31 downto 0) := (others => '0');
    signal sig_out_reg_b : std_logic_vector(31 downto 0) := (others => '0');
begin
    out_reg_a <= sig_out_reg_a;
    out_reg_b <= sig_out_reg_b;

    process (addr_reg_a, registers)
    begin
        sig_out_reg_a <= registers(to_integer(unsigned(addr_reg_a)));
    end process;

    process (addr_reg_b, registers)
    begin
        sig_out_reg_b <= registers(to_integer(unsigned(addr_reg_b)));
    end process;

    process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                registers <= ((others => (others => '0')));
            elsif (wr_en = '1') then
                registers(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
        end if;
    end process;
end architecture;
