LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY PC IS
	PORT(
			clock, reset : IN STD_LOGIC;
			pc_input	    : IN STD_LOGIC_VECTOR (31 DOWNTO 0);		
			pc_output    : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		  );
END PC;

ARCHITECTURE behavior OF PC IS
BEGIN

PROCESS (clock, reset)
BEGIN		
	IF (reset = '0') THEN
		pc_output <= X"00400000";
	ELSIF (RISING_EDGE(clock)) THEN
		pc_output <= pc_input;
	END IF;		
		
END PROCESS;

END behavior;