-- 8-Digit 7-Segment Display Driver
--
-- Drives an 8-digit, common-cathode, 7-segment display.
-- System Clock: 1 MHz
-- Refresh Rate per digit: ~244 Hz (2kHz / 8 digits)
-- Total Refresh Rate for all digits: ~2 kHz
-- This ensures no visible flicker.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_segment_driver is
    port (
        -- System clock (1 MHz)
        clk         : in  std_logic;
        reset       : in  std_logic;

        -- 32-bit input to represent 8 digits of 4-bit BCD values.
        -- disp_data(31 downto 28) -> DISP7 (Most significant digit)
        -- ...
        -- disp_data(3 downto 0)   -> DISP0 (Least significant digit)
        disp_data   : in  std_logic_vector(31 downto 0);

        -- 7-segment outputs (active high)
        -- Corresponds to AA, AB, AC, AD, AE, AF, AG
        segment_out : out std_logic_vector(6 downto 0);

        -- 8-digit common cathode select (active low)
        -- Corresponds to CAT0 to CAT7
        cat_out   : out std_logic_vector(7 downto 0)
    );
end entity seven_segment_driver;

architecture rtl of seven_segment_driver is

    -- The system clock is 1 MHz. To get a ~2kHz refresh clock,
    -- we need to divide by 500.
    -- 1,000,000 Hz / 500 = 2000 Hz (2 kHz)
    constant CLK_DIVIDER_VALUE : integer := 500;

    -- Counter to divide the main clock for display refresh
    signal refresh_counter : integer range 0 to CLK_DIVIDER_VALUE - 1 := 0;

    -- This signal will pulse high for one clock cycle at the refresh rate
    signal refresh_tick : std_logic := '0';

    -- 3-bit counter to select which of the 8 digits is active
    signal digit_selector : unsigned(2 downto 0) := (others => '0');

    -- Holds the 4-bit BCD value for the currently selected digit
    signal current_digit_bcd : std_logic_vector(3 downto 0);

begin

    -- Clock Divider Process
    -- This process generates a single-cycle pulse 'refresh_tick'
    -- at approximately 2 kHz.
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


    -- Digit Scanning and Data Selection Process
    -- This process cycles through the digits one by one on each refresh_tick.
    -- It also selects the corresponding 4-bit BCD data for the active digit.
    digit_scanner_proc : process(clk, reset)
    begin
        if reset = '1' then
            digit_selector <= (others => '0');
        elsif rising_edge(clk) then
            if refresh_tick = '1' then
                -- Cycle through digits 0, 1, 2, 3, 4, 5, 6, 7
                digit_selector <= digit_selector + 1;
            end if;
        end if;
    end process digit_scanner_proc;

    -- Select the BCD data for the currently active digit using a multiplexer.
    -- This is a more efficient way to implement this than in a process with a case statement
    -- for synthesis.
    with to_integer(digit_selector) select
        current_digit_bcd <=
            disp_data(3 downto 0)     when 0,
            disp_data(7 downto 4)     when 1,
            disp_data(11 downto 8)    when 2,
            disp_data(15 downto 12)   when 3,
            disp_data(19 downto 16)   when 4,
            disp_data(23 downto 20)   when 5,
            disp_data(27 downto 24)   when 6,
            disp_data(31 downto 28)   when 7,
            "1111"                    when others; -- Default to off state

    -- BCD to 7-Segment Decoder
    -- This process decodes the 4-bit BCD value into the 7-segment pattern.
    -- segment_out mapping: (g, f, e, d, c, b, a)
    bcd_to_7seg_proc : process(current_digit_bcd)
    begin
        case current_digit_bcd is
            when "0000" => segment_out <= "0111111"; -- 0
            when "0001" => segment_out <= "0000110"; -- 1
            when "0010" => segment_out <= "1011011"; -- 2
            when "0011" => segment_out <= "1001111"; -- 3
            when "0100" => segment_out <= "1100110"; -- 4
            when "0101" => segment_out <= "1101101"; -- 5
            when "0110" => segment_out <= "1111101"; -- 6
            when "0111" => segment_out <= "0000111"; -- 7
            when "1000" => segment_out <= "1111111"; -- 8
            when "1001" => segment_out <= "1101111"; -- 9
            when others => segment_out <= "0000000"; -- Off for any other value (e.g., "1111")
        end case;
    end process bcd_to_7seg_proc;


    -- Anode Output Driver
    -- This process activates the common cathode for the selected digit.
    -- Since it's common cathode, the active level is low.
    anode_driver_proc : process(digit_selector)
        variable anode_temp : std_logic_vector(7 downto 0);
    begin
        anode_temp := (others => '1'); -- Turn off all digits
        anode_temp(to_integer(digit_selector)) := '0'; -- Turn on the selected one
        cat_out <= anode_temp;
    end process anode_driver_proc;

end architecture rtl;
