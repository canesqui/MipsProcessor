library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY orgate IS
    Port ( InputA   : IN  STD_LOGIC;
           InputB   : IN  STD_LOGIC;
           Output   : OUT STD_LOGIC);  
END orgate;

ARCHITECTURE behavior OF orgate IS
BEGIN
    Output <= InputA OR InputB;    
END behavior;