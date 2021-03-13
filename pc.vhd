library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity pc is
    port
    (
        EN: in std_logic;
        RESET: in std_logic;
        CLK: in std_logic;
        LOAD: in std_logic;
        LOAD_VAL: in std_logic_vector(31 downto 0);
        ADDR: out std_logic_vector(31 downto 0)
    );	
end pc;

architecture Behavorial of pc is
    signal pc : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_4 : std_logic_vector(31 downto 0) :=  (others => '0');
begin
    ADDR <= pc;

    process(pc)
    begin
        pc_4 <= std_logic_vector(unsigned(pc) + 4);
    end process;

    process(CLK)
    begin
        if (rising_edge(CLK)) then
            if (RESET = '1') then
                pc <= (others => '0');
            elsif (EN = '1') then
                if (LOAD = '1') then
                    pc <= LOAD_VAL;
                else
                    pc <= pc_4;
                end if;
            end if;
        end if;
    end process;
end Behavorial;
