library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_synth is
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
        byte_write : in std_logic;
        
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
end audio_synth;

architecture behav of audio_synth is
    constant NUM_CHANNELS : integer := 64;
    constant ENV_STEP_CYCLES : std_logic_vector (9 downto 0) := std_logic_vector(to_unsigned(799, 10));
    --constant ENV_STEP_CYCLES : std_logic_vector (9 downto 0) := std_logic_vector(to_unsigned(2, 10));

    -- audio interface signals
    signal audio_new_sample : std_logic;
    signal audio_fpga_to_dac_l : std_logic_vector(15 downto 0) := x"0000";
    signal audio_fpga_to_dac_r : std_logic_vector(15 downto 0) := x"0000";

    -- audio register signals
    type T_REG_1  is array (0 to (NUM_CHANNELS - 1)) of std_logic;
    type T_REG_4  is array (0 to (NUM_CHANNELS - 1)) of std_logic_vector(3 downto 0);
    type T_REG_6  is array (0 to (NUM_CHANNELS - 1)) of std_logic_vector(5 downto 0);
    type T_REG_7  is array (0 to (NUM_CHANNELS - 1)) of std_logic_vector(6 downto 0);
    type T_REG_8  is array (0 to (NUM_CHANNELS - 1)) of std_logic_vector(7 downto 0);
    type T_REG_10  is array (0 to (NUM_CHANNELS - 1)) of std_logic_vector(9 downto 0);
    type T_REG_15  is array (0 to (NUM_CHANNELS - 1)) of std_logic_vector(14 downto 0);
    type T_REG_16  is array (0 to (NUM_CHANNELS - 1)) of std_logic_vector(15 downto 0);
    type T_REG_32 is array (0 to (NUM_CHANNELS - 1)) of std_logic_vector(31 downto 0);

    type T_SAMPLE is array (0 to 31) of std_logic_vector(3 downto 0);
    type T_REG_WAVE is array (0 to (NUM_CHANNELS - 1)) of T_SAMPLE;

    signal reg_status :     T_REG_6  := (others => (others => '0'));
    signal reg_key :        T_REG_7  := (others => (others => '0'));
    signal reg_left_vol :   T_REG_8  := (others => (others => '0'));
    signal reg_right_vol :  T_REG_8  := (others => (others => '0'));
    signal reg_wave_type :  T_REG_1  := (others => '0');
    signal reg_owner :      T_REG_4  := (others => (others => '0'));
    signal reg_velocity :   T_REG_7  := (others => (others => '0'));
    signal reg_freq :       T_REG_32 := (others => (others => '0'));
    signal reg_attack :     T_REG_8  := (others => (others => '0'));
    signal reg_decay :      T_REG_8  := (others => (others => '0'));
    signal reg_sustain :    T_REG_8  := (others => (others => '0'));
    signal reg_release :    T_REG_8  := (others => (others => '0'));
    signal reg_waveform :   T_REG_WAVE := (others => (others => x"0"));

    signal h_reg_phase :    T_REG_32 := (others => (others => '0'));
    signal h_reg_env_level : T_REG_16 := (others => (others => '0'));
    signal h_reg_env_countdown : T_REG_10 := (others => (others => '0'));

    signal h_reg_noise_state : T_REG_15 := (others => "100000000000000");
    signal h_reg_noise_out : T_REG_1 := (others => '0');

    -- audio rendering state signals
    type T_RENDER_STATE is (IDLE, UPDATE_STATUS, UPDATE_PHASE, SAMPLE_FETCH, SAMPLE_CALC_VOL, SAMPLE_ACC, UPDATE_LEVEL);
    signal render_state : T_RENDER_STATE := IDLE;

    signal current_channel : integer range 0 to (NUM_CHANNELS - 1) := 0;
    signal current_sample : unsigned(3 downto 0);
    signal current_volume_left : unsigned(7 downto 0);
    signal current_volume_right : unsigned(7 downto 0);

    signal current_level_left : signed(15 downto 0);
    signal current_level_right : signed(15 downto 0);
begin
    zed_audio: entity work.adau1761_izedboard port map
    (
        clk_48 => clk,
        ac_gpio1 => ac_gpio1,
        ac_gpio2 => ac_gpio2,
        ac_gpio3 => ac_gpio3,
        hphone_l => audio_fpga_to_dac_r, -- probably l/r mixed up on the hphone_l/r
        hphone_r => audio_fpga_to_dac_l,
        ac_sda => ac_sda,
        ac_adr0 => ac_adr0,
        ac_adr1 => ac_adr1,
        ac_gpio0 => ac_gpio0,
        ac_mclk => ac_mclk,
        ac_sck => ac_sck,
        line_in_l => open,
        line_in_r => open,
        new_sample => audio_new_sample
    );

    process (clk, reset)
        variable rd_chn_index : integer range 0 to 63;
        variable rd_chn_word : std_logic_vector(2 downto 0);

        variable wr_chn_index : integer range 0 to 63;
        variable wr_chn_reg : std_logic_vector(4 downto 0);
        variable wr_chn_word : std_logic_vector(2 downto 0);

        variable tmp_env : std_logic_vector(16 downto 0);
    begin
        if (reset = '1') then
            audio_fpga_to_dac_l <= x"0000";
            audio_fpga_to_dac_r <= x"0000";

            reg_status      <= (others => (others => '0'));
            reg_key         <= (others => (others => '0'));
            reg_left_vol    <= (others => (others => '0'));
            reg_right_vol   <= (others => (others => '0'));
            reg_wave_type   <= (others => '0');
            reg_owner       <= (others => (others => '0'));
            reg_velocity    <= (others => (others => '0'));
            reg_freq        <= (others => (others => '0'));
            reg_attack      <= (others => (others => '0'));
            reg_decay       <= (others => (others => '0'));
            reg_sustain     <= (others => (others => '0'));
            reg_release     <= (others => (others => '0'));
            reg_waveform    <= (others => (others => x"0"));

            h_reg_phase     <= (others => (others => '0'));
            h_reg_env_level <= (others => (others => '0'));
            h_reg_env_countdown <= (others => (others => '0'));

            h_reg_noise_state <= (others => "100000000000000");
            h_reg_noise_out <= (others => '0');

            render_state <= IDLE;
            current_channel <= 0;

            current_level_left <= to_signed(0, 16);
            current_level_right <= to_signed(0, 16);
        elsif (rising_edge(clk)) then
            -- write to register
            if (wr_en = '1') then
                wr_chn_index := to_integer(unsigned(wr_addr(10 downto 5)));
                if (byte_write = '1') then
                    wr_chn_reg := wr_addr(4 downto 0);
                    case wr_chn_reg is
                        when "00000" =>
                            reg_status(wr_chn_index)(5 downto 3) <= wr_data(5 downto 3) or reg_status(wr_chn_index)(5 downto 3);
                        when "00001" =>
                            reg_key(wr_chn_index) <= wr_data(6 downto 0);
                        when "00010" =>
                            reg_left_vol(wr_chn_index) <= wr_data(7 downto 0);
                        when "00011" =>
                            reg_right_vol(wr_chn_index) <= wr_data(7 downto 0);
                        when "00100" =>
                            reg_wave_type(wr_chn_index) <= wr_data(0);
                        when "00101" =>
                            reg_owner(wr_chn_index) <= wr_data(3 downto 0);
                        when "00110" =>
                            reg_velocity(wr_chn_index) <= wr_data(6 downto 0);
                        when "00111" =>
                        when "01000" =>
                            reg_freq(wr_chn_index)(7 downto 0) <= wr_data(7 downto 0);
                        when "01001" =>
                            reg_freq(wr_chn_index)(15 downto 8) <= wr_data(7 downto 0);
                        when "01010" =>
                            reg_freq(wr_chn_index)(23 downto 16) <= wr_data(7 downto 0);
                        when "01011" =>
                            reg_freq(wr_chn_index)(31 downto 24) <= wr_data(7 downto 0);
                        when "01100" =>
                            reg_attack(wr_chn_index) <= wr_data(7 downto 0);
                        when "01101" =>
                            reg_decay(wr_chn_index) <= wr_data(7 downto 0);
                        when "01110" =>
                            reg_sustain(wr_chn_index) <= wr_data(7 downto 0);
                        when "01111" =>
                            reg_release(wr_chn_index) <= wr_data(7 downto 0);
                        when "10000" =>
                            reg_waveform(wr_chn_index)(0) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(1) <= wr_data(3 downto 0);
                        when "10001" =>
                            reg_waveform(wr_chn_index)(2) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(3) <= wr_data(3 downto 0);
                        when "10010" =>
                            reg_waveform(wr_chn_index)(4) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(5) <= wr_data(3 downto 0);
                        when "10011" =>
                            reg_waveform(wr_chn_index)(6) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(7) <= wr_data(3 downto 0);
                        when "10100" =>
                            reg_waveform(wr_chn_index)(8) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(9) <= wr_data(3 downto 0);
                        when "10101" =>
                            reg_waveform(wr_chn_index)(10) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(11) <= wr_data(3 downto 0);
                        when "10110" =>
                            reg_waveform(wr_chn_index)(12) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(13) <= wr_data(3 downto 0);
                        when "10111" =>
                            reg_waveform(wr_chn_index)(14) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(15) <= wr_data(3 downto 0);
                        when "11000" =>
                            reg_waveform(wr_chn_index)(16) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(17) <= wr_data(3 downto 0);
                        when "11001" =>
                            reg_waveform(wr_chn_index)(18) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(19) <= wr_data(3 downto 0);
                        when "11010" =>
                            reg_waveform(wr_chn_index)(20) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(21) <= wr_data(3 downto 0);
                        when "11011" =>
                            reg_waveform(wr_chn_index)(22) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(23) <= wr_data(3 downto 0);
                        when "11100" =>
                            reg_waveform(wr_chn_index)(24) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(25) <= wr_data(3 downto 0);
                        when "11101" =>
                            reg_waveform(wr_chn_index)(26) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(27) <= wr_data(3 downto 0);
                        when "11110" =>
                            reg_waveform(wr_chn_index)(28) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(29) <= wr_data(3 downto 0);
                        when "11111" =>
                            reg_waveform(wr_chn_index)(30) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(31) <= wr_data(3 downto 0);
                        when others =>
                            assert false report "AUDIO SYNTH: illegal byte read";
                    end case;
                else
                    wr_chn_word := wr_addr(4 downto 2);
                    case wr_chn_word is
                        when "000" =>
                            reg_status(wr_chn_index)(5 downto 3) <= wr_data(5 downto 3) or reg_status(wr_chn_index)(5 downto 3);
                            reg_key(wr_chn_index) <= wr_data(14 downto 8);
                            reg_left_vol(wr_chn_index) <= wr_data(23 downto 16);
                            reg_right_vol(wr_chn_index) <= wr_data(31 downto 24);
                        when "001" =>
                            reg_wave_type(wr_chn_index) <= wr_data(0);
                            reg_owner(wr_chn_index) <= wr_data(11 downto 8);
                            reg_velocity(wr_chn_index) <= wr_data(22 downto 16);
                        when "010" =>
                            reg_freq(wr_chn_index) <= wr_data;
                        when "011" =>
                            reg_attack(wr_chn_index) <= wr_data(7 downto 0);
                            reg_decay(wr_chn_index) <= wr_data(15 downto 8);
                            reg_sustain(wr_chn_index) <= wr_data(23 downto 16);
                            reg_release(wr_chn_index) <= wr_data(31 downto 24);
                        when "100" =>
                            reg_waveform(wr_chn_index)(0) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(1) <= wr_data(3 downto 0);
                            reg_waveform(wr_chn_index)(2) <= wr_data(15 downto 12);
                            reg_waveform(wr_chn_index)(3) <= wr_data(11 downto 8);
                            reg_waveform(wr_chn_index)(4) <= wr_data(23 downto 20);
                            reg_waveform(wr_chn_index)(5) <= wr_data(19 downto 16);
                            reg_waveform(wr_chn_index)(6) <= wr_data(31 downto 28);
                            reg_waveform(wr_chn_index)(7) <= wr_data(27 downto 24);
                        when "101" =>
                            reg_waveform(wr_chn_index)(8) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(9) <= wr_data(3 downto 0);
                            reg_waveform(wr_chn_index)(10) <= wr_data(15 downto 12);
                            reg_waveform(wr_chn_index)(11) <= wr_data(11 downto 8);
                            reg_waveform(wr_chn_index)(12) <= wr_data(23 downto 20);
                            reg_waveform(wr_chn_index)(13) <= wr_data(19 downto 16);
                            reg_waveform(wr_chn_index)(14) <= wr_data(31 downto 28);
                            reg_waveform(wr_chn_index)(15) <= wr_data(27 downto 24);
                        when "110" =>
                            reg_waveform(wr_chn_index)(16) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(17) <= wr_data(3 downto 0);
                            reg_waveform(wr_chn_index)(18) <= wr_data(15 downto 12);
                            reg_waveform(wr_chn_index)(19) <= wr_data(11 downto 8);
                            reg_waveform(wr_chn_index)(20) <= wr_data(23 downto 20);
                            reg_waveform(wr_chn_index)(21) <= wr_data(19 downto 16);
                            reg_waveform(wr_chn_index)(22) <= wr_data(31 downto 28);
                            reg_waveform(wr_chn_index)(23) <= wr_data(27 downto 24);
                        when "111" =>
                            reg_waveform(wr_chn_index)(24) <= wr_data(7 downto 4);
                            reg_waveform(wr_chn_index)(25) <= wr_data(3 downto 0);
                            reg_waveform(wr_chn_index)(26) <= wr_data(15 downto 12);
                            reg_waveform(wr_chn_index)(27) <= wr_data(11 downto 8);
                            reg_waveform(wr_chn_index)(28) <= wr_data(23 downto 20);
                            reg_waveform(wr_chn_index)(29) <= wr_data(19 downto 16);
                            reg_waveform(wr_chn_index)(30) <= wr_data(31 downto 28);
                            reg_waveform(wr_chn_index)(31) <= wr_data(27 downto 24);
                        when others =>
                            assert false report "AUDIO SYNTH: illegal word write";
                    end case;
                end if;
            end if;

            if (rd_en = '1') then
                rd_chn_index := to_integer(unsigned(rd_addr(10 downto 5)));
                rd_chn_word := rd_addr(4 downto 2);

                case rd_chn_word is
                    when "000" =>
                        rd_data <= reg_right_vol(rd_chn_index) & 
                                   reg_left_vol(rd_chn_index) &
                                   "0" & reg_key(rd_chn_index) & 
                                   "00" & reg_status(rd_chn_index)(5 downto 0);
                    when "001" =>
                        rd_data <= "00000000" & 
                                   "0" & reg_velocity(rd_chn_index) &
                                   "0000" & reg_owner(rd_chn_index) & 
                                   "0000000" & reg_wave_type(rd_chn_index);
                    when "010" =>
                        rd_data <= reg_freq(rd_chn_index);
                    when "011" =>
                        rd_data <= reg_release(rd_chn_index) &
                                   reg_sustain(rd_chn_index) &
                                   reg_decay(rd_chn_index) &
                                   reg_attack(rd_chn_index);
                    when "100" =>
                        rd_data <= reg_waveform(rd_chn_index)(6) &
                                   reg_waveform(rd_chn_index)(7) &
                                   reg_waveform(rd_chn_index)(4) &
                                   reg_waveform(rd_chn_index)(5) &
                                   reg_waveform(rd_chn_index)(2) &
                                   reg_waveform(rd_chn_index)(3) &
                                   reg_waveform(rd_chn_index)(0) &
                                   reg_waveform(rd_chn_index)(1);
                    when "101" =>
                        rd_data <= reg_waveform(rd_chn_index)(14) &
                                   reg_waveform(rd_chn_index)(15) &
                                   reg_waveform(rd_chn_index)(12) &
                                   reg_waveform(rd_chn_index)(13) &
                                   reg_waveform(rd_chn_index)(10) &
                                   reg_waveform(rd_chn_index)(11) &
                                   reg_waveform(rd_chn_index)(8) &
                                   reg_waveform(rd_chn_index)(9);
                    when "110" =>
                        rd_data <= reg_waveform(rd_chn_index)(22) &
                                   reg_waveform(rd_chn_index)(23) &
                                   reg_waveform(rd_chn_index)(20) &
                                   reg_waveform(rd_chn_index)(21) &
                                   reg_waveform(rd_chn_index)(18) &
                                   reg_waveform(rd_chn_index)(19) &
                                   reg_waveform(rd_chn_index)(16) &
                                   reg_waveform(rd_chn_index)(17);
                    when "111" =>
                        rd_data <= reg_waveform(rd_chn_index)(30) &
                                   reg_waveform(rd_chn_index)(31) &
                                   reg_waveform(rd_chn_index)(28) &
                                   reg_waveform(rd_chn_index)(29) &
                                   reg_waveform(rd_chn_index)(26) &
                                   reg_waveform(rd_chn_index)(27) &
                                   reg_waveform(rd_chn_index)(24) &
                                   reg_waveform(rd_chn_index)(25);
                    when others =>
                        assert false report "AUDIO SYNTH: illegal word read";
                end case;
            end if;

            -- process sample
            case render_state is
                when IDLE =>
                    if (audio_new_sample = '1') then
                    --if true then
                        render_state <= UPDATE_STATUS;
                        current_channel <= 0;
                        current_level_left <= to_signed(0, 16);
                        current_level_right <= to_signed(0, 16);
                    end if;
                when UPDATE_STATUS =>
                    render_state <= UPDATE_PHASE;
                    if (reg_status(current_channel)(3) = '1') then -- if FORCE_STOP
                        h_reg_env_level(current_channel) <= x"0000";
                        h_reg_env_countdown(current_channel) <= (others => '0');
                        reg_status(current_channel)(2 downto 0) <= "000";
                        reg_status(current_channel)(3) <= '0';

                        if (current_channel = NUM_CHANNELS - 1) then
                            render_state <= UPDATE_LEVEL;
                        else
                            render_state <= UPDATE_STATUS;
                            current_channel <= current_channel + 1;
                        end if;
                    elsif (reg_status(current_channel)(5) = '1') then -- if INIT
                        h_reg_env_level(current_channel) <= reg_attack(current_channel) & x"00";
                        h_reg_env_countdown(current_channel) <= ENV_STEP_CYCLES;
                        h_reg_phase(current_channel) <= (others => '0');
                        reg_status(current_channel)(2 downto 0) <= "100"; -- state = attack
                        reg_status(current_channel)(5) <= '0';
                    elsif (reg_status(current_channel)(4) = '1') then -- if FORCE_RELEASE
                        h_reg_env_countdown(current_channel) <= ENV_STEP_CYCLES;
                        reg_status(current_channel)(2 downto 0) <= "001"; -- state = release
                        reg_status(current_channel)(4) <= '0';
                    elsif (reg_status(current_channel)(2 downto 0) = "100") then -- attack
                        if (h_reg_env_countdown(current_channel) = "0000000000") then
                            h_reg_env_countdown(current_channel) <= ENV_STEP_CYCLES;
                            tmp_env := std_logic_vector(resize(unsigned(h_reg_env_level(current_channel)), 17) + shift_left(resize(unsigned(reg_attack(current_channel)), 17), 8));
                            if (unsigned(tmp_env) >= to_unsigned(16#FF00#, 17)) then
                                h_reg_env_level(current_channel) <= x"FF00";
                                reg_status(current_channel)(2 downto 0) <= "011"; -- state = decay
                            else
                                h_reg_env_level(current_channel) <= tmp_env(15 downto 0);
                            end if;
                        else
                            h_reg_env_countdown(current_channel) <= std_logic_vector(
                                                                    unsigned(h_reg_env_countdown(current_channel)) -
                                                                    to_unsigned(1, 10));
                        end if;
                    elsif (reg_status(current_channel)(2 downto 0) = "011") then -- decay
                        if (h_reg_env_countdown(current_channel) = "0000000000") then
                            h_reg_env_countdown(current_channel) <= ENV_STEP_CYCLES;
                            tmp_env := '0' & std_logic_vector(resize(shift_right(unsigned(h_reg_env_level(current_channel)) * unsigned(reg_decay(current_channel)), 8), 16));
                            if (unsigned(tmp_env(15 downto 8)) <= unsigned(reg_sustain(current_channel))) then
                                h_reg_env_level(current_channel) <= reg_sustain(current_channel) & x"00";
                                reg_status(current_channel)(2 downto 0) <= "010";
                            else
                                h_reg_env_level(current_channel) <= tmp_env(15 downto 0);
                            end if;
                        else
                            h_reg_env_countdown(current_channel) <= std_logic_vector(
                                                                    unsigned(h_reg_env_countdown(current_channel)) -
                                                                    to_unsigned(1, 10));
                        end if;
                    elsif (reg_status(current_channel)(2 downto 0) = "010") then -- sustain
                        h_reg_env_countdown(current_channel) <= (others => '0');
                    elsif (reg_status(current_channel)(2 downto 0) = "001") then -- release
                        if (h_reg_env_countdown(current_channel) = "0000000000") then
                            h_reg_env_countdown(current_channel) <= ENV_STEP_CYCLES;
                            tmp_env := '0' & std_logic_vector(resize(shift_right(unsigned(h_reg_env_level(current_channel)) * unsigned(reg_release(current_channel)), 8), 16));
                            if (unsigned(tmp_env(15 downto 8)) = to_unsigned(0, 8)) then
                                h_reg_env_level(current_channel) <= x"0000";
                                reg_status(current_channel)(2 downto 0) <= "000";
                            else
                                h_reg_env_level(current_channel) <= tmp_env(15 downto 0);
                            end if;
                        else
                            h_reg_env_countdown(current_channel) <= std_logic_vector(
                                                                    unsigned(h_reg_env_countdown(current_channel)) -
                                                                    to_unsigned(1, 10));
                        end if;
                    elsif (reg_status(current_channel)(2 downto 0) = "000") then -- full stop
                        h_reg_env_countdown(current_channel) <= (others => '0');

                        if (current_channel = NUM_CHANNELS - 1) then
                            render_state <= UPDATE_LEVEL;
                        else
                            render_state <= UPDATE_STATUS;
                            current_channel <= current_channel + 1;
                        end if;
                    end if;
                when UPDATE_PHASE =>
                    if (reg_wave_type(current_channel) = '0') then
                        h_reg_phase(current_channel) <= std_logic_vector(
                                                        unsigned(h_reg_phase(current_channel)) +
                                                        unsigned(reg_freq(current_channel)));
                        render_state <= SAMPLE_FETCH;
                    else
                        if (unsigned(h_reg_phase(current_channel)) + unsigned(reg_freq(current_channel)) > to_unsigned(16#40000000#, 32)) then
                            h_reg_noise_out(current_channel) <= h_reg_noise_state(current_channel)(0);
                            if (h_reg_noise_state(current_channel)(0) = '1') then
                                h_reg_noise_state(current_channel) <= std_logic_vector(shift_right(unsigned(h_reg_noise_state(current_channel)), 1)) xor "110000000000000";
                            else
                                h_reg_noise_state(current_channel) <= std_logic_vector(shift_right(unsigned(h_reg_noise_state(current_channel)), 1));
                            end if;
                        else
                            render_state <= SAMPLE_FETCH;
                        end if;
                        h_reg_phase(current_channel) <= "00" & std_logic_vector(
                                                        resize(
                                                        unsigned(h_reg_phase(current_channel)) + 
                                                        unsigned(reg_freq(current_channel)), 30));
                    end if;
                when SAMPLE_FETCH =>
                    if (reg_wave_type(current_channel) = '0') then
                        current_sample <= unsigned(reg_waveform(current_channel)(to_integer(unsigned(h_reg_phase(current_channel)(31 downto 27)))));
                    else
                        if (h_reg_noise_out(current_channel) = '1') then
                            current_sample <= to_unsigned(15, 4);
                        else
                            current_sample <= to_unsigned(0, 4);
                        end if;
                    end if;
                    render_state <= SAMPLE_CALC_VOL;
                when SAMPLE_CALC_VOL =>
                    current_volume_left <= resize(shift_right(unsigned(reg_left_vol(current_channel)) * unsigned(h_reg_env_level(current_channel)), 16), 8);
                    current_volume_right <= resize(shift_right(unsigned(reg_right_vol(current_channel)) * unsigned(h_reg_env_level(current_channel)), 16), 8);
                    render_state <= SAMPLE_ACC;
                when SAMPLE_ACC =>
                    current_level_left <= to_signed(to_integer(current_level_left) + (to_integer(current_sample) - 8) * to_integer(current_volume_left), 16);
                    current_level_right <= to_signed(to_integer(current_level_right) + (to_integer(current_sample) - 8) * to_integer(current_volume_right), 16);

                    if (current_channel = NUM_CHANNELS - 1) then
                        render_state <= UPDATE_LEVEL;
                    else
                        render_state <= UPDATE_STATUS;
                        current_channel <= current_channel + 1;
                    end if;
                when UPDATE_LEVEL =>
                    audio_fpga_to_dac_l <= std_logic_vector(current_level_left);
                    audio_fpga_to_dac_r <= std_logic_vector(current_level_right);
                    render_state <= IDLE;
            end case;
        end if; -- rising_edge(clk)
    end process;
end architecture;
