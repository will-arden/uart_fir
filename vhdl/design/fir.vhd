-- Import libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Declare entity
entity fir is
    generic(
        N   : positive := 32;       -- Configurable word length (bits)
        FO  : positive := 64        -- Configurable filter order
    );
    port (
        rst, clk    : in    std_logic;
        input       : in    std_logic_vector(N-1 downto 0);
        output      : out   std_logic_vector(N-1 downto 0)
    );
end fir;

architecture behav of fir is

    -- Define the order of the filter
    constant filter_order       : positive := FO;
    constant filter_order_bits  : positive := integer(log2(real(filter_order)));

    -- Allow for arrays of std_logic_vector elements
    type t_buffer is array (0 to filter_order-1) of std_logic_vector(N-1 downto 0);
    
    -- State types
    type t_state is (IDLE, BUF_READ, WINDOW_READ);
    
    -- Declare internal signals
    signal buf          : t_buffer;
    signal window       : t_buffer;
    signal state        : t_state;
    
    -- Function to zero-initialise a t_buffer signal/variable
    function zero_init(
        buf_in : t_buffer
    ) return t_buffer is
        variable buf_out : t_buffer;
        variable zero : std_logic_vector(N-1 downto 0);
    begin
        zero := (others=>'0');
        for i in 0 to filter_order - 1 loop
            buf_out(i) := zero;
        end loop;
        return buf_out;
    end function;
    
    -- Function to shift the buffer contents right, leaving zeroes at the zeroth element
    function shift_buffer(
        buf_in : t_buffer
    ) return t_buffer is
        variable buf_out : t_buffer;
        variable zero : std_logic_vector(N-1 downto 0);
    begin
        zero := (others=>'0');
        for i in 0 to filter_order - 2 loop
            buf_out(i+1) := buf_in(i);
        end loop;
        buf_out(0) := zero;
        return buf_out;
    end function;
    
begin

    -- State excitation
    state_proc : process(clk, input, state) is
    begin
        if(rst = '1') then      state <= IDLE;
        elsif(rising_edge(clk)) then
        
            case state is
                when IDLE =>                                                        -- IDLE
                    if(input(7 downto 0) = x"AA") then      state <= BUF_READ;          -- Excite to BUF_READ
                    elsif(input(7 downto 0) = x"BB") then   state <= WINDOW_READ;       -- Excite to WINDOW_READ
                    end if;
                when BUF_READ =>                                                    -- BUF_READ
                    state <= IDLE;                                                      -- Return to IDLE
                when WINDOW_READ =>                                                 -- WINDOW_READ
                    state <= IDLE;                                                      -- Return to IDLE
                when others =>                                                      -- Default case (invalid)
                    state <= IDLE;                                                      -- Return to IDLE
            end case;
        
        end if;
    end process;

    -- Act on UART command
    action_proc : process(rst, clk, input, state) is
    begin
        if(rst = '1') then                              -- Upon reset
            buf     <= zero_init(buf);                      -- Empty the input buffer
            window  <= zero_init(window);                   -- Empty the window
        elsif(rising_edge(clk)) then
            if(state = BUF_READ) then                   -- BUF_READ state
                buf     <= shift_buffer(buf);               -- Shift the buffer along
                buf(0)  <= input;                           -- Insert the current input
            elsif(state = WINDOW_READ) then             -- WINDOW_READ state
                window      <= shift_buffer(window);        -- Shift the coefficients along
                window(0)   <= input;                       -- Insert the new coefficient
            end if;
        end if;
    end process;
    
    
    
    -- Compute the output
    conv_proc : process(rst, clk) is
        variable sum, product, tempA, tempB : integer := 0;
    begin
        if(rst = '1') then
            output <= (others=>'0');
        elsif(rising_edge(clk)) then
            sum := 0;
            for i in 0 to filter_order-1 loop
                tempA   := to_integer(unsigned(buf(i)));        -- Buffer value as an integer
                tempB   := to_integer(unsigned(window(i)));     -- Window value as an integer
                product := tempA * tempB;                       -- Element-wise multiplication
                sum     := sum + product;                       -- Sum of products
            end loop;
            output <= std_logic_vector(to_unsigned(sum, output'length));
        end if;
    end process;

end behav;
