library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity tb_cpu is
end;

architecture bench of tb_cpu is
    signal clk: std_logic := '0';
    signal reset: std_logic := '0';

    signal gpi: std_logic_vector (7 downto 0) := x"00";
    signal gpo: std_logic_vector (7 downto 0);

    signal uart_in : std_logic := '1';

    signal ac_adr0 : std_logic;
    signal ac_adr1 : std_logic;
    signal ac_gpio0 : std_logic;  -- i2s miso
    signal ac_gpio1 : std_logic := '0';   -- i2s mosi
    signal ac_gpio2 : std_logic := '0';   -- i2s_bclk
    signal ac_gpio3 : std_logic := '0';   -- i2s_lr
    signal ac_mclk : std_logic;
    signal ac_sck : std_logic;
    signal ac_sda : std_logic;

    constant clock_period: time := 10 ns;
    signal stop_the_clock: boolean := false;
begin

    uut: entity work.cpu port map 
    ( 
        clk => clk,
        reset => reset,
        gpi => gpi,
        gpo => gpo,

        uart_in => uart_in,

        ac_adr0 => ac_adr0,
        ac_adr1 => ac_adr1,
        ac_gpio0 => ac_gpio0, -- i2s miso
        ac_gpio1 => ac_gpio1, -- i2s mosi
        ac_gpio2 => ac_gpio2, -- i2s_bclk
        ac_gpio3 => ac_gpio3, -- i2s_lr
        ac_mclk => ac_mclk,
        ac_sck => ac_sck,
        ac_sda => ac_sda
    );

    process
    begin
        uart_in <= '1';
        wait for 100 ns;
        reset <= '1';
        wait for 2000 ns;
        reset <= '0';
        wait for 6000 ns;
        uart_in <= '0'; -- start bit
        wait for 8680 ns;
        uart_in <= '0'; -- bit 0
        wait for 8680 ns;
        uart_in <= '0'; -- bit 1
        wait for 8680 ns;
        uart_in <= '0'; -- bit 2
        wait for 8680 ns;
        uart_in <= '0'; -- bit 3
        wait for 8680 ns;
        uart_in <= '1'; -- bit 4
        wait for 8680 ns;
        uart_in <= '0'; -- bit 5
        wait for 8680 ns;
        uart_in <= '0'; -- bit 6
        wait for 8680 ns;
        uart_in <= '1'; -- bit 7
        wait for 8680 ns;
        uart_in <= '1'; -- stop bit
        wait for 8680 ns;

        uart_in <= '0'; -- start bit
        wait for 8680 ns;
        uart_in <= '0'; -- bit 0
        wait for 8680 ns;
        uart_in <= '0'; -- bit 1
        wait for 8680 ns;
        uart_in <= '1'; -- bit 2
        wait for 8680 ns;
        uart_in <= '1'; -- bit 3
        wait for 8680 ns;
        uart_in <= '1'; -- bit 4
        wait for 8680 ns;
        uart_in <= '1'; -- bit 5
        wait for 8680 ns;
        uart_in <= '0'; -- bit 6
        wait for 8680 ns;
        uart_in <= '0'; -- bit 7
        wait for 8680 ns;
        uart_in <= '1'; -- stop bit
        wait for 8680 ns;

        uart_in <= '0'; -- start bit
        wait for 8680 ns;
        uart_in <= '1'; -- bit 0
        wait for 8680 ns;
        uart_in <= '1'; -- bit 1
        wait for 8680 ns;
        uart_in <= '1'; -- bit 2
        wait for 8680 ns;
        uart_in <= '1'; -- bit 3
        wait for 8680 ns;
        uart_in <= '1'; -- bit 4
        wait for 8680 ns;
        uart_in <= '1'; -- bit 5
        wait for 8680 ns;
        uart_in <= '1'; -- bit 6
        wait for 8680 ns;
        uart_in <= '0'; -- bit 7
        wait for 8680 ns;
        uart_in <= '1'; -- stop bit
        wait for 8680 ns;
        wait;
    end process;

    clocking: process
    begin
        while not stop_the_clock loop
            clk <= '0', '1' after clock_period / 2;
            wait for clock_period;
        end loop;
        wait;
    end process;

end;
