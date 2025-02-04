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
        ctrl_en     : in    std_logic;
        ctrl_data   : in    std_logic_vector(N-1 downto 0);
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
    state_proc : process(rst, buf, state) is
    begin
        if(rst = '1') then      state <= IDLE;                      -- Reset state
        elsif(state = IDLE and buf(0)(7 downto 0) = x"AA") then     -- Detect command
            state <= BUF_READ;                                          -- Read to buffer
        elsif(state = IDLE and buf(0)(7 downto 0) = x"BB") then     -- Detect command
            state <= WINDOW_READ;                                       -- Read to window
        elsif(state = BUF_READ) then
        end if;
    end process;

    -- Allow the window buffer to be written to
    ctrl_proc : process(rst, clk) is
    begin
        if(rst = '1') then          window <= zero_init(window);        -- Clear window on reset
        elsif(rising_edge(clk) and ctrl_en = '1') then
            window      <= shift_buffer(window);
            window(0)   <= ctrl_data;
        end if;
    end process;
    

    -- FIFO buffer storing recent inputs
    buf_proc : process(rst, clk) is
    begin
        if(rst = '1') then
            buf <= zero_init(buf);
        elsif(rising_edge(clk)) then
            buf     <= shift_buffer(buf);
            buf(0)  <= input;
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