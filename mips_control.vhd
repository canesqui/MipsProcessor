LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY mips_control IS
PORT (	opcode				: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			funct					: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			RegDst, ALUSrc		: OUT STD_LOGIC;
			Jump, Jal, Jr		: OUT STD_LOGIC;
			Beq, Bne				: OUT	STD_LOGIC;
			MemRead, MemWrite	: OUT STD_LOGIC;
			RegWrite, MemtoReg: OUT STD_LOGIC;
			ALUControl			: OUT	STD_LOGIC_VECTOR(3 DOWNTO 0));
END mips_control;

ARCHITECTURE behavior OF mips_control IS
SIGNAL R_type : STD_LOGIC;
BEGIN	
	
	PROCESS ( opcode, funct)
	BEGIN
		RegDst     <= '0';
		ALUSrc     <= '0';
		Jump 	     <= '0';
		Jal 	     <= '0';
		Jr 	     <= '0';
		Beq 	     <= '0';
		Bne 	     <= '0';
		MemRead    <= '0';
		MemWrite   <= '0';
		RegWrite   <= '0';
		MemtoReg   <= '0';
		R_type     <= '0';
		ALUSrc     <= '0';
		ALUControl <= "0000";				
		
		CASE opcode IS
			--opcode R
			WHEN "000000" => RegDst <= '1'; RegWrite <= '1'; R_type <= '1';
			--J
			WHEN "000010" => Jump <= '1'; ALUSrc <= '1';
			--jal
			WHEN "000011" => Jal <= '1'; RegWrite <= '1'; ALUSrc <= '1'; Jump <= '1';						
			--Beq
			WHEN "000100" => Beq <= '1'; ALUControl <= "0110";
			--Bne
			WHEN "000101" => Bne <= '1'; ALUControl <= "0110";
			--Addi
			WHEN "001000" | "001001" => RegWrite <= '1'; ALUSrc <= '1'; ALUControl <= "0010";					
			
			WHEN "001010" | "001011" | "001100" | "001101" | "010111" | "011000" | "011001" | "011100" | "011101" | "011110" | "101000" => RegWrite <= '1'; ALUSrc <= '1';
			--LUI
			WHEN "001111" => ALUControl <= "1101"; RegWrite <= '1'; ALUSrc <= '1';			
			--sw		
			WHEN "101011" => MemWrite <= '1'; ALUSrc <= '1'; ALUControl <= "0010";
			--lw		
			WHEN "100011" => MemRead <= '1'; MemtoReg <= '1'; RegWrite <= '1'; ALUSrc <= '1'; ALUControl <= "0010";
			
			WHEN others =>				
							
		END CASE;
		
		IF (R_type = '1') THEN
			
			CASE funct IS			
		--	add	
				WHEN "100000" =>
					ALUControl <= "0010";				
		-- and			
				WHEN "100100" =>
					ALUControl <= "0000";				
		-- nor			
				WHEN "100111" =>
					ALUControl <= "1100";				
		-- or			
				WHEN "100101" =>
					ALUControl <= "0001";				
		-- slt			
				WHEN "101010"	=>
					ALUControl <= "0111";				
		-- sll			
				WHEN "000000" =>
					ALUControl <= "1000";				
		--	srl			
				WHEN "000010" =>
					ALUControl <= "1001";				
		-- sllv			
				WHEN "000100" =>
					ALUControl <= "1010";				
		-- srlv			
				WHEN "000110" =>
					ALUControl <= "1011";				
		--	sub			
				WHEN "100010" =>
					ALUControl <= "0110";					
		-- Jr			
				WHEN "001000" => Jr <= '1';
				
				WHEN OTHERS => ALUControl <= "0000";	
			END CASE;
		
		END IF;						
    		
	END PROCESS;	
	
END behavior;