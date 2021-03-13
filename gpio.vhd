library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio is
    port
    (
        clk: in std_logic;
        reset: in std_logic;
        rd_addr: in std_logic_vector(31 downto 0);
        rd_data: out std_logic_vector(31 downto 0);
        rd_en: in std_logic;
        wr_addr: in std_logic_vector(31 downto 0);
        wr_data: in std_logic_vector(31 downto 0);
        wr_en: in std_logic;
        byte_write: in std_logic;

        gpi: in std_logic_vector(7 downto 0);
        gpo: out std_logic_vector(7 downto 0)
    );
end gpio;

architecture behav of gpio is
    signal gpo_buf : std_logic_vector(7 downto 0) := x"00";
begin
    gpo <= gpo_buf;

    process (clk, reset)
    begin
        if (reset = '1') then
            gpo_buf <= x"00";
        elsif (rising_edge(clk)) then
            rd_data <= x"000000" & gpi;
            if (wr_en = '1') then
                gpo_buf <= wr_data(7 downto 0);
            end if;
        end if;
    end process;
end architecture;
