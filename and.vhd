library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY andgate IS
    Port ( InputA         : IN  STD_LOGIC;
           InputB         : IN  STD_LOGIC;			  
           Output         : OUT STD_LOGIC);  
END andgate;

ARCHITECTURE behavior OF andgate IS
BEGIN
    Output <= InputA and InputB;      
END behavior;