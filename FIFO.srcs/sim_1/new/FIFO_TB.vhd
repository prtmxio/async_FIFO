library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIFO_TB is
end FIFO_TB;

architecture Behavioral of FIFO_TB is
    
    constant DATA_WIDTH : integer := 8;
    constant FIFO_DEPTH : integer := 8;
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals (all initialized)
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal wr_en       : std_logic := '0';
    signal wr_data     : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal rd_en       : std_logic := '0';
    signal rd_data     : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal full        : std_logic := '0';
    signal empty       : std_logic := '1';
    
    -- Helper function to convert std_logic_vector to hex string
    function to_hex(vec : std_logic_vector) return string is
        constant hex_chars : string := "0123456789ABCDEF";
        variable result : string(1 to 2);
        variable upper_nibble : integer;
        variable lower_nibble : integer;
    begin
        upper_nibble := to_integer(unsigned(vec(7 downto 4)));
        lower_nibble := to_integer(unsigned(vec(3 downto 0)));
        result(1) := hex_chars(upper_nibble + 1);
        result(2) := hex_chars(lower_nibble + 1);
        return result;
    end function;
    
begin
    
    -- Instantiate FIFO
    UUT: entity work.FIFO
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            FIFO_DEPTH => FIFO_DEPTH
        )
        port map (
            clk          => clk,
            rst          => rst,
            wr_en        => wr_en,
            wr_data      => wr_data,
            rd_en        => rd_en,
            rd_data      => rd_data,
            full         => full,
            empty        => empty
        );
    
    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Main test - Easy to follow!
    test_process: process
    begin
        -- STEP 1: Reset
        report "========== RESET ==========";
        rst <= '1';
        wait for CLK_PERIOD*3;
        rst <= '0';
        wait for CLK_PERIOD*2;
        
        -- STEP 2: Write 5 values (0x10, 0x20, 0x30, 0x40, 0x50)
        report "========== WRITING 5 VALUES ==========";
        
        wr_en <= '1';
        wr_data <= X"10";
        report "Writing: 0x10";
        wait for CLK_PERIOD;
        
        wr_data <= X"20";
        report "Writing: 0x20";
        wait for CLK_PERIOD;
        
        wr_data <= X"30";
        report "Writing: 0x30";
        wait for CLK_PERIOD;
        
        wr_data <= X"40";
        report "Writing: 0x40";
        wait for CLK_PERIOD;
        
        wr_data <= X"50";
        report "Writing: 0x50";
        wait for CLK_PERIOD;
        
        wr_en <= '0';
        wait for CLK_PERIOD*3;
        
        -- STEP 3: Read 3 values
        report "========== READING 3 VALUES ==========";
        
        rd_en <= '1';
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0x10)";
        
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0x20)";
        
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0x30)";
        
        rd_en <= '0';
        wait for CLK_PERIOD*3;
        
        -- STEP 4: Write 3 more values
        report "========== WRITING 3 MORE VALUES ==========";
        
        wr_en <= '1';
        wr_data <= X"60";
        report "Writing: 0x60";
        wait for CLK_PERIOD;
        
        wr_data <= X"70";
        report "Writing: 0x70";
        wait for CLK_PERIOD;
        
        wr_data <= X"80";
        report "Writing: 0x80";
        wait for CLK_PERIOD;
        
        wr_en <= '0';
        wait for CLK_PERIOD*3;
        
        -- STEP 5: Read all remaining (should be 0x40, 0x50, 0x60, 0x70, 0x80)
        report "========== READING ALL REMAINING ==========";
        
        rd_en <= '1';
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0x40)";
        
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0x50)";
        
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0x60)";
        
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0x70)";
        
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0x80)";
        
        rd_en <= '0';
        wait for CLK_PERIOD*3;
        
        -- STEP 6: Fill completely (8 writes)
        report "========== FILLING FIFO COMPLETELY ==========";
        
        wr_en <= '1';
        for i in 0 to 7 loop
            wr_data <= std_logic_vector(to_unsigned(i+100, 8));
            report "Writing: " & integer'image(i+100);
            wait for CLK_PERIOD;
        end loop;
        wr_en <= '0';
        wait for CLK_PERIOD*3;
        
        -- STEP 7: Try writing when full (should be blocked)
        report "========== TRYING TO WRITE WHEN FULL ==========";
        wr_en <= '1';
        wr_data <= X"FF";
        report "Attempting write (should be blocked!)";
        wait for CLK_PERIOD*2;
        wr_en <= '0';
        wait for CLK_PERIOD*3;
        
        -- STEP 8: Empty completely
        report "========== EMPTYING FIFO ==========";
        rd_en <= '1';
        for i in 0 to 7 loop
            wait for CLK_PERIOD;
            report "Read: 0x" & to_hex(rd_data);
        end loop;
        rd_en <= '0';
        wait for CLK_PERIOD*3;
        
        -- STEP 9: Simultaneous read/write
        report "========== SIMULTANEOUS READ AND WRITE ==========";
        
        -- First put one item
        wr_en <= '1';
        wr_data <= X"AA";
        wait for CLK_PERIOD;
        wr_en <= '0';
        wait for CLK_PERIOD*2;
        
        -- Now read and write at same time
        wr_en <= '1';
        rd_en <= '1';
        wr_data <= X"BB";
        report "Simultaneous: Writing 0xBB, Reading...";
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0xAA)";
        
        wr_data <= X"CC";
        report "Simultaneous: Writing 0xCC, Reading...";
        wait for CLK_PERIOD;
        report "Read: 0x" & to_hex(rd_data) & " (should be 0xBB)";
        
        wr_en <= '0';
        rd_en <= '0';
        wait for CLK_PERIOD*3;
        
        report "========================================";
        report "========== TEST COMPLETE! ==========";
        report "========================================";
        wait;
    end process;
    
    -- Process to display FIFO state every clock cycle
    monitor_process: process(clk)
    begin
        if rising_edge(clk) then
            if wr_en = '1' and full = '0' then
                report ">>> WRITE detected | Data=0x" & to_hex(wr_data);
            end if;
            if rd_en = '1' and empty = '0' then
                report "<<< READ detected  | Data=0x" & to_hex(rd_data);
            end if;
        end if;
    end process;
    
end Behavioral;