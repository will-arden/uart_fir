-- Import libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

-- Declare an empty testbench entity
entity tb_fir is
end entity;

-- Define the architecture
architecture tb of tb_fir is

    constant BITS : positive := 32;
    constant ORDER : positive := 60;

    -- Declare test signals
    signal rst_in, clk_in : std_logic;
    signal input_in, output_out : std_logic_vector(BITS-1 downto 0);

    -- Declare the DUT
    component fir is
        generic(
            N   : positive := 32;       -- Configurable word length (bits)
            FO : positive := 64         -- Configurable filter order
        );
        port (
            rst, clk    : in    std_logic;
            input       : in    std_logic_vector(N-1 downto 0);
            output      : out   std_logic_vector(N-1 downto 0)
        );
    end component;

begin

    -- Instantiate the DUT
    DUT : fir
        generic map (
            N   => BITS,
            FO  => ORDER
        )
        port map (
            rst         => rst_in,
            clk         => clk_in,
            input       => input_in,
            output      => output_out
        );
    
    -- Generate a clock
    clk_gen : process is
    begin
        clk_in <= '1';     wait for 20ns;      clk_in <= '0';     wait for 20ns;
    end process;
    
    -- Simulation
    process is
    
    type window is array (0 to ORDER-1) of std_logic_vector(15 downto 0);
    variable window_vals : window := (
  
    -- 500Hz Blackman LPF
    -- Source: https://vhdlwhiz.com/part-2-finite-impulse-response-fir-filters/
    x"0000", x"0001", x"0005", x"000C", 
    x"0016", x"0025", x"0037", x"004E", 
    x"0069", x"008B", x"00B2", x"00E0", 
    x"0114", x"014E", x"018E", x"01D3", 
    x"021D", x"026A", x"02BA", x"030B", 
    x"035B", x"03AA", x"03F5", x"043B", 
    x"047B", x"04B2", x"04E0", x"0504", 
    x"051C", x"0528", x"0528", x"051C", 
    x"0504", x"04E0", x"04B2", x"047B", 
    x"043B", x"03F5", x"03AA", x"035B", 
    x"030B", x"02BA", x"026A", x"021D", 
    x"01D3", x"018E", x"014E", x"0114", 
    x"00E0", x"00B2", x"008B", x"0069", 
    x"004E", x"0037", x"0025", x"0016", 
    x"000C", x"0005", x"0001", x"0000");
    
    -- Random number declarations
    type inputArray is array (0 to (ORDER-1)*2) of std_logic_vector(BITS-1 downto 0);
    variable randArray : inputArray;
    variable seed1 : positive := 1;
    variable seed2 : positive := 1;
    variable randReal : real;
    variable randInt : integer;
    
    begin
    
        -- Generate random numbers to simulate white noise
        for i in 0 to (ORDER-1)*2 loop
            uniform(seed1, seed2, randReal);                                -- IEEE uniform distribution procedure
            randInt := integer(floor(randReal * 1024.0));                   -- Obtain an integer from the random real value
            randArray(i) := std_logic_vector(to_unsigned(randInt, BITS));   -- Add the random integer to the array of inputs
        end loop;
        
        -- Toggle reset
        rst_in <= '1';
        input_in <= x"00000000";
        wait for 50ns;
        rst_in <= '0';
        wait for 20ns;
        
        -- Load window
        for i in 0 to ORDER-1 loop
            input_in <= x"000000BB";
            wait for 40ns;
            input_in <= x"0000" & window_vals(i);
            wait for 40ns;
        end loop;
        
        wait for 40ns;
        
        -- Provide inputs
        for i in 0 to (ORDER-1)*2 loop
            input_in <= x"000000AA";
            wait for 40ns;
            input_in <= randArray(i);
            wait for 40ns;
        end loop;
        
        -- Continue to the end of time (keep inserting zeros)
        for i in 0 to 1024 loop
            input_in <= x"000000AA";
            wait for 40ns;
            input_in <= x"00000000";
            wait for 40ns;
        end loop;
        
        wait;
    end process;

end tb;




