library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port
    (
        input_a: in std_logic_vector(31 downto 0);
        input_b: in std_logic_vector(31 downto 0);
        ctrl: in std_logic_vector(3 downto 0);
        output: out std_logic_vector(31 downto 0);
        zero: out std_logic;
        not_negative: out std_logic
    );
end alu;

architecture behav of alu is
    signal output_buf : std_logic_vector(31 downto 0);
begin
    output <= output_buf;

    zero <= '1' when output_buf = x"00000000" else '0';
    not_negative <= '0' when input_a(31) = '1' else '1';

    process(ctrl, input_a, input_b)
    begin
        case ctrl is
            when "0000" =>
                -- AND
                output_buf <= input_a and input_b;
            when "0001" =>
                -- OR
                output_buf <= input_a or input_b;
            when "0010" =>
                -- ADD
                output_buf <= std_logic_vector(
                          signed(input_a) + 
                          signed(input_b));
            when "0100" =>
                -- LUI
                output_buf <= input_b(15 downto 0) & x"0000";
            when "0101" =>
                -- XOR
                output_buf <= input_a xor input_b;
            when "0110" =>
                -- SUB
                output_buf <= std_logic_vector(
                          signed(input_a) - 
                          signed(input_b));
            when "0111" =>
                -- SLT
                if (signed(input_a) < signed(input_b)) then
                    output_buf <= x"00000001";
                else
                    output_buf <= x"00000000";
                end if;
            when "1000" =>
                -- SHIFT LEFT LOGICAL
                output_buf <= std_logic_vector(shift_left(unsigned(input_b), to_integer(unsigned(input_a))));
            when "1001" =>
                -- SHIFT RIGHT LOGICAL
                output_buf <= std_logic_vector(shift_right(unsigned(input_b), to_integer(unsigned(input_a))));
            when "1010" =>
                -- SHIFT RIGHT ARITHMETIC
                output_buf <= std_logic_vector(shift_right(signed(input_b), to_integer(unsigned(input_a))));
            when "1100" =>
                -- NOR
                output_buf <= input_a nor input_b;
            when "1110" =>
                -- MUL
                output_buf <= std_logic_vector(
                              resize(signed(input_a) * signed(input_b), 32)
                          );
            when others =>
                assert false report "illegal ALU code";
                output_buf <= x"DEADFA11";
        end case;
    end process;
end architecture;
