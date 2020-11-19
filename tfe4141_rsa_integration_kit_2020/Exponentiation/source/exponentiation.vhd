library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

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
    
    signal result_tmp : std_logic_vector (C_block_size-1 downto 0);
    signal message_tmp : std_logic_vector (C_block_size-1 downto 0);
    signal key_e_d_tmp : std_logic_vector (C_block_size-1 downto 0);
    signal modulus_n : std_logic_vector (C_block_size-1 downto 0);
    
    signal working_start, multiply_start, modulus_start : std_logic := '0';
    signal multiply_R : std_logic_vector (C_block_size - 1 downto 0);
    signal ready_in_tmp, message_in_ready, message_out_ready : std_logic;
    
    signal counter_size : integer range 0 to 255;
    signal msb_bit : integer range 0 to 255;
    
begin
    
    process (clk, reset_n)
    begin
        if reset_n = '0' then
            result_tmp <= message;
        end if;
        
        if rising_edge(clk) then
        case current_state is
        
            when IDLE => -- Check if we are ready to start
            -- Telling rsa_msgin that ready for msgin_data
            ready_in <= '1';
            valid_out <= '0';
            
            key_e_d_tmp <= key;
            modulus_n <= modulus;
            
            message_in_ready <= ready_in and valid_in;
            if (message_in_ready = '1') then
                message_tmp <= message;
                next_state <= SQUARING;
            end if;
            
            -- Values used for multiplying and squaring
            --counter <= C_block_size - 2;
            counter_size <= 5;
            counter <= counter_size - 2;
            
            
            multiply_counter <= 0;
            squaring_counter <= 0;
            working_start <= '0';
            multiply_R <= (others => '0');
            
            -- Once finished, we move to squaring
            
            
            
        
            when SQUARING =>
                if (working_start = '0') then
                    result_tmp <= message_tmp;
                    working_start <= '1';
                end if;
                
                if (counter > 0) and (working_start = '1') then
                    -- Performing C = C^2 = C*C
                    
                    -- C_block_size === number of bits in key
                    for i in 0 to (C_block_size-1) loop
                        if (result_tmp(i) = '1') then
                            msb_bit <= i;
                        end if;
                    end loop;
                    
                    if (squaring_counter < msb_bit) then
                        multiply_R <= multiply_R sll 1;
                        
                        if (result_tmp(squaring_counter) = '1') then
                            multiply_R <= std_logic_vector(unsigned(multiply_R) + unsigned(result_tmp));
                        end if;
                        
                        squaring_counter <= squaring_counter + 1;
                    end if;
                    
                    if (squaring_counter = msb_bit) then
                        result_tmp <= multiply_R;
                        multiply_R <= (others => '0');
                        squaring_counter <= 0;
                        
                    end if;
                end if;
                if (key_e_d_tmp(counter) = '1') then
                    next_state <= MULTIPLY;
                    --squaring_counter <= 0;
                else
                    next_state <= MODULO;
                    --squaring_counter <= 0;
                end if;
                
                
                
            
            when MULTIPLY =>
                for i in 0 to (C_block_size-1) loop
                        if (result_tmp(i) = '1') then
                            msb_bit <= i;
                        end if;
                end loop;
                
                if (multiply_counter < msb_bit) then
                    multiply_R <= multiply_R sll 1;
                    
                    if (result_tmp(multiply_counter) = '1') then
                        multiply_R <= std_logic_vector(unsigned(multiply_R) + unsigned(message_tmp));
                    end if;
                    
                    multiply_counter <= multiply_counter + 1;
                end if;
                
                if (multiply_counter = msb_bit) then
                    result_tmp <= multiply_R;
                    multiply_R <= (others => '0');
                    multiply_counter <= 0;
                    next_state <= MODULO;              
                end if;
                
                
            
            when MODULO =>
                if (result_tmp > modulus_n) then
                    --result_tmp <= std_logic_vector(unsigned(result_tmp) - unsigned(modulus_n));
                    result_tmp <= result_tmp(255 downto 0) - modulus_n(255 downto 0);
                    modulus_start <= '1';
                    
                    if (result_tmp < modulus_n) then
                        modulus_start <= '0';
                    end if;
                end if;
                if(modulus_start = '0') then
                    if (counter > 0) then --and (modulus_start = '0') then
                        counter <= counter - 1;
                        next_state <= SQUARING;
                    elsif (counter < 1) then --and (modulus_start = '0') then
                        next_state <= FINISHED;
                        working_start <= '0';
                    end if;
                end if;
                
            when FINISHED => -- Output the signal and confirm that is finished
            result <= result_tmp;
            valid_out <= '1';
            ready_in <= '0';
            
            message_out_ready <= valid_out and ready_out;
            if (message_out_ready = '1') then
                next_state <= IDLE;
            end if;
            
            
            
        end case;
        end if;
    end process;
    
    -- Control process -- 
    process (clk, reset_n)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                current_state <= IDLE;
                
            else
                current_state <= next_state;
            end if;
        end if;
    end process;
	
end expBehave;
