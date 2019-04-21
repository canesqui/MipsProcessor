LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all; 

ENTITY signextend IS
	PORT(			
			input							: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			output                  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END signextend;

ARCHITECTURE behavior OF signextend IS
BEGIN
	output <= X"0000"&input WHEN (input(15 DOWNTO 15) = "0") ELSE X"1111"&input;	
END behavior;
