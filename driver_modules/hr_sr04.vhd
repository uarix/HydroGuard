-- ultrasonic_driver
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ultrasonic_driver is
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        measure_i    : in  std_logic;
        ready_o      : out std_logic;
        data_valid_o : out std_logic;
        trig_o       : out std_logic;
        echo_i       : in  std_logic;
        distance_o   : out std_logic_vector(9 downto 0)
    );
end entity ultrasonic_driver;

architecture behavioral of ultrasonic_driver is
    type t_state is (S_IDLE, S_TRIGGER, S_WAIT_ECHO_RISE, S_COUNT_ECHO);
    signal state_reg : t_state;

    signal trig_counter_reg  : unsigned(5 downto 0);
    signal echo_counter_reg  : unsigned(15 downto 0);
    signal distance_reg      : unsigned(9 downto 0);
    signal data_valid_reg    : std_logic;
    
    constant C_MIN_ECHO_COUNT    : unsigned(15 downto 0) := to_unsigned(100, 16); -- 对应1.7cm
    constant C_MAX_ECHO_COUNT    : unsigned(15 downto 0) := to_unsigned(5800, 16); --对应100cm
    constant C_TRIG_PULSE_CYCLES : unsigned(5 downto 0) := to_unsigned(40, 6);


begin

    trig_o <= '1' when state_reg = S_TRIGGER else '0';
    ready_o <= '1' when state_reg = S_IDLE else '0';
    data_valid_o <= data_valid_reg;
    distance_o <= std_logic_vector(distance_reg);

    -- Main Sequential Process
    process(clk_i, reset_i)
        -- Calculation variables. Total width needed is 16 (input) + 5 (shift) + 1 (adder carry) = 22 bits
        variable sum_var : unsigned(21 downto 0);
    begin
        if reset_i = '1' then
            state_reg         <= S_IDLE;
            trig_counter_reg  <= (others => '0');
            echo_counter_reg  <= (others => '0');
            distance_reg      <= (others => '0');
            data_valid_reg    <= '0';
        elsif rising_edge(clk_i) then
            data_valid_reg <= '0';

            case state_reg is
                when S_IDLE =>
                    if measure_i = '1' then
                        state_reg <= S_TRIGGER;
                    end if;

                when S_TRIGGER =>
                    if trig_counter_reg >= C_TRIG_PULSE_CYCLES then
                        state_reg        <= S_WAIT_ECHO_RISE;
                        trig_counter_reg <= (others => '0');
                    else
                        trig_counter_reg <= trig_counter_reg + 1;
                    end if;

                when S_WAIT_ECHO_RISE =>
                    echo_counter_reg <= (others => '0');
                    if echo_i = '1' then
                        state_reg <= S_COUNT_ECHO;
                    end if;

                when S_COUNT_ECHO =>
                    if echo_i = '0' then -- On falling edge of echo...
                        if (echo_counter_reg > C_MIN_ECHO_COUNT) and (echo_counter_reg < C_MAX_ECHO_COUNT) then
                            -- D_mm = ( (echo_counter_reg << 5) + (echo_counter_reg << 4) ) >> 10
                            sum_var := shift_left(resize(echo_counter_reg, sum_var'length), 5) + 
                                       shift_left(resize(echo_counter_reg, sum_var'length), 4);
                            distance_reg   <= resize(shift_right(sum_var, 10), distance_reg'length);
                            data_valid_reg <= '1';
                        end if;
                        
                        state_reg <= S_IDLE;
                    else
                        -- Continue counting
                        echo_counter_reg <= echo_counter_reg + 1;
                    end if;
            end case;
        end if;
    end process;

end architecture behavioral;