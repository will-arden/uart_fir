-- Import libraries
library ieee;
use ieee.std_logic_1164.all;

-- Declare an empty testbench entity
entity tb_uart_rx is
end entity;

-- Define architecture
architecture tb of tb_uart_rx is

    -- Declare the test signals
    signal rst_in, clk_in, rx_in, read_out  : std_logic := '0';
    signal data_reg_out           : std_logic_vector(7 downto 0) := "00000000";
    
    -- Declare the DUT
    component uart_rx is
        port(
            rst, clk, rx    : in    std_logic;
            data_reg        : out   std_logic_vector(7 downto 0);
            read            : out   std_logic
        );
    end component;

begin

    -- Instantiate the DUT
    DUT : uart_rx port map (
        rst         => rst_in,
        clk         => clk_in,
        rx          => rx_in,
        data_reg    => data_reg_out,
        read        => read_out
    );
    
    -- Generate clock
    clk_gen : process is
    begin
        clk_in <= not clk_in;   wait for 20ns;
    end process;
    
    -- Simulation
    sim : process is
    begin
        -- Reset toggle
        rst_in <= '1';
        rx_in <= '1';
        wait for 50ns;
        rst_in <= '0';
        wait for 60ns;
        
        -- Start message
        rx_in <= '0';
        wait for 20ns;
        
        -- Write the sequence "O": "01001111"
        rx_in <= '1';
        wait for 40ns;
        rx_in <= '1';
        wait for 40ns;
        rx_in <= '1';
        wait for 40ns;
        rx_in <= '1';
        wait for 40ns;
        rx_in <= '0';
        wait for 40ns;
        rx_in <= '0';
        wait for 40ns;
        rx_in <= '1';
        wait for 40ns;
        rx_in <= '0';
        wait for 40ns;
        
        -- Terminate message
        rx_in <= '1';
        wait for 40ns;
        
        wait;
    end process;
    


end tb;