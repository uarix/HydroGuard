library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity lcd_12864 is
    port(
        clk_i        : in  STD_LOGIC;
        reset_i      : in  STD_LOGIC;
        lcd_ok_o     : out STD_LOGIC;
        pos_x_i      : in  STD_LOGIC_VECTOR(3 downto 0);
        pos_y_i      : in  STD_LOGIC_VECTOR(3 downto 0);
        char_index_i : in  STD_LOGIC_VECTOR(6 downto 0); -- Input ASCII code
        char_show_i  : in  STD_LOGIC;
        data_o       : out STD_LOGIC_VECTOR(7 downto 0);
        reset_n_o    : out STD_LOGIC;
        cs_n_o       : out STD_LOGIC;
        wr_n_o       : out STD_LOGIC;
        rd_n_o       : out STD_LOGIC;
        a0_o         : out STD_LOGIC
    );
end lcd_12864;

architecture arch of lcd_12864 is

    -- UFM with 16-bit data bus
    COMPONENT font_ufm
        PORT (
            addr       : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
            nread      : IN  STD_LOGIC;
            dataout    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            nbusy      : OUT STD_LOGIC;
            data_valid : OUT STD_LOGIC
        );
    END COMPONENT;

    -- State machine types
    type T_Sys_States is (S_SYS_INIT, S_HW_RST, S_SOFT_INIT, S_SYS_IDLE, S_SET_ADDR, S_UFM_REQ, S_UFM_WAIT);
    signal cur_sys_state, next_sys_state : T_Sys_States;
    type T_Chip_States is (sr_lcd_idle, sr_lcd_setup, sr_lcd_write, sr_lcd_hold);
    signal cur_lcd_state, next_lcd_state : T_Chip_States;

    -- Initialization constants
    constant C_INIT_CMD_NUM : integer := 14;
    type T_INIT_BUF is array(0 to C_INIT_CMD_NUM) of std_logic_vector(7 downto 0);
    constant C_INIT_DATA : T_INIT_BUF := (
        x"e2", x"2c", x"2e", x"2f", x"24", x"81", x"1C", x"a2",
        x"c8", x"a0", x"40", x"b0", x"10", x"00", x"af"
    );
    signal soft_init_addr : integer range 0 to C_INIT_CMD_NUM;

    -- UFM font signals
    signal ufm_addr       : std_logic_vector(8 downto 0);
    signal ufm_data_out   : std_logic_vector(15 downto 0);
    signal ufm_data_valid : std_logic;
    signal ufm_nread      : std_logic := '1';

    -- Internal control signals
    signal delay_counter     : integer range 0 to 65535;
    signal init_ok           : std_logic;
    signal hw_reset_ok       : std_logic;
    signal set_addr_ok       : std_logic;
    signal write_trigger     : std_logic;
    signal chip_done_pulse   : std_logic;
    signal is_cmd            : std_logic;
    signal internal_data_bus : std_logic_vector(7 downto 0);

    -- Character and address signals
    signal char_ascii_code     : integer range 0 to 127;
    signal mapped_char_index   : integer range 0 to 94;  -- Index for the compacted font library (95 chars)
    signal data_word_index     : integer range 0 to 3;
    signal is_writing_low_byte : std_logic;
    signal column_addr         : std_logic_vector(7 downto 0);
    signal page_addr           : std_logic_vector(3 downto 0);
    signal set_addr_step       : integer range 0 to 2;

begin

    -- UFM Instantiation
    UFM_FONT_INSTANCE : font_ufm PORT MAP(addr=>ufm_addr, nread=>ufm_nread, dataout=>ufm_data_out, nbusy=>open, data_valid=>ufm_data_valid);

    -- =============================================================================
    -- UFM ADDRESSING LOGIC 
    -- =============================================================================
    -- Maps incoming ASCII code to a compact index for the UFM.
    -- Printable characters (ASCII 32-126) are mapped to indices 0-94.
    -- Non-printable characters default to index 0 (Space).
    process(char_ascii_code)
    begin
        if char_ascii_code >= 32 and char_ascii_code <= 126 then
            mapped_char_index <= char_ascii_code - 32;
        else
            mapped_char_index <= 0; -- Default to 'Space' (ASCII 32) which is at index 0
        end if;
    end process;

    -- Calculates final UFM address based on the mapped index and word offset.
    ufm_addr <= std_logic_vector(to_unsigned((mapped_char_index * 4) + data_word_index, 9));

    -- =============================================================================
    -- MAIN SYSTEM FSM 
    -- =============================================================================
    process(clk_i, reset_i) begin if reset_i = '1' then cur_sys_state <= S_SYS_INIT; elsif rising_edge(clk_i) then cur_sys_state <= next_sys_state; end if; end process;

    process(cur_sys_state, init_ok, hw_reset_ok, char_show_i, set_addr_ok, ufm_data_valid, chip_done_pulse, data_word_index, soft_init_addr, is_writing_low_byte)
    begin
        next_sys_state <= cur_sys_state;
        case cur_sys_state is
            when S_SYS_INIT  => if init_ok = '1' then next_sys_state <= S_HW_RST; end if;
            when S_HW_RST    => if hw_reset_ok = '1' then next_sys_state <= S_SOFT_INIT; end if;
            when S_SOFT_INIT => if chip_done_pulse = '1' and soft_init_addr = C_INIT_CMD_NUM then next_sys_state <= S_SYS_IDLE; end if;
            when S_SYS_IDLE  => if char_show_i = '1' then next_sys_state <= S_SET_ADDR; end if;
            when S_SET_ADDR  => if set_addr_ok = '1' then next_sys_state <= S_UFM_REQ; end if;
            when S_UFM_REQ   => next_sys_state <= S_UFM_WAIT;
            when S_UFM_WAIT  =>
                if ufm_data_valid = '1' and chip_done_pulse = '1' then
                    if is_writing_low_byte = '1' then
                        if data_word_index = 3 then      
                            next_sys_state <= S_SYS_IDLE;
                        else
                            next_sys_state <= S_UFM_REQ;
                        end if;
                    else
                        next_sys_state <= S_UFM_WAIT;
                    end if;
                end if;
        end case;
    end process;

    -- =============================================================================
    -- INTERNAL LOGIC AND COUNTERS 
    -- =============================================================================
    process(clk_i, reset_i) begin if reset_i = '1' then char_ascii_code <= 0; column_addr <= (others => '0'); page_addr <= (others => '0'); elsif rising_edge(clk_i) then if cur_sys_state = S_SYS_IDLE and char_show_i = '1' then char_ascii_code <= to_integer(unsigned(char_index_i)); column_addr <= '0' & pos_x_i & "000"; page_addr <= pos_y_i; end if; end if; end process;

    process(clk_i, reset_i)
    begin
        if reset_i = '1' then delay_counter <= 0; soft_init_addr <= 0; set_addr_step <= 0; data_word_index <= 0; is_writing_low_byte <= '0';
        elsif rising_edge(clk_i) then
            if (cur_sys_state = S_SYS_INIT or cur_sys_state = S_HW_RST) and delay_counter < 65535 then delay_counter <= delay_counter + 1;
            elsif not(cur_sys_state = S_SYS_INIT or cur_sys_state = S_HW_RST) then delay_counter <= 0; end if;
            if (cur_sys_state = S_SOFT_INIT and chip_done_pulse = '1') and soft_init_addr < C_INIT_CMD_NUM then soft_init_addr <= soft_init_addr + 1; end if;
            if (cur_sys_state = S_SET_ADDR and chip_done_pulse = '1') and set_addr_step < 2 then set_addr_step <= set_addr_step + 1; end if;
            if cur_sys_state = S_SYS_IDLE and char_show_i = '1' then set_addr_step <= 0; data_word_index <= 0; is_writing_low_byte <= '0'; end if;
            if cur_sys_state = S_UFM_WAIT and ufm_data_valid = '1' and chip_done_pulse = '1' then
                if is_writing_low_byte = '0' then is_writing_low_byte <= '1';
                else is_writing_low_byte <= '0'; if data_word_index < 3 then data_word_index <= data_word_index + 1; end if; end if;
            end if;
        end if;
    end process;
    
    init_ok     <= '1' when delay_counter = 65535 and cur_sys_state = S_SYS_INIT else '0';
    hw_reset_ok <= '1' when delay_counter = 65535 and cur_sys_state = S_HW_RST else '0';
    set_addr_ok <= '1' when set_addr_step = 2 and chip_done_pulse = '1' else '0';

    process(cur_sys_state, soft_init_addr, set_addr_step, column_addr, page_addr, ufm_data_out, is_writing_low_byte)
    begin
        internal_data_bus <= (others => '0');
        case cur_sys_state is
            when S_SOFT_INIT => internal_data_bus <= C_INIT_DATA(soft_init_addr);
            when S_SET_ADDR  => case set_addr_step is when 0 => internal_data_bus <= "1011" & page_addr; when 1 => internal_data_bus <= "0001" & column_addr(7 downto 4); when 2 => internal_data_bus <= "0000" & column_addr(3 downto 0); when others => null; end case;
            when S_UFM_WAIT  => 
                -- The low byte (ufm_data_out(7:0)) corresponds to the earlier column and must be written first.
                -- The high byte (ufm_data_out(15:8)) corresponds to the later column and is written second.
                if is_writing_low_byte = '1' then 
                    -- This is the second write for the 16-bit word, send the high byte.
                    internal_data_bus <= ufm_data_out(15 downto 8); 
                else 
                    -- This is the first write for the 16-bit word, send the low byte.
                    internal_data_bus <= ufm_data_out(7 downto 0);
                end if;
            when others      => null;
        end case;
    end process;

    -- =============================================================================
    -- LOW-LEVEL PHYSICAL WRITE FSM
    -- =============================================================================
    process(clk_i, reset_i) begin if reset_i = '1' then cur_lcd_state <= sr_lcd_idle; elsif rising_edge(clk_i) then cur_lcd_state <= next_lcd_state; end if; end process;
    process(cur_lcd_state, write_trigger) begin next_lcd_state <= cur_lcd_state; case cur_lcd_state is when sr_lcd_idle => if write_trigger = '1' then next_lcd_state <= sr_lcd_setup; end if; when sr_lcd_setup => next_lcd_state <= sr_lcd_write; when sr_lcd_write => next_lcd_state <= sr_lcd_hold; when sr_lcd_hold => next_lcd_state <= sr_lcd_idle; end case; end process;
    write_trigger   <= '1' when cur_lcd_state = sr_lcd_idle and (cur_sys_state = S_SOFT_INIT or cur_sys_state = S_SET_ADDR or (cur_sys_state = S_UFM_WAIT and ufm_data_valid = '1')) else '0';
    chip_done_pulse <= '1' when cur_lcd_state = sr_lcd_hold else '0';
    process(cur_lcd_state, is_cmd, internal_data_bus) begin cs_n_o <= '1'; wr_n_o <= '1'; a0_o <= '1'; data_o <= (others => '0'); case cur_lcd_state is when sr_lcd_idle => null; when sr_lcd_setup => cs_n_o <= '0'; wr_n_o <= '1'; a0_o <= not is_cmd; data_o <= internal_data_bus; when sr_lcd_write => cs_n_o <= '0'; wr_n_o <= '0'; a0_o <= not is_cmd; data_o <= internal_data_bus; when sr_lcd_hold => cs_n_o <= '0'; wr_n_o <= '1'; a0_o <= not is_cmd; data_o <= internal_data_bus; end case; end process;
    
    -- Final Output Logic
    lcd_ok_o  <= '1' when cur_sys_state = S_SYS_IDLE else '0';
    is_cmd    <= '1' when cur_sys_state = S_SOFT_INIT or cur_sys_state = S_SET_ADDR else '0';
    ufm_nread <= '0' when cur_sys_state = S_UFM_REQ else '1';
    reset_n_o <= '0' when cur_sys_state = S_HW_RST else '1';
    rd_n_o    <= '1';

end arch;

