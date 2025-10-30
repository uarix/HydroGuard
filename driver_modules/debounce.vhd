-- =================================================================================
-- Entity: debounce
-- Description: A generic button debouncer module.
--              It takes a noisy button input and generates a clean, single-cycle
--              strobe pulse when a stable press is detected.
-- Generic:
--   - DEBOUNCE_TIME_MS: Debounce period in milliseconds.
-- =================================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
    generic (
        CLK_FREQUENCY    : natural := 1_000_000; -- System clock frequency in Hz
        DEBOUNCE_TIME_MS : natural := 20         -- Debounce time in milliseconds
    );
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        btn_in        : in  std_logic; -- Noisy button input (active low)
        btn_pulse_out : out std_logic  -- Clean single-cycle pulse output (active high)
    );
end entity debounce;

architecture rtl of debounce is
    -- Calculate the required counter value for the debounce time
    constant COUNTER_MAX : natural := (CLK_FREQUENCY / 1000) * DEBOUNCE_TIME_MS;

    -- Internal signals for FSM and counter
    type T_STATE is (IDLE, WAIT_STABLE, WAIT_RELEASE);
    signal state   : T_STATE;
    signal counter : natural range 0 to COUNTER_MAX;

    -- Flipped button input to work with active high logic internally
    signal btn_sync : std_logic;
    signal ff1 : std_logic;

begin
    -- Simple 2-stage synchronizer for the async button input
    ff_sync : process(clk, reset)
        
    begin
        if reset = '1' then
            ff1      <= '1';
            btn_sync <= '1';
        elsif rising_edge(clk) then
            ff1      <= btn_in;
            btn_sync <= ff1;
        end if;
    end process ff_sync;

    -- Debouncer FSM
    debounce_proc : process(clk, reset)
    begin
        if reset = '1' then
            state         <= IDLE;
            counter       <= 0;
            btn_pulse_out <= '0';
        elsif rising_edge(clk) then
            btn_pulse_out <= '0'; -- Pulse is only high for one cycle

            case state is
                when IDLE =>
                    -- Wait for a button press (active low, so check for '0')
                    if btn_sync = '0' then
                        state   <= WAIT_STABLE;
                        counter <= 0;
                    end if;

                when WAIT_STABLE =>
                    if btn_sync = '1' then -- Bounced back?
                        state <= IDLE; -- Reset FSM
                    elsif counter = COUNTER_MAX - 1 then
                        state         <= WAIT_RELEASE;
                        btn_pulse_out <= '1'; -- Output the clean pulse
                    else
                        counter <= counter + 1;
                    end if;

                when WAIT_RELEASE =>
                    -- Wait for the button to be released
                    if btn_sync = '1' then
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process debounce_proc;

end architecture rtl;