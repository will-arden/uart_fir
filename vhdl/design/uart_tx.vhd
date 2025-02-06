-- Import libraries
library ieee;
use ieee.std_logic_1164.all;

-- Declare entity
entity uart_tx is
    generic(
        N : positive := 8       -- UART packet length
    );
    port(
        rst, clk    : in    std_logic;
        input       : in    std_logic_vector(7 downto 0);
        tx          : out   std_logic
    );
end entity;

-- Define the architecture
architecture behav of uart_tx is

    signal input_reg : std_logic_vector(N-1 downto 0);
    signal counter : integer;

begin

    sync_proc : process(rst, clk, input) is
    begin
        if(rst = '1') then
            input_reg <= (others=>'0');
            counter <= 0;
        elsif(rising_edge(clk)) then
        
            -- Control counter
            if(counter = N-1) then  counter <= 0;
            else                    counter <= counter + 1;
            end if;
            
            -- Copy input to the internal register
            if(counter = 7) then    input_reg <= input;
            end if;
            
            -- Transmit serial data
            tx <= input_reg(counter);
            
        end if;
    end process;

end behav;


