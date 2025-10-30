-- 蜂鸣器驱动模块 (Buzzer Driver)
--
-- 功能：
-- 1. 根据输入的“半周期计数值”，生成对应的PWM方波来驱动蜂鸣器。
-- 2. 输出方波的占空比固定为50%。
-- 3. 当输入计数值为 0 时，关闭蜂鸣器（输出持续低电平）。
--
-- 参数：
-- - 系统时钟: 1 MHz
-- - 输入端口 `half_period_in`: 控制PWM频率的半周期计数值。
-- 计算公式:
-- half_period_in = (系统时钟频率 / (2 * 目标频率))
--
-- 示例:
-- - 系统时钟 = 1,000,000 Hz
-- - 目标频率 = 1000 Hz (1kHz)
-- - half_period_in = (1,000,000 / (2 * 1000)) = 500
--
-- 将计算出的 `500` 作为 `half_period_in` 端口的输入即可产生1kHz的声音。

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buzzer_driver is
    port (
        -- 系统时钟 (1 MHz)
        clk            : in  std_logic;
        reset          : in  std_logic;

        -- 半周期计数值输入, 用于直接控制音调
        -- 输入 0 将使蜂鸣器静音
        half_period_in : in  natural range 0 to 500_000;

        -- PWM波形输出至蜂鸣器
        buzzer_out     : buffer std_logic
    );
end entity buzzer_driver;

architecture rtl of buzzer_driver is

    -- 定义系统时钟频率，用于设置计数器范围
    constant CLK_FREQUENCY : natural := 1_000_000;

    -- 用于PWM生成的内部计数器
    signal pwm_counter : natural range 0 to CLK_FREQUENCY / 2;

begin

    -- PWM 生成器进程
    pwm_gen_proc : process(clk, reset)
    begin
        if reset = '1' then
            pwm_counter <= 0;
            buzzer_out  <= '0';
        elsif rising_edge(clk) then
            -- 直接使用输入的计数值 `half_period_in` 进行判断
            -- 值为0表示静音
            if half_period_in > 0 then
                -- 当计数器到达半周期阈值减1时
                if pwm_counter >= half_period_in - 1 then
                    pwm_counter <= 0;          -- 复位计数器
                    buzzer_out  <= not buzzer_out; -- 翻转输出电平以形成方波
                else
                    pwm_counter <= pwm_counter + 1; -- 计数器加一
                end if;
            else
                -- 如果输入的计数值为0，保持静音状态
                pwm_counter <= 0;
                buzzer_out  <= '0';
            end if;
        end if;
    end process pwm_gen_proc;

end architecture rtl;