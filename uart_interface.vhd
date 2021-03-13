library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_interface is
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
        byte_write : std_logic;

        uart_in : in std_logic
    );
end uart_interface;

architecture behav of uart_interface is
    component uart_fifo
        port
        (
            clk : in std_logic;
            srst : in std_logic;
            din : in std_logic_vector(7 downto 0);
            wr_en : in std_logic;
            rd_en : in std_logic;
            dout : out std_logic_vector(7 downto 0);
            full : out std_logic;
            empty : out std_logic
        );
    end component;

    constant UART_CLOCKS : integer := 417;
    constant NUM_BITS : integer := 8;
    type UART_STATE is (STATE_RESET, WAIT_FOR_START, RECEIVE, FIFO_PUSH);

    signal current_state : UART_STATE := STATE_RESET;
    signal clock_count : integer range 0 to 10000000;
    signal bit_count : integer range 0 to 7;
    signal uart_shift_register : std_logic_vector (7 downto 0);

    signal uart_in_buf : std_logic;
    signal uart_in_buf_main : std_logic;
    signal uart_in_buf_previous : std_logic;

    signal fifo_din : std_logic_vector(7 downto 0);
    signal fifo_wr_en : std_logic;
    signal fifo_rd_en : std_logic;
    signal fifo_dout : std_logic_vector(7 downto 0);
    signal fifo_empty : std_logic;

    signal flag_read_empty : std_logic;
begin
    instance_uart_fifo: uart_fifo port map
    (
        clk => clk,
        srst => reset,
        din => fifo_din,
        wr_en => fifo_wr_en,
        rd_en => fifo_rd_en,
        dout => fifo_dout,
        full => open,
        empty => fifo_empty
    );

    fifo_din <= uart_shift_register;
    fifo_rd_en <= rd_en when rd_addr = x"00000000" else '0';
    rd_data <= x"000000" & fifo_dout when flag_read_empty = '0' else
               x"0000000" & "000" & not fifo_empty;

    process (clk, reset)
    begin
        if (reset = '1') then
            flag_read_empty <= '0';
            current_state <= STATE_RESET;
            clock_count <= 100;
            uart_shift_register <= x"00";
            fifo_wr_en <= '0';
        elsif (rising_edge(clk)) then
            uart_in_buf <= uart_in;
            uart_in_buf_main <= uart_in_buf;
            uart_in_buf_previous <= uart_in_buf_main;
            fifo_wr_en <= '0';

            if (rd_addr = x"00000000") then
                flag_read_empty <= '0';
            else
                flag_read_empty <= '1';
            end if;

            case current_state is
                when STATE_RESET =>
                    if (clock_count > 0) then
                        clock_count <= clock_count - 1;
                    else
                        current_state <= WAIT_FOR_START;
                        clock_count <= 0;
                    end if;
                when WAIT_FOR_START =>
                    if (uart_in_buf_main = '0' and uart_in_buf_previous = '1') then -- wait for start bit
                        clock_count <= UART_CLOCKS - 1 + (UART_CLOCKS/2);
                        current_state <= RECEIVE;
                        bit_count <= 0;
                    end if;
                when RECEIVE =>
                    if (clock_count > 0) then
                        clock_count <= clock_count - 1;
                    else
                        uart_shift_register <= uart_in_buf_main & uart_shift_register (7 downto 1);
                        clock_count <= UART_CLOCKS - 1;
                        if (bit_count = NUM_BITS - 1) then
                            current_state <= FIFO_PUSH;
                        else
                            bit_count <= bit_count + 1;
                        end if;
                    end if;
                when FIFO_PUSH =>
                    if (clock_count > 0) then
                        clock_count <= clock_count - 1;
                    else
                        current_state <= WAIT_FOR_START;
                        if (uart_in_buf_main = '1') then -- check for proper stop bit
                            -- TODO: SET SIGNALS FIFO
                            fifo_wr_en <= '1';
                        end if;
                    end if;
            end case;
        end if;
    end process;
end architecture;
