library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_mem is
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
        byte_write: in std_logic
    );
end data_mem;

architecture behav of data_mem is
    component blk_ram_data
        port 
        (
            clka : in std_logic;
            wea : in std_logic_vector(3 downto 0);
            addra : in std_logic_vector(11 downto 0);
            dina : in std_logic_vector(31 downto 0);
            clkb : in std_logic;
            addrb : in std_logic_vector(11 downto 0);
            doutb : out std_logic_vector(31 downto 0)
        );
    end component;

    signal byte_read_buf : std_logic;
    signal wr_addr_buf : std_logic_vector(11 downto 0);
    signal wr_data_buf : std_logic_vector(31 downto 0);
    signal wr_en_buf : std_logic_vector(3 downto 0);
    signal rd_addr_buf : std_logic_vector(11 downto 0);
begin
    bram_instance: blk_ram_data port map 
    (
        clka => clk,
        wea => wr_en_buf,
        addra => wr_addr_buf,
        dina => wr_data_buf,
        clkb => clk,
        addrb => rd_addr_buf,
        doutb => rd_data
    );

    wr_addr_buf <= wr_addr(13 downto 2);
    rd_addr_buf <= rd_addr(13 downto 2);

    wr_data_buf <= wr_data when byte_write = '0' else
                   x"000000" & wr_data(7 downto 0) when wr_addr(1 downto 0) = "00" else
                   x"0000" & wr_data(7 downto 0) & x"00"  when wr_addr(1 downto 0) = "01" else
                   x"00" & wr_data(7 downto 0) & x"0000" when wr_addr(1 downto 0) = "10" else
                   wr_data(7 downto 0) & x"000000";

    wr_en_buf <= "0000" when wr_en = '0' else
                 "1111" when byte_write = '0' else
                 "0001" when wr_addr(1 downto 0) = "00" else
                 "0010" when wr_addr(1 downto 0) = "01" else
                 "0100" when wr_addr(1 downto 0) = "10" else
                 "1000";
end architecture;
