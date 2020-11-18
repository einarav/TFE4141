library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;


entity exponentiation_tb is
	generic (
		C_block_size : integer := 256
	);
end exponentiation_tb;


architecture expBehave of exponentiation_tb is
    
    --DUT ports
    --valid_in    : std_logic;
    --ready_out   : std_logic;
    --message     : std_logic_vector (C_block_size-1 downto 0);
    --key         : std_logic_vector (C_block_size-1 downto 0);
            
    --Clock
    signal clk 			: STD_LOGIC := '1';
    constant clk_freq   : integer := 100e6; --100MHz
    constant clk_period : time := 1000 ms / clk_freq;
    
    

    --Inputs
    signal valid_in 	: STD_LOGIC;
    signal ready_out 	: STD_LOGIC;  
	signal message 		: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
	signal key 			: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
	
	--Outputs
	signal ready_in 	: STD_LOGIC;
	signal valid_out 	: STD_LOGIC;
	signal result 		: STD_LOGIC_VECTOR(C_block_size-1 downto 0);
	
	--Internal
	signal modulus 		  : STD_LOGIC_VECTOR(C_block_size-1 downto 0);
	signal restart 		  : STD_LOGIC;
	signal reset_n 		  : STD_LOGIC;
    signal working_start, multiply_start, modulus_start : std_logic;

begin
 
    --Device under test (DUT)
	i_exponentiation : entity work.exponentiation
	port map (
		message   => message  ,
		key       => key      ,
		valid_in  => valid_in ,
		ready_in  => ready_in ,
		ready_out => ready_out,
		valid_out => valid_out,
		result    => result   ,
		modulus   => modulus  ,
		clk       => clk      ,
		reset_n   => reset_n
	);
		
	--Clock generation
    clk <= not clk after clk_period / 2;

    --Testbench sequence
    process is
    begin
        reset_n <= '0';
        wait for 50 ns;
        reset_n <= '1';
        valid_in <= '1';
        --working_start <= '0';
        wait for 40 ns;
        reset_n <= '0';
        wait for 60 ns;
        modulus(7 downto 0) <= "00110111";
        key(3 downto 0) <= "0111";
        message(7 downto 0) <= "00011011";
        wait for 200 ns;
        finish;
    end process;
end expBehave;
