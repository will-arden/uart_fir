-- Import libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Declare entity
entity uart_rx is
    generic (
        N : positive := 8       -- Configurable UART packet length (bits)
    );
    port(
        rst, clk, rx    : in    std_logic;
        data_reg        : out   std_logic_vector(N-1 downto 0);
        read            : out   std_logic
    );
end uart_rx;

-- Define architecture
architecture behav of uart_rx is
    constant counter_length : positive := integer(ceil(log2(real(N))));

    signal buf      : std_logic_vector(N-1 downto 0);                   -- FIFO buffer
    signal count    : std_logic_vector(counter_length-1 downto 0);      -- Counter for correct message length
    signal c_en     : std_logic;                                        -- Count enable
    signal flag     : std_logic;                                        -- Flag for message completion
    
    -- Define a useful function
    function ones_count(
        input : std_logic_vector(integer(ceil(log2(real(N))))-1 downto 0) := (others=>'0')
    ) return integer is
        variable total : integer := 0;
    begin
        for i in 0 to integer(ceil(log2(real(N))))-1 loop
            if(input(i) = '1') then
                total := total + 1;
            end if;
        end loop;
        return total;
    end function;
    
begin

    -- Output register control
    reg_proc : process (clk) is
    begin
        if(rst = '1') then
            data_reg <= (others=>'0');
        elsif(rising_edge(clk) and flag = '1') then
            data_reg <= buf;
        end if;
    end process;

    -- Buffer control process
    buf_proc : process(rst, clk) is
    begin
        if(rst = '1') then      buf <= (others=>'0');
        elsif(rising_edge(clk)) then
            if(c_en = '1') then
                buf <= rx & buf(N-1 downto 1);
            else
                buf <= (others=>'0');
            end if;
        end if;
    end process;
    
    -- Process to determine when count should begin
    c_en_proc : process(rst, clk) is
    begin
        if(rst = '1') then
            c_en <= '0';
        elsif(rising_edge(clk)) then
            if(c_en = '0' and rx = '0') then
                c_en <= '1';
            elsif(ones_count(count) = counter_length) then
                c_en <= '0';
            end if;
        end if;
    end process;
    
    -- Count process
    count_proc : process(rst, clk) is
    begin
        if(rst = '1') then
            count   <= (others=>'0');
            flag    <= '0';
        elsif(rising_edge(clk)) then
        
            -- Count
            if(c_en = '1') then
                count <= std_logic_vector(unsigned(count) + 1);
            else
                count <= (others=>'0');
            end if;
            
            -- When the counter expires, assert flag
            if(ones_count(count) = counter_length) then flag <= '1';
            else                                        flag <= '0';
            end if;
            
        end if;
    end process;
    
    -- Combinational assignments
    read <= flag;
    
end behav;
