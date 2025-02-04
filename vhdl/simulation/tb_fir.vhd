-- Import libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare an empty testbench entity
entity tb_fir is
end entity;

-- Define the architecture
architecture tb of tb_fir is

    constant BITS : positive := 32;
    constant ORDER : positive := 64;

    -- Declare test signals
    signal rst_in, clk_in, ctrl_en_in : std_logic;
    signal ctrl_data_in, input_in, output_out : std_logic_vector(BITS-1 downto 0);

    -- Declare the DUT
    component fir is
        generic(
            N   : positive := 32;       -- Configurable word length (bits)
            FO : positive := 64         -- Configurable filter order
        );
        port (
            rst, clk    : in    std_logic;
            ctrl_en     : in    std_logic;
            ctrl_data   : in    std_logic_vector(N-1 downto 0);
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
            ctrl_en     => ctrl_en_in,
            ctrl_data   => ctrl_data_in,
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
    begin
        
        -- Toggle reset
        rst_in <= '1';
        ctrl_en_in <= '0';
        input_in <= x"00000000";
        wait for 50ns;
        rst_in <= '0';
        wait for 20ns;
        
        -- Arrange a window
        ctrl_data_in <= x"0000000A";
        ctrl_en_in <= '1';
        wait for 40ns;
        ctrl_data_in <= x"000000C8";
        wait for 40ns;
        ctrl_data_in <= x"0000012C";
        wait for 40ns;
        ctrl_en_in <= '0';
        wait for 40ns;
        
        -- Put in some kind of input
        input_in <= x"000001A4";
        wait for 40ns;
        input_in <= x"000000D4";
        
        wait for 100ns;
        input_in <= x"00000000";
        
        wait;
    end process;

end tb;




