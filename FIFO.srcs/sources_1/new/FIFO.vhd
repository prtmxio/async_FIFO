library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIFO is
    Generic (
        DATA_WIDTH : integer := 8;      -- Bits per word
        FIFO_DEPTH : integer := 8       -- Number of locations
    );
    Port (
        clk         : in  std_logic;    
        rst         : in  std_logic;    -- async reset
        
        -- Write interface
        wr_en       : in  std_logic;    -- write enable
        wr_data     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Read interface  
        rd_en       : in  std_logic;    -- read enable
        rd_data     : out std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Status flags
        full        : out std_logic;    -- full FIFO
        empty       : out std_logic    -- empty FIFO
    );
end FIFO;

architecture Behavioral of FIFO is
    
    -- mem_array : 8 locs, each 8-bits wide
    type memory_type is array (0 to FIFO_DEPTH-1) of 
         std_logic_vector(DATA_WIDTH-1 downto 0);
    signal memory : memory_type := (others => (others => '0'));
    
    -- ptrs : need 3 bits to addr 8 locs (0 to 7)
    signal wr_ptr : integer range 0 to FIFO_DEPTH-1 := 0;
    signal rd_ptr : integer range 0 to FIFO_DEPTH-1 := 0;
    
    -- counters : tracks number of elements (0 to 8)
    signal count : integer range 0 to FIFO_DEPTH := 0;
    
    -- internal status signals
    signal full_i  : std_logic := '0';
    signal empty_i : std_logic := '1';
    
    
begin
    
    -- init status flags based on count
    full_i  <= '1' when count = FIFO_DEPTH else '0';
    empty_i <= '1' when count = 0 else '0';
    
    -- o/p status flags
    full  <= full_i;
    empty <= empty_i;
    
    
    my_FIFO : process(clk, rst)
    begin
        if rst = '1' then
            -- init all
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            rd_data <= (others => '0');
            
        elsif rising_edge(clk) then
            
            -- will write here
            if wr_en = '1' and full_i = '0' then
                memory(wr_ptr) <= wr_data; -- write data
                
                -- loop back
                if wr_ptr = FIFO_DEPTH-1 then
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
                end if;
                
                -- if not reading simultaneously, increment count
                if rd_en = '0' or empty_i = '1' then
                    count <= count + 1;
                end if;
            end if;
            
            -- will read here
            if rd_en = '1' and empty_i = '0' then
                rd_data <= memory(rd_ptr); -- read data
                
                -- loop back
                if rd_ptr = FIFO_DEPTH-1 then
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;
                end if;
                
                -- if not writing simultaneously, decrement count
                if wr_en = '0' or full_i = '1' then
                    count <= count - 1;
                end if;
            end if;
            
        end if;
    end process;
    
end Behavioral;