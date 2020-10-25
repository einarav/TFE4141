library ieee;
use ieee.std_logic_1164.all;
-- Adding numeric_std.all to allow for * & mod operations
use IEEE.numeric_std.all;


entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input controll
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;

		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		
		-- Vector equal to decimal value 1
		onevector   : in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 ) := (0 => '1', others => '0');

		--ouput controll
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--modulus
		modulus 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
	);
end exponentiation;


architecture expBehave of exponentiation is

-- Integer versions of the vectors
signal int_result : integer;
signal int_message : integer;
signal int_key : integer;
-- Will the integer size work????

begin
    process
    
    begin -- Checking key binary value
        if (key(C_block_size-1) = '1') then
            result <= message;
        else   
            result <= onevector;        
        end if;
        
        -- Converting values
        int_result <= to_integer(unsigned(result));
        int_message <= to_integer(unsigned(message));
        int_key <= to_integer(unsigned(key));
         
        for element in C_block_size-2 downto 0 loop
            -- Can do int_result^2 using multiplication when Montgomery is implemented
            int_result <= (int_result**2) mod int_key;
            
            if (key(element) = '1') then
                -- Need to add different method for multiplication
                int_result <= (int_result*int_message) mod int_key;
            end if;
        end loop;
         
        result <= std_logic_vector(to_unsigned(int_result, C_block_size-1));
	
	ready_in <= ready_out;
	valid_out <= valid_in;
	wait for 1 us; -- Wait statement? Is it needed??
    end process;
end expBehave;
