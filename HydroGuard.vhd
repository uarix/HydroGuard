library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity HydroGuard is
    port( 
        clk_i : in STD_LOGIC; 
        reset_i : in std_logic; 
        sw0_i : in std_logic; 
        btn2_i : in std_logic; 
        btn7_i : in std_logic; 
        trig_o : out std_logic; 
        echo_i : in std_logic; 
        data_o : out STD_LOGIC_VECTOR(7 downto 0); 
        reset_n_o : out STD_LOGIC; 
        cs_n_o : out STD_LOGIC; 
        wr_n_o : out STD_LOGIC; 
        rd_n_o : out STD_LOGIC; 
        a0_o : out STD_LOGIC; 
        segment_out_o : out std_logic_vector(6 downto 0); 
        cat_out_o : out std_logic_vector(7 downto 0); 
        row_out_o : out std_logic_vector(7 downto 0); 
        col_r_out_o : out std_logic_vector(7 downto 0); 
        col_g_out_o : out std_logic_vector(7 downto 0); 
        buzzer_out_o  : out std_logic; 
        floodgate_open_o : out std_logic 
    );
end HydroGuard;

architecture Behavioral of HydroGuard is

    component lcd_12864 is port(
        clk_i:in STD_LOGIC;
        reset_i:in std_logic;
        lcd_ok_o:out std_logic;
        pos_x_i:in STD_LOGIC_VECTOR(3 downto 0);
        pos_y_i:in STD_LOGIC_VECTOR(3 downto 0);
        char_index_i:in STD_LOGIC_VECTOR(6 downto 0);
        char_show_i:in STD_LOGIC;
        data_o:out STD_LOGIC_VECTOR(7 downto 0);
        reset_n_o:out STD_LOGIC;
        cs_n_o:out STD_LOGIC;
        wr_n_o:out STD_LOGIC;
        rd_n_o:out STD_LOGIC;
        a0_o:out STD_LOGIC
    );end component;

    component ultrasonic_driver is port (
        clk_i:in std_logic;
        reset_i:in std_logic;
        measure_i:in std_logic;
        ready_o:out std_logic;
        data_valid_o:out std_logic;
        trig_o:out std_logic;
        echo_i:in std_logic;
        distance_o:out std_logic_vector(9 downto 0)
    );end component;

    component seven_segment_driver is port (
        clk:in std_logic;
        reset:in std_logic;
        disp_data:in std_logic_vector(31 downto 0);
        segment_out:out std_logic_vector(6 downto 0);
        cat_out:out std_logic_vector(7 downto 0)
    );end component;

    component led_matrix_driver is port (
        clk:in std_logic;
        reset:in std_logic;
        display_data:in std_logic_vector(127 downto 0);
        row_out:out std_logic_vector(7 downto 0);
        col_r_out:out std_logic_vector(7 downto 0);
        col_g_out:out std_logic_vector(7 downto 0)
    );end component;

    component buzzer_driver is port (
        clk:in std_logic;
        reset:in std_logic;
        half_period_in:in natural range 0 to 500_000;
        buzzer_out:out std_logic
    );end component;

    component debounce is generic (
        CLK_FREQUENCY : natural := 1_000_000;
        DEBOUNCE_TIME_MS : natural := 20 
    ); 
    port ( 
        clk : in  std_logic;
        reset : in  std_logic;
        btn_in : in  std_logic;
        btn_pulse_out : out std_logic
    ); end component;

    type T_ARRAY_15 is array (0 to 14) of integer; 
    constant C_TEXT_ERROR   : T_ARRAY_15 := (85,76,84,82,65,83,79,78,73,67,32,70,65,73,76);

    type T_LCD_STATE is ( 
        S_LCD_INIT, 
        S_LCD_SPLASH_CLEAR_CMD, 
        S_LCD_SPLASH_CLEAR_WAIT, 
        S_LCD_SPLASH_CMD, 
        S_LCD_SPLASH_WAIT, 
        S_LCD_SPLASH_DELAY, 
        S_LCD_SELF_CHECK_START, 
        S_LCD_SELF_CHECK_WAIT, 
        S_LCD_FAIL_CMD, 
        S_LCD_FAIL_WAIT, 
        S_LCD_UI_CLEAR_CMD, 
        S_LCD_UI_CLEAR_WAIT, 
        S_LCD_SETUP_CMD, 
        S_LCD_SETUP_WAIT, 
        S_LCD_IDLE, 
        S_LCD_UPDATE_CMD, 
        S_LCD_UPDATE_WAIT 
    );

    signal run_normal_ops      : std_logic := '0';

    constant C_SELF_CHECK_TIMEOUT  : natural := 200_000; 
    signal self_check_timer      : natural range 0 to C_SELF_CHECK_TIMEOUT; 
    signal fsm_measure_pulse     : std_logic := '0'; 
    signal timer_measure_pulse   : std_logic; 
    signal measure_pulse         : std_logic;

    type T_ARRAY_14 is array (0 to 13) of integer; 
    constant C_TITLE_TEXT   : T_ARRAY_14 := (45,45,72,121,100,114,111,71,117,97,114,100,45,45); 
    
    type T_ARRAY_10 is array (0 to 9) of integer; 
    constant C_ID_TEXT      : T_ARRAY_10 := (50,48,50,51,32,32,32,32,32,32); 
    
    type T_ARRAY_7 is array (0 to 6) of integer; 
    constant C_LABEL_LEVEL  : T_ARRAY_7 := (76,69,86,69,76,58,32); 
    constant C_LABEL_STATUS : T_ARRAY_7 := (83,84,65,84,85,83,58); 
    constant C_LABEL_DMODE  : T_ARRAY_7 := (68,45,77,79,68,69,58); 
    constant C_LABEL_DSPEED : T_ARRAY_7 := (68,45,83,80,69,69,68); 
    
    type T_ARRAY_7_SPACES is array (0 to 6) of integer; 
    constant C_TEXT_SAFE    : T_ARRAY_7_SPACES := (83, 97,102,101,32, 32, 32); 
    constant C_TEXT_CAUTION : T_ARRAY_7_SPACES := (67, 97,117,116,105,111,110); 
    constant C_TEXT_DANGER  : T_ARRAY_7_SPACES := (68, 97,110,103,101,114,32); 
    constant C_TEXT_DRAIN   : T_ARRAY_7_SPACES := (68,114, 97,105,110,105,110); 
    constant C_TEXT_AUTO    : T_ARRAY_7_SPACES := (65,117,116,111,32, 32, 32); 
    constant C_TEXT_MANUAL  : T_ARRAY_7_SPACES := (77, 97,110,117, 97,108,32); 
    constant C_TEXT_BLANK7  : T_ARRAY_7_SPACES := (32, 32, 32, 32, 32, 32, 32); 
    
    constant C_SPLASH_DELAY_CYCLES : natural := 2_000_000; 
    signal splash_screen_timer     : natural range 0 to C_SPLASH_DELAY_CYCLES;

    type T_SYSTEM_MODE is (NORMAL_MONITORING, DRAINING); 
    signal system_mode : T_SYSTEM_MODE := NORMAL_MONITORING; 
    signal level_status_bcd : unsigned(3 downto 0); 
    signal distance_reg : unsigned(9 downto 0); 
    signal btn2_pulse : std_logic; 
    signal btn7_pulse : std_logic; 
    signal auto_drain_speed : unsigned(3 downto 0); 
    signal manual_drain_speed : unsigned(3 downto 0) := to_unsigned(1, 4); 
    signal drain_speed_bcd : unsigned(3 downto 0); 
    
    constant C_SAFE_THRESH : unsigned(9 downto 0) := to_unsigned(150, 10); 
    constant C_CAUTION_THRESH : unsigned(9 downto 0) := to_unsigned(100, 10); 
    constant C_DANGER_THRESH : unsigned(9 downto 0) := to_unsigned(50, 10); 
    
    signal bcd_h, bcd_t, bcd_u: unsigned(3 downto 0); 
    constant C_BLINK_PERIOD: natural := 500_000; 
    constant C_BLINK_HALF_PERIOD: natural := 250_000; 
    signal blinking_counter: natural range 0 to C_BLINK_PERIOD; 
    signal blink_enable: std_logic; 
    constant C_BUZZER_TONE_1KHZ: natural := 500; 
    constant C_CAUTION_PERIOD: natural := 1_000_000; 
    constant C_DANGER_PERIOD: natural := 500_000; 
    constant C_DRAIN_PERIOD: natural := 250_000; 
    constant C_CAUTION_BEEP_DUR: natural := 200_000; 
    constant C_DANGER_BEEP_DUR: natural := 200_000; 
    constant C_DRAIN_BEEP_DUR: natural := 125_000; 
    signal alarm_pattern_counter: natural range 0 to C_CAUTION_PERIOD; 
    signal buzzer_half_period: natural range 0 to C_BUZZER_TONE_1KHZ; 
    constant C_SPACE_ASCII : integer := 32; 
    constant C_SEG_BLANK : std_logic_vector(3 downto 0) := "1111"; 
    constant C_SCREEN_COLS : integer := 16; 
    constant C_SCREEN_ROWS : integer := 8; 
    constant COLOR_OFF : std_logic_vector(1 downto 0) := "00"; 
    constant COLOR_RED : std_logic_vector(1 downto 0) := "01"; 
    constant COLOR_GREEN : std_logic_vector(1 downto 0) := "10"; 
    constant COLOR_YELLOW : std_logic_vector(1 downto 0) := "11";

    signal lcd_state : T_LCD_STATE := S_LCD_INIT; 
    signal ultrasonic_valid : std_logic; 
    signal matrix_display_data : std_logic_vector(127 downto 0); 
    signal num_rows_to_light : integer range 0 to 8; 
    signal current_color_code : std_logic_vector(1 downto 0); 
    signal display_char_counter : integer range 0 to C_SCREEN_COLS-1 := 0; 
    signal clear_x : integer range 0 to C_SCREEN_COLS := 0; 
    signal clear_y : integer range 0 to C_SCREEN_ROWS := 0; 
    signal trigger_counter : unsigned(16 downto 0); 
    
    constant C_10HZ_COUNT : unsigned(16 downto 0) := to_unsigned(100000-1, 17); 
    signal ultrasonic_ready : std_logic; 
    signal distance_bin : std_logic_vector(9 downto 0); 
    signal lcd_ok : std_logic; 
    signal pos_x : STD_LOGIC_VECTOR(3 downto 0); 
    signal pos_y : STD_LOGIC_VECTOR(3 downto 0); 
    signal char_index : STD_LOGIC_VECTOR(6 downto 0); 
    signal char_show : STD_LOGIC := '0'; 
    signal seg_disp_data : std_logic_vector(31 downto 0); 
    signal animation_counter : natural range 0 to 200_000; 
    signal animation_column : integer range 0 to 7; 
    signal write_step_counter : integer range 0 to 15 := 0; 
    signal current_char_in_string : integer range 0 to 15 := 0; 
    signal status_text_ascii : T_ARRAY_7_SPACES; 
    signal dmode_text_ascii : T_ARRAY_7_SPACES; 
    signal dspeed_text_ascii : T_ARRAY_7_SPACES;

    signal value_to_convert_bin : unsigned(9 downto 0);
    
begin

    DEBOUNCER_BTN2 : debounce port map (
        clk=>clk_i, 
        reset=>reset_i, 
        btn_in=>btn2_i, 
        btn_pulse_out=>btn2_pulse
    ); 
    
    DEBOUNCER_BTN7 : debounce port map (
        clk=>clk_i, 
        reset=>reset_i, 
        btn_in=>btn7_i, 
        btn_pulse_out=>btn7_pulse
    ); 
    
    U_LCD_DRIVER : lcd_12864 port map (
        clk_i=>clk_i,
        reset_i=>reset_i,
        lcd_ok_o=>lcd_ok,
        pos_x_i=>pos_x,
        pos_y_i=>pos_y,
        char_index_i=>char_index,
        char_show_i=>char_show,
        data_o=>data_o,
        reset_n_o=>reset_n_o,
        cs_n_o=>cs_n_o,
        wr_n_o=>wr_n_o,
        rd_n_o=>rd_n_o,
        a0_o=>a0_o
    ); 
    
    U_ULTRASONIC : ultrasonic_driver port map (
        clk_i=>clk_i,
        reset_i=>reset_i,
        measure_i=>measure_pulse,
        ready_o=>ultrasonic_ready,
        data_valid_o=>ultrasonic_valid,
        trig_o=>trig_o,
        echo_i=>echo_i,
        distance_o=>distance_bin
    ); 
    
    U_7SEG_DRIVER : seven_segment_driver port map (
        clk=>clk_i,
        reset=>reset_i,
        disp_data=>seg_disp_data,
        segment_out=>segment_out_o,
        cat_out=>cat_out_o
    ); 
    
    U_MATRIX_DRIVER : led_matrix_driver port map (
        clk=>clk_i,
        reset=>reset_i,
        display_data=>matrix_display_data,
        row_out=>row_out_o,
        col_r_out=>col_r_out_o,
        col_g_out=>col_g_out_o
    ); 
    
    U_BUZZER_DRIVER : buzzer_driver port map (
        clk=>clk_i,
        reset=>reset_i,
        half_period_in=>buzzer_half_period,
        buzzer_out=>buzzer_out_o
    );

    measure_pulse <= timer_measure_pulse or fsm_measure_pulse;

    value_to_convert_bin <= to_unsigned(0, 10) WHEN unsigned(distance_reg) > 1000 ELSE
                          to_unsigned(1000, 10) - unsigned(distance_reg);

    bin_to_bcd_proc : process(all)
        variable bcd_val : unsigned(23 downto 0);
    begin
        if run_normal_ops = '0' then
            bcd_h <= (others => '1'); -- Output blank BCD code
            bcd_t <= (others => '1');
            bcd_u <= (others => '1');
        else
            bcd_val := (others => '0'); bcd_val(9 downto 0) := value_to_convert_bin;
            for i in 0 to 9 loop
                if bcd_val(11 downto 8) > 4 then bcd_val(11 downto 8) := bcd_val(11 downto 8) + 3; end if;
                if bcd_val(15 downto 12) > 4 then bcd_val(15 downto 12) := bcd_val(15 downto 12) + 3; end if;
                if bcd_val(19 downto 16) > 4 then bcd_val(19 downto 16) := bcd_val(19 downto 16) + 3; end if;
                bcd_val := shift_left(bcd_val, 1);
            end loop;
            bcd_h <= bcd_val(19 downto 16); bcd_t <= bcd_val(15 downto 12); bcd_u <= bcd_val(11 downto 8);
        end if;
    end process bin_to_bcd_proc;

    row_counter_proc : process(all)
    begin
        if run_normal_ops = '0' then
            num_rows_to_light <= 0; 
        else
            if distance_reg < to_unsigned(50, 10) then num_rows_to_light <= 8;
            elsif distance_reg < to_unsigned(75, 10) then num_rows_to_light <= 7;
            elsif distance_reg < to_unsigned(100, 10) then num_rows_to_light <= 6;
            elsif distance_reg < to_unsigned(125, 10) then num_rows_to_light <= 5;
            elsif distance_reg < to_unsigned(150, 10) then num_rows_to_light <= 4;
            elsif distance_reg < to_unsigned(175, 10) then num_rows_to_light <= 3;
            elsif distance_reg < to_unsigned(200, 10) then num_rows_to_light <= 2;
            else num_rows_to_light <= 1; end if;
        end if;
    end process row_counter_proc;
    
    WITH level_status_bcd SELECT
        status_text_ascii <= C_TEXT_SAFE    WHEN "0001",
                             C_TEXT_CAUTION WHEN "0010",
                             C_TEXT_DANGER  WHEN "0011",
                             C_TEXT_DRAIN   WHEN "0100",
                             C_TEXT_BLANK7  WHEN OTHERS;

    dmode_text_ascii <= C_TEXT_BLANK7 WHEN system_mode = NORMAL_MONITORING ELSE
                    C_TEXT_AUTO   WHEN sw0_i = '0' ELSE
                    C_TEXT_MANUAL;
    
    WITH drain_speed_bcd SELECT
        dspeed_text_ascii <= (32,32,32,49,32,32,32)     WHEN "0001",
                             (32,32,32,50,32,32,32)     WHEN "0010",
                             (32,32,32,51,32,32,32)     WHEN "0011",
                             C_TEXT_BLANK7 WHEN OTHERS;
    
    floodgate_open_o <= '1' WHEN system_mode = DRAINING ELSE '0';

    WITH level_status_bcd SELECT
        auto_drain_speed <= "0001"                WHEN "0010",         -- 水位: CAUTION -> 速度 1
                            "0010"                WHEN "0011",         -- 水位: DANGER  -> 速度 2
                            "0011"                WHEN "0100",         -- 水位: DRAIN   -> 速度 3
                            unsigned(C_SEG_BLANK) WHEN OTHERS;

    drain_speed_bcd <= auto_drain_speed   WHEN sw0_i = '0' ELSE -- 自动模式
                   manual_drain_speed;                     -- 手动模式
    
    -- 显示排水速度 (第3位数码管)
    seg_disp_data(11 DOWNTO 8) <= C_SEG_BLANK WHEN system_mode = NORMAL_MONITORING ELSE
                                std_logic_vector(drain_speed_bcd);

    -- 显示水位百位 (第8位数码管)，在危险水位时根据 blink_enable 信号闪烁
    seg_disp_data(31 DOWNTO 28) <= C_SEG_BLANK WHEN (bcd_h = 0) OR (level_status_bcd = "0011" AND blink_enable = '0') ELSE
                                std_logic_vector(bcd_h);

    -- 显示水位十位 (第7位数码管)，在危险水位时闪烁
    seg_disp_data(27 DOWNTO 24) <= C_SEG_BLANK WHEN (bcd_h = 0 AND bcd_t = 0) OR (level_status_bcd = "0011" AND blink_enable = '0') ELSE
                                std_logic_vector(bcd_t);

    -- 显示水位个位 (第6位数码管)，在危险水位时闪烁
    seg_disp_data(23 DOWNTO 20) <= C_SEG_BLANK WHEN (level_status_bcd = "0011" AND blink_enable = '0') ELSE
                                std_logic_vector(bcd_u);

    -- 显示状态BCD码 (第1位数码管)
    seg_disp_data(3 DOWNTO 0) <= std_logic_vector(level_status_bcd);

    -- 熄灭其他数码管
    seg_disp_data(19 DOWNTO 12) <= (OTHERS => '1');
    seg_disp_data(7 DOWNTO 4)   <= (OTHERS => '1');

    -- 闪烁使能信号生成
    blink_enable <= '1' WHEN blinking_counter < C_BLINK_HALF_PERIOD ELSE '0';

    WITH level_status_bcd SELECT
        current_color_code <= COLOR_GREEN  WHEN "0001",
                              COLOR_YELLOW WHEN "0010",
                              COLOR_RED    WHEN "0011",
                              COLOR_RED    WHEN "0100",  -- DANGER 和 DRAIN 状态都显示红色
                              COLOR_OFF    WHEN OTHERS;

    -- LED矩阵数据生成器进程
    matrix_data_builder_proc : process(all)
    -- 在 VHDL-2008 中，`process(all)` 会自动包含所有在进程中读取的信号到敏感列表
    CONSTANT ROW_DATA_OFF : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    VARIABLE row_data_on  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    VARIABLE anim_data_row: STD_LOGIC_VECTOR(15 DOWNTO 0);
    BEGIN
        IF system_mode = NORMAL_MONITORING THEN
            -- 监控模式: 显示一个与水位高度对应的彩色条
            -- 1. 生成单行点亮时的数据 (所有像素点颜色相同)
            FOR i IN 0 TO 7 LOOP
                row_data_on(2*i+1 DOWNTO 2*i) := current_color_code;
            END LOOP;

            -- 2. 根据需要点亮的行数 (num_rows_to_light) 填充整个显示数据
            FOR i IN 0 TO 7 LOOP
                IF i < num_rows_to_light THEN
                    matrix_display_data(i*16 + 15 DOWNTO i*16) <= row_data_on;
                ELSE
                    matrix_display_data(i*16 + 15 DOWNTO i*16) <= ROW_DATA_OFF;
                END IF;
            END LOOP;
        ELSE -- DRAINING 模式
            -- 排水模式: 显示一个滚动的红色动画
            -- 1. 生成单行数据，只在动画的当前列显示红色
            anim_data_row := (OTHERS => '0');
            anim_data_row(animation_column*2+1 DOWNTO animation_column*2) := COLOR_RED;

            -- 2. 将此行数据复制到所有行，形成垂直滚动的效果
            FOR i IN 0 TO 7 LOOP
                matrix_display_data(i*16 + 15 DOWNTO i*16) <= anim_data_row;
            END LOOP;
        END IF;
    END PROCESS matrix_data_builder_proc;

    --==============================================================================
    -- Sequential Logic
    --==============================================================================
    trigger_gen_proc : process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            trigger_counter <= (others => '0');
            timer_measure_pulse <= '0';
        elsif rising_edge(clk_i) then
            timer_measure_pulse <= '0';
            if run_normal_ops = '1' then -- Only run if self-test has passed
                if ultrasonic_ready = '1' then
                    if trigger_counter = C_10HZ_COUNT then
                        trigger_counter <= (others => '0');
                        timer_measure_pulse <= '1';
                    else
                        trigger_counter <= trigger_counter + 1;
                    end if;
                else
                    trigger_counter <= (others => '0');
                end if;
            end if;
        end if;
    end process trigger_gen_proc;
        
    -- Main LCD FSM 
    lcd_fsm_proc : process(clk_i, reset_i)
        variable char_ascii : integer;
    begin
        if reset_i = '1' then
            lcd_state <= S_LCD_INIT;
            char_show <= '0';
            clear_x <= 0; clear_y <= 0;
            write_step_counter <= 0; current_char_in_string <= 0;
            distance_reg <= (others => '0');
            splash_screen_timer <= 0;
            self_check_timer <= 0;
            fsm_measure_pulse <= '0';
            run_normal_ops <= '0';
        elsif rising_edge(clk_i) then
            char_show <= '0';
            fsm_measure_pulse <= '0';

            case lcd_state is
                -- Splash Screen Sequence
                when S_LCD_INIT => if lcd_ok = '1' then clear_x <= 0; clear_y <= 0; lcd_state <= S_LCD_SPLASH_CLEAR_CMD; end if;
                when S_LCD_SPLASH_CLEAR_CMD => if lcd_ok = '1' then pos_y <= std_logic_vector(to_unsigned(clear_y, 4)); pos_x <= std_logic_vector(to_unsigned(clear_x, 4)); char_index <= std_logic_vector(to_unsigned(C_SPACE_ASCII, 7)); char_show <= '1'; lcd_state <= S_LCD_SPLASH_CLEAR_WAIT; end if;
                when S_LCD_SPLASH_CLEAR_WAIT => if lcd_ok = '1' then if clear_x = C_SCREEN_COLS - 1 then clear_x <= 0; if clear_y = C_SCREEN_ROWS - 1 then write_step_counter <= 0; current_char_in_string <= 0; lcd_state <= S_LCD_SPLASH_CMD; else clear_y <= clear_y + 1; lcd_state <= S_LCD_SPLASH_CLEAR_CMD; end if; else clear_x <= clear_x + 1; lcd_state <= S_LCD_SPLASH_CLEAR_CMD; end if; end if;
                when S_LCD_SPLASH_CMD => if lcd_ok = '1' then case write_step_counter is when 0 => pos_y <= "0010"; pos_x <= std_logic_vector(to_unsigned(1 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(C_TITLE_TEXT(current_char_in_string), 7)); when 1 => pos_y <= "0101"; pos_x <= std_logic_vector(to_unsigned(3 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(C_ID_TEXT(current_char_in_string), 7)); when others => null; end case; char_show <= '1'; lcd_state <= S_LCD_SPLASH_WAIT; end if;
                when S_LCD_SPLASH_WAIT => if lcd_ok = '1' then if (write_step_counter = 0 and current_char_in_string = C_TITLE_TEXT'length - 1) or (write_step_counter = 1 and current_char_in_string = C_ID_TEXT'length - 1) then current_char_in_string <= 0; if write_step_counter = 1 then splash_screen_timer <= 0; lcd_state <= S_LCD_SPLASH_DELAY; else write_step_counter <= write_step_counter + 1; lcd_state <= S_LCD_SPLASH_CMD; end if; else current_char_in_string <= current_char_in_string + 1; lcd_state <= S_LCD_SPLASH_CMD; end if; end if;
                when S_LCD_SPLASH_DELAY => if splash_screen_timer < C_SPLASH_DELAY_CYCLES - 1 then splash_screen_timer <= splash_screen_timer + 1; else self_check_timer <= 0; lcd_state <= S_LCD_SELF_CHECK_START; end if;
                
                -- Self-Test Sequence
                when S_LCD_SELF_CHECK_START =>
                    fsm_measure_pulse <= '1';
                    lcd_state <= S_LCD_SELF_CHECK_WAIT;
                
                when S_LCD_SELF_CHECK_WAIT =>
                    if ultrasonic_valid = '1' and unsigned(distance_bin) > 0 then
                        run_normal_ops <= '1';
                        clear_x <= 0; clear_y <= 0;
                        lcd_state <= S_LCD_UI_CLEAR_CMD;
                    elsif self_check_timer >= C_SELF_CHECK_TIMEOUT - 1 then
                        write_step_counter <= 0; current_char_in_string <= 0;
                        lcd_state <= S_LCD_FAIL_CMD;
                    else
                        self_check_timer <= self_check_timer + 1;
                    end if;

                when S_LCD_FAIL_CMD => if lcd_ok = '1' then pos_y <= "0011"; pos_x <= std_logic_vector(to_unsigned(1 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(C_TEXT_ERROR(current_char_in_string), 7)); char_show <= '1'; lcd_state <= S_LCD_FAIL_WAIT; end if;
                when S_LCD_FAIL_WAIT => if lcd_ok = '1' then if current_char_in_string < C_TEXT_ERROR'length - 1 then current_char_in_string <= current_char_in_string + 1; lcd_state <= S_LCD_FAIL_CMD; else null; end if; end if;
                when S_LCD_UI_CLEAR_CMD => if lcd_ok = '1' then pos_y <= std_logic_vector(to_unsigned(clear_y, 4)); pos_x <= std_logic_vector(to_unsigned(clear_x, 4)); char_index <= std_logic_vector(to_unsigned(C_SPACE_ASCII, 7)); char_show <= '1'; lcd_state <= S_LCD_UI_CLEAR_WAIT; end if;
                when S_LCD_UI_CLEAR_WAIT => if lcd_ok = '1' then if clear_x = C_SCREEN_COLS - 1 then clear_x <= 0; if clear_y = C_SCREEN_ROWS - 1 then write_step_counter <= 0; current_char_in_string <= 0; lcd_state <= S_LCD_SETUP_CMD; else clear_y <= clear_y + 1; lcd_state <= S_LCD_UI_CLEAR_CMD; end if; else clear_x <= clear_x + 1; lcd_state <= S_LCD_UI_CLEAR_CMD; end if; end if;
                when S_LCD_SETUP_CMD => if lcd_ok = '1' then case write_step_counter is when 0 => pos_y <= "0000"; pos_x <= std_logic_vector(to_unsigned(1 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(C_TITLE_TEXT(current_char_in_string), 7)); when 1 => pos_y <= "0010"; pos_x <= std_logic_vector(to_unsigned(3 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(C_LABEL_LEVEL(current_char_in_string), 7)); when 2 => pos_y <= "0100"; pos_x <= std_logic_vector(to_unsigned(0 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(C_LABEL_STATUS(current_char_in_string), 7)); when 3 => pos_y <= "0110"; pos_x <= std_logic_vector(to_unsigned(0 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(C_LABEL_DMODE(current_char_in_string), 7)); when 4 => pos_y <= "0111"; pos_x <= std_logic_vector(to_unsigned(0 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(C_LABEL_DSPEED(current_char_in_string), 7)); when others => null; end case; char_show <= '1'; lcd_state <= S_LCD_SETUP_WAIT; end if;
                when S_LCD_SETUP_WAIT => if lcd_ok = '1' then if (write_step_counter = 0 and current_char_in_string = C_TITLE_TEXT'length - 1) or (write_step_counter > 0 and current_char_in_string = 6) then current_char_in_string <= 0; if write_step_counter = 4 then lcd_state <= S_LCD_IDLE; else write_step_counter <= write_step_counter + 1; lcd_state <= S_LCD_SETUP_CMD; end if; else current_char_in_string <= current_char_in_string + 1; lcd_state <= S_LCD_SETUP_CMD; end if; end if;
                when S_LCD_IDLE => if ultrasonic_valid = '1' then distance_reg <= unsigned(distance_bin); write_step_counter <= 0; current_char_in_string <= 0; lcd_state <= S_LCD_UPDATE_CMD; end if;
                when S_LCD_UPDATE_CMD => if lcd_ok = '1' then case write_step_counter is when 0 => pos_y <= "0010"; pos_x <= std_logic_vector(to_unsigned(10 + current_char_in_string, 4)); case current_char_in_string is when 0 => if bcd_h=0 then char_ascii := C_SPACE_ASCII; else char_ascii := to_integer(bcd_h)+48; end if; when 1 => if bcd_h=0 and bcd_t=0 then char_ascii := C_SPACE_ASCII; else char_ascii := to_integer(bcd_t)+48; end if; when others => char_ascii := to_integer(bcd_u)+48; end case; char_index <= std_logic_vector(to_unsigned(char_ascii, 7)); when 1 => pos_y <= "0100"; pos_x <= std_logic_vector(to_unsigned(8 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(status_text_ascii(current_char_in_string), 7)); when 2 => pos_y <= "0110"; pos_x <= std_logic_vector(to_unsigned(8 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(dmode_text_ascii(current_char_in_string), 7)); when 3 => pos_y <= "0111"; pos_x <= std_logic_vector(to_unsigned(8 + current_char_in_string, 4)); char_index <= std_logic_vector(to_unsigned(dspeed_text_ascii(current_char_in_string), 7)); when others => null; end case; char_show <= '1'; lcd_state <= S_LCD_UPDATE_WAIT; end if;
                when S_LCD_UPDATE_WAIT => if lcd_ok = '1' then if (write_step_counter = 0 and current_char_in_string = 2) or (write_step_counter > 0 and current_char_in_string = 6) then current_char_in_string <= 0; if write_step_counter = 3 then lcd_state <= S_LCD_IDLE; else write_step_counter <= write_step_counter + 1; lcd_state <= S_LCD_UPDATE_CMD; end if; else current_char_in_string <= current_char_in_string + 1; lcd_state <= S_LCD_UPDATE_CMD; end if; end if;
            end case;
        end if;
    end process lcd_fsm_proc;
    --------------------------------------------------------------------------------
    -- 任务1: 主系统状态机 (FSM)
    --------------------------------------------------------------------------------

    -- 在“正常监控”和“排水”模式之间切换。
    system_mode_proc : PROCESS(clk_i, reset_i)
    BEGIN
    IF reset_i = '1' THEN
        system_mode <= NORMAL_MONITORING;
    ELSIF rising_edge(clk_i) THEN
        CASE system_mode IS

        -- 状态: 正常监控
        WHEN NORMAL_MONITORING =>
            -- 条件1: 在危险水位时，按下按钮手动启动排水
            IF (btn7_pulse = '1' AND level_status_bcd = "0011") THEN
                system_mode <= DRAINING;
            -- 条件2: 水位超过危险阈值时，自动启动排水
            ELSIF (ultrasonic_valid = '1' AND unsigned(distance_bin) < C_DANGER_THRESH) THEN
                system_mode <= DRAINING;
            END IF;

        -- 状态: 正在排水
        WHEN DRAINING =>
            -- 条件1: 按下按钮手动停止排水
            IF (btn7_pulse = '1') THEN
                system_mode <= NORMAL_MONITORING;
            -- 条件2: 水位降至安全阈值以下时，自动停止排水
            ELSIF (ultrasonic_valid = '1' AND unsigned(distance_bin) >= C_SAFE_THRESH) THEN
                system_mode <= NORMAL_MONITORING;
            END IF;

        END CASE;
    END IF;
    END PROCESS system_mode_proc;

    ---

    --------------------------------------------------------------------------------
    -- 任务2: 手动排水速度控制器
    --------------------------------------------------------------------------------

    -- 该进程管理手动模式下的排水速度。
    -- 当系统进入“正常监控”模式时，速度会自动重置。
    manual_speed_proc : PROCESS(clk_i, reset_i)
    BEGIN
    IF reset_i = '1' THEN
        manual_drain_speed <= to_unsigned(1, 4); -- 复位到速度 1
    ELSIF rising_edge(clk_i) THEN
        -- 仅在“排水”模式且开关拨到“手动”时，才响应按钮
        IF system_mode = DRAINING AND sw0_i = '1' AND btn2_pulse = '1' THEN
        CASE manual_drain_speed IS -- 状态转移表
            WHEN "0001" => manual_drain_speed <= "0010"; -- 速度 1 -> 2
            WHEN "0010" => manual_drain_speed <= "0011"; -- 速度 2 -> 3
            WHEN "0011" => manual_drain_speed <= "0001"; -- 速度 3 -> 1
            WHEN OTHERS => manual_drain_speed <= "0001"; -- 异常保护
        END CASE;
        END IF;

        -- 如果系统返回“正常监控”模式，则将手动速度重置为初始值
        IF system_mode = NORMAL_MONITORING THEN
        manual_drain_speed <= to_unsigned(1, 4);
        END IF;
    END IF;
    END PROCESS manual_speed_proc;

    ---

    --------------------------------------------------------------------------------
    -- 任务3: 计时器和信号发生器
    --------------------------------------------------------------------------------

    -- LED 矩阵动画计时器
    -- 在排水模式下，根据排水速度生成一个周期性信号来驱动动画。
    animation_timer_proc : PROCESS(clk_i, reset_i)
    VARIABLE anim_period : NATURAL RANGE 0 TO 200_000;
    BEGIN
    IF reset_i = '1' THEN
        animation_counter <= 0;
        animation_column  <= 0;
    ELSIF rising_edge(clk_i) THEN
        IF system_mode = DRAINING THEN
        -- 1. 根据当前排水速度选择动画更新周期
        CASE drain_speed_bcd IS
            WHEN "0001" => anim_period := 200_000; -- 速度1: 慢
            WHEN "0010" => anim_period := 100_000; -- 速度2: 中
            WHEN "0011" => anim_period := 50_000;  -- 速度3: 快
            WHEN OTHERS => anim_period := 200_000;
        END CASE;

        -- 2. 驱动计数器和动画列索引
        IF animation_counter >= anim_period - 1 THEN
            animation_counter <= 0;
            IF animation_column = 7 THEN
                animation_column <= 0; -- 动画循环
            ELSE
                animation_column <= animation_column + 1;
            END IF;
        ELSE
            animation_counter <= animation_counter + 1;
        END IF;
        ELSE
            -- 不在排水模式时，重置动画状态
            animation_counter <= 0;
            animation_column  <= 0;
        END IF;
    END IF;
    END PROCESS animation_timer_proc;

    ---

    -- 通用闪烁计时器
    -- 生成一个固定的周期性信号，用于驱动需要闪烁的显示元件。
    blinking_timer_proc : PROCESS(clk_i, reset_i)
    BEGIN
    IF reset_i = '1' THEN
        blinking_counter <= 0;
    ELSIF rising_edge(clk_i) THEN
        IF blinking_counter >= C_BLINK_PERIOD - 1 THEN
        blinking_counter <= 0; -- 计数器归零
        ELSE
        blinking_counter <= blinking_counter + 1;
        END IF;
    END IF;
    END PROCESS blinking_timer_proc;

    ---

    -- 警报蜂鸣器模式发生器
    -- 根据不同的水位状态，生成不同模式（频率、占空比）的警报声。
    alarm_pattern_proc : PROCESS(clk_i, reset_i)
        VARIABLE current_period   : NATURAL RANGE 0 TO C_CAUTION_PERIOD;
        VARIABLE current_beep_dur : NATURAL RANGE 0 TO C_CAUTION_BEEP_DUR;
    BEGIN
    IF reset_i = '1' THEN
        alarm_pattern_counter <= 0;
        buzzer_half_period    <= 0; -- 默认关闭
    ELSIF rising_edge(clk_i) THEN
        -- 1. 根据水位状态选择警报模式（周期和响声时长）
        CASE level_status_bcd IS
        WHEN "0010" => -- CAUTION
            current_period   := C_CAUTION_PERIOD;
            current_beep_dur := C_CAUTION_BEEP_DUR;
        WHEN "0011" => -- DANGER
            current_period   := C_DANGER_PERIOD;
            current_beep_dur := C_DANGER_BEEP_DUR;
        WHEN "0100" => -- DRAIN
            current_period   := C_DRAIN_PERIOD;
            current_beep_dur := C_DRAIN_BEEP_DUR;
        WHEN OTHERS => -- SAFE or OFF
            current_period   := 0;
            current_beep_dur := 0;
        END CASE;

        -- 2. 根据选定的模式生成蜂鸣器信号
        IF current_period = 0 THEN
        alarm_pattern_counter <= 0;
        buzzer_half_period    <= 0; -- 关闭蜂鸣器
        ELSE
        -- 判断当前是否在“响声”时间段内
        IF alarm_pattern_counter < current_beep_dur THEN
            buzzer_half_period <= C_BUZZER_TONE_1KHZ; -- 产生1kHz音调
        ELSE
            buzzer_half_period <= 0; -- 静音
        END IF;

        -- 驱动模式计数器
        IF alarm_pattern_counter >= current_period - 1 THEN
            alarm_pattern_counter <= 0; -- 模式周期结束，重置
        ELSE
            alarm_pattern_counter <= alarm_pattern_counter + 1;
        END IF;
        END IF;
    END IF;
    END PROCESS alarm_pattern_proc;

    ---

    --------------------------------------------------------------------------------
    -- 任务4: 水位状态解码器
    --------------------------------------------------------------------------------

    -- 根据超声波传感器测得的距离，将其转换为离散的水位状态BCD码。
    level_status_proc : PROCESS(clk_i, reset_i)
    BEGIN
    IF reset_i = '1' THEN
        level_status_bcd <= unsigned(C_SEG_BLANK);
    ELSIF rising_edge(clk_i) THEN
        IF ultrasonic_valid = '1' THEN
        -- 将距离与预设阈值比较，确定当前状态
        IF unsigned(distance_bin) >= C_SAFE_THRESH THEN 
            level_status_bcd <= "0001"; -- 状态: SAFE
        ELSIF unsigned(distance_bin) >= C_CAUTION_THRESH THEN
            level_status_bcd <= "0010"; -- 状态: CAUTION
        ELSIF unsigned(distance_bin) >= C_DANGER_THRESH THEN
            level_status_bcd <= "0011"; -- 状态: DANGER
        ELSE
            level_status_bcd <= "0100"; -- 状态: DRAIN 
        END IF;
        END IF;
    END IF;
    END PROCESS level_status_proc;
end Behavioral;