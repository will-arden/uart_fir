-- Import libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare an empty testbench entity
entity tb_uart_tx is
end entity;

-- Define architecture
architecture tb of tb_uart_tx is

    -- Define constants
    constant BITS : positive := 8;

    -- Declare test signals
    signal rst_in, clk_in   : std_logic;
    signal input_in         : std_logic_vector(BITS-1 downto 0);
    signal tx_out           : std_logic;
    
    -- Declare component
    component uart_tx is
        generic(
            N : positive := 8       -- UART packet length
        );
        port(
            rst, clk    : in    std_logic;
            input       : in    std_logic_vector(7 downto 0);
            tx          : out   std_logic
        );
    end component;
    

begin

    -- Instantiate DUT
    DUT : uart_tx
        generic map(
            N => BITS
        )
        port map(
            rst     => rst_in,
            clk     => clk_in,
            input   => input_in,
            tx      => tx_out
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
        wait for 40ns;
        rst_in <= '0';
        wait for 50ns;
        
        -- Input something
        input_in <= x"AA";
        wait for 320ns;
        input_in <= x"00";
        wait for 40ns;
        
    
    wait;
    end process;

end tb;

