library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all; 
--use ieee.STD_LOGIC_ARITH.all;

ENTITY alu IS
  PORT( ALUControl			: IN STD_LOGIC_VECTOR( 3 DOWNTO 0);
		  inputA, inputB     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		  shamt					: IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
		  Zero					: OUT STD_LOGIC;
		  ALU_Result			: OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END alu;

ARCHITECTURE arch of alu IS
 SIGNAL Result : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN
	
	PROCESS (ALUControl, inputA, inputB, shamt)
	BEGIN	
	  CASE ALUControl IS
				--and
				--y <= a and b; -- Or 'y <= a xor b;' or 'y <= a or b;', etc
				WHEN "0000" => Result <= inputA and inputB;
				--or
				WHEN "0001" => Result <= inputA or inputB;
				--add
				WHEN "0010" => Result <= inputA + inputB;			
				--subtract
				WHEN "0110" => Result <= inputA - inputB;				
				--set on less than
				WHEN "0111" => 
				 IF(inputA < inputB) THEN
					Result <= X"00000001";
				 ELSE 
					Result <= X"00000000";
				 END IF;
				--shift left logical
				WHEN "1000" => Result <= std_logic_vector(shift_left(unsigned(inputB), to_integer(unsigned(shamt))));				
				--shift left logical vector
				WHEN "1010" => Result <= std_logic_vector(shift_left(unsigned(inputB), to_integer(unsigned(inputA))));				
				--shift right logical
				WHEN "1001" => Result <= std_logic_vector(shift_right(unsigned(inputB), to_integer(unsigned(shamt))));
				--shift right logical vector
				WHEN "1011" => Result <= std_logic_vector(shift_right(unsigned(inputB), to_integer(unsigned(inputA))));				
				--NOR
				WHEN "1100" => Result <= inputA nor inputB;
				--LUI
				WHEN "1101" => Result <= inputB(31 downto 16) & "0000000000000000";								
				WHEN others =>										
	  END CASE;	  
	  
	  IF (Result(31 DOWNTO 0) = X"00000000") THEN
		 Zero <= '1';
	  ELSE
	    Zero <= '0';
	  END IF;
	  
	  ALU_Result <= Result;  
	END PROCESS;
END arch;		  