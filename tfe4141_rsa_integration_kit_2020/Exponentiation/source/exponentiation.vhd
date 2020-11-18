library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
    type state is (IDLE, FINISHED, MULTIPLY, SQUARING, MODULO);
    signal current_state : state := IDLE;
    signal next_state : state := IDLE;
    
    signal counter, multiply_counter, squaring_counter : integer range 0 to 256;
    
    signal result_tmp : std_logic_vector (C_block_size-1 downto 0) := result;
    signal message_tmp : std_logic_vector (C_block_size-1 downto 0) := message;
    signal key_e_d_tmp : std_logic_vector (C_block_size-1 downto 0) := key;
    signal modulus_n : std_logic_vector (C_block_size-1 downto 0) := modulus;
    
    signal working_start, multiply_start, modulus_start : std_logic := '0';
    signal multiply_R : std_logic_vector (C_block_size - 1 downto 0);
    
begin
    
    process (next_state, current_state,
    counter, multiply_counter, squaring_counter, result_tmp, message_tmp, key_e_d_tmp, modulus_n,
    working_start, multiply_start, modulus_start, multiply_R, clk)
    begin
        case current_state is
        
            when IDLE => -- Check if we are ready to start
            -- Telling rsa_msgin that ready for msgin_data
            ready_in <= '0';
            valid_out <= '0';
            
            counter <= C_block_size - 2;
            multiply_counter <= 0;
            squaring_counter <= 0;
            working_start <= '0';
            multiply_R <= (others => '0');
            next_state <= SQUARING;
            
            
        
            when SQUARING =>
            -- Removed the ERROR part. Might cause program not to
            -- run with arrays containing U (emptiness)
                if (working_start = '0') then
                    result_tmp <= message_tmp;
                    working_start <= '1';
                end if;
                --elsif (key_e_d_tmp(C_block_size - 1) = '0') then
                    -- ERROR with key_e_d value
                    -- result_tmp = 0;
                    -- Send back to IDLE?
                --end if;
                
                if (counter > 0) then
                    -- Performing C = C^2 = C*C
                    if (squaring_counter < C_block_size - 1) then
                        multiply_R <= multiply_R sll 1;
                        
                        if (result_tmp(squaring_counter) = '1') then
                            multiply_R <= std_logic_vector(unsigned(multiply_R) + unsigned(result_tmp));
                        end if;
                        
                        squaring_counter <= squaring_counter + 1;
                    end if;
                    
                    if (squaring_counter = C_block_size - 1) then
                        result_tmp <= multiply_R;
                        multiply_R <= (others => '0');
                        squaring_counter <= 0;
                        
                        if (key_e_d_tmp(counter) = '1') then
                            next_state <= MULTIPLY;
                        else
                            next_state <= MODULO;
                        end if;
                    end if;
                end if;
                
                
            
            when MULTIPLY =>
                if (multiply_counter < C_block_size - 1) then
                    multiply_R <= multiply_R sll 1;
                    
                    if (result_tmp(multiply_counter) = '1') then
                        multiply_R <= std_logic_vector(unsigned(multiply_R) + unsigned(message_tmp));
                    end if;
                    
                    multiply_counter <= multiply_counter + 1;
                end if;
                
                if (multiply_counter = C_block_size - 1) then
                    result_tmp <= multiply_R;
                    multiply_R <= (others => '0');
                    multiply_counter <= 0;
                    next_state <= MODULO;              
                end if;
                
                
            
            when MODULO =>
                if (result_tmp > modulus_n) then
                    result_tmp <= std_logic_vector(unsigned(result_tmp) - unsigned(modulus_n));
                    modulus_start <= '1';
                    
                    if (result_tmp < modulus_n) then
                        modulus_start <= '0';
                    end if;
                end if;
                
                if (counter > 0) and (modulus_start = '0') then
                    counter <= counter - 1;
                    next_state <= SQUARING;
                elsif (counter < 1) and (modulus_start = '0') then
                    next_state <= FINISHED;
                end if;
                
                
            when FINISHED => -- Output the signal and confirm that is finished
            result <= result_tmp;
            ready_in <= '1';
            valid_out <= '1';
            next_state <= IDLE;
            
            
        end case;
    end process;
    
    -- Control process -- 
    process (clk, reset_n)
    begin
        if (reset_n = '0') then
            current_state <= IDLE;
            
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
	
end expBehave;
