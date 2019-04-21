library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all; 

ENTITY mux IS
  PORT( input0, input1	   : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
		  sel				    	: IN STD_LOGIC;
		  output	     		   : OUT STD_LOGIC_VECTOR(4 DOWNTO 0));
END mux;

ARCHITECTURE behavior OF mux IS
BEGIN

	output <= input0 WHEN (sel='0') ELSE input1;
	
END behavior;