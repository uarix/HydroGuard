-- 8x8 双色 LED 点阵驱动模块
--
-- 功能：
-- 1. 驱动一个 8x8 共阳极、行扫描的双色LED点阵。
-- 2. 每个像素点可独立控制为 熄灭、红色、绿色、黄色 (红+绿)。
--
-- 参数：
-- - 系统时钟: 1 MHz
-- - 行扫描频率: ~1.6 kHz (1,000,000 Hz / 625)
-- - 整屏刷新率: ~200 Hz (1.6 kHz / 8 行)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_matrix_driver is
    port (
        -- 系统时钟 (1 MHz)
        clk          : in  std_logic;
        reset        : in  std_logic;

        -- 128位显示数据输入
        -- 每一行占用16位，每个像素点占用2位 [G, R]
        -- display_data(127 downto 112): 第7行 (ROW7) 的数据
        -- ...
        -- display_data(15 downto 0): 第0行 (ROW0) 的数据
        --
        -- 例如，对于第0行:
        -- display_data(1:0)   -> 第0列像素点 (ROW0, COL0)
        -- display_data(3:2)   -> 第1列像素点 (ROW0, COL1)
        -- ...
        -- display_data(15:14) -> 第7列像素点 (ROW0, COL7)
        --
        -- 颜色编码 (G, R):
        -- "00" -> 熄灭
        -- "01" -> 红色
        -- "10" -> 绿色
        -- "11" -> 黄色
        display_data : in  std_logic_vector(127 downto 0);

        -- 行选通信号输出 (ROW0 ~ ROW7, 低电平有效)
        row_out      : out std_logic_vector(7 downto 0);

        -- 红色LED列驱动信号输出 (COLR0 ~ COLR7, 高电平有效)
        col_r_out    : out std_logic_vector(7 downto 0);

        -- 绿色LED列驱动信号输出 (COLG0 ~ COLG7, 高电平有效)
        col_g_out    : out std_logic_vector(7 downto 0)
    );
end entity led_matrix_driver;

architecture rtl of led_matrix_driver is

    -- 时钟分频系数，用于产生行扫描时钟
    -- 1,000,000 Hz / 1600 Hz (目标行频) ≈ 625
    constant CLK_DIVIDER_VALUE : integer := 625;

    -- 分频计数器
    signal refresh_counter : integer range 0 to CLK_DIVIDER_VALUE - 1 := 0;
    -- 行扫描时钟脉冲信号
    signal refresh_tick    : std_logic := '0';

    -- 3位行选择计数器，用于循环扫描 0 到 7 行
    signal row_selector    : unsigned(2 downto 0) := (others => '0');

    -- 用于暂存当前扫描行对应的16位颜色数据
    signal current_row_data : std_logic_vector(15 downto 0);

begin

    -- 1. 时钟分频器进程
    -- 产生一个约 1.6 kHz 的单周期脉冲信号 (refresh_tick) 用于切换行
    clk_divider_proc : process(clk, reset)
    begin
        if reset = '1' then
            refresh_counter <= 0;
            refresh_tick    <= '0';
        elsif rising_edge(clk) then
            if refresh_counter = CLK_DIVIDER_VALUE - 1 then
                refresh_counter <= 0;
                refresh_tick    <= '1';
            else
                refresh_counter <= refresh_counter + 1;
                refresh_tick    <= '0';
            end if;
        end if;
    end process clk_divider_proc;

    -- 2. 行扫描器进程
    -- 在每个 refresh_tick 上升沿，切换到下一行
    row_scanner_proc : process(clk, reset)
    begin
        if reset = '1' then
            row_selector <= (others => '0');
        elsif rising_edge(clk) then
            if refresh_tick = '1' then
                row_selector <= row_selector + 1;
            end if;
        end if;
    end process row_scanner_proc;

    -- 3. 数据选择器
    -- 根据当前的行选择信号 (row_selector)，从128位的输入数据中选出对应的16位行数据
    with to_integer(row_selector) select
        current_row_data <=
            display_data(15 downto 0)   when 0,
            display_data(31 downto 16)  when 1,
            display_data(47 downto 32)  when 2,
            display_data(63 downto 48)  when 3,
            display_data(79 downto 64)  when 4,
            display_data(95 downto 80)  when 5,
            display_data(111 downto 96) when 6,
            display_data(127 downto 112) when 7,
            (others => '0')             when others;

    -- 4. 列数据分离
    -- 将16位的行数据 (current_row_data) 分离成8位的红色数据和8位的绿色数据
    deinterleave_gen : for i in 0 to 7 generate
        col_r_out(i) <= current_row_data(2 * i);     -- 偶数位是红色数据
        col_g_out(i) <= current_row_data(2 * i + 1); -- 奇数位是绿色数据
    end generate deinterleave_gen;

    -- 5. 行驱动器 (3-to-8 译码器，低电平有效)
    -- 根据行选择信号 (row_selector)，将对应行的输出置为低电平，其他行为高电平
    row_driver_proc : process(row_selector)
        -- 使用一个临时变量来简化逻辑
        variable row_temp : std_logic_vector(7 downto 0);
    begin
        row_temp := (others => '1'); -- 默认所有行都关闭（高电平）
        row_temp(to_integer(row_selector)) := '0'; -- 打开（置低）选中的行
        row_out <= row_temp;
    end process row_driver_proc;

end architecture rtl;
