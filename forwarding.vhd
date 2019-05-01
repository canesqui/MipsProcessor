library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;  

ENTITY forwarding IS
	PORT(
			reset 	 				   : OUT STD_LOGIC;
			slow_clock				   : IN STD_LOGIC;
			
			fRegwrite_EXMEM			: IN STD_LOGIC;
			fRegwrite_MEMWB         : IN STD_LOGIC;
			
			fRead_data1_in				: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			fRead_data2_in          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			fRead_reg1_in				: IN STD_LOGIC_VECTOR(31 DOWNTO 0);	-- what are these for?
			fRead_reg2_in				: IN STD_LOGIC_VECTOR(31 DOWNTO 0);	-- what are these for?
			
			fWrite_reg_EXMEM			: IN STD_LOGIC_VECTOR(4 DOWNTO 0); --fALU_result_EXMEM			: IN STD_LOGIC_VECTOR(4 DOWNTO 0)
			fWrite_reg_MEMWB			: IN STD_LOGIC_VECTOR(4 DOWNTO 0); --freg_writedata_MEMWB		: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			fRS_IDEX						: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			fRT_IDEX						: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			
			fRead_data1_out			: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			fRead_data2_out         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END forwarding;

ARCHITECTURE behavior OF forwarding IS

SIGNAL rd1_mux : STD_LOGIC_VECTOR (1 DOWNTO 0);	-- 2 bit mux
SIGNAL rd2_mux	: STD_LOGIC_VECTOR (1 DOWNTO 0); -- 2 bit mux 
SIGNAL sRead_data1_out	: STD_LOGIC_VECTOR (1 DOWNTO 0); -- signal for output
SIGNAL sRead_data2_out	: STD_LOGIC_VECTOR (1 DOWNTO 0); -- signal for output

--COMPONENT ROMVHDL IS
--	PORT
--	(
--		address		: IN  STD_LOGIC_VECTOR (5 DOWNTO 0);
--		clock			: IN  STD_LOGIC;
--		q				: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
--	);
--END COMPONENT;

--X <= A when (SEL = '1') else B;


BEGIN
	PROCESS (reset)
	BEGIN
		local_reset <= reset;
	END PROCESS;

--PROCESS (mux_branch_sel,sjump_IDEX)
--BEGIN
--	IF (fwrite_reg_EXMEM != 0) THEN
--		IF 	(fRS_IDEX = fwrite_reg_EXMEM) THEN	-- some of these need ORs
--			  <= '1';
--		ELSIF (fRT_IDEX = fwrite_reg_EXMEM) THEN
--			<= ;
--		ELSIF (fRS_IDEX = fwrite_reg_MEMWB) THEN
--			<= ;
--		ELSIF (fRT_IDEX = fwrite_reg_MEMWB) THEN
--			<= ;
--		END IF;
--	END IF;
--END PROCESS; 

PROCESS (fRegwrite_EXMEM,fReg_write_MEMWB, fWrite_reg_EXMEM, fRegwrite_MEMWB, fRS_IDEX, fRT_IDEX)
BEGIN
	--EX hazard
	IF (fRegwrite_EXMEM and (fWrite_reg_EXMEM != 0) and (fWrite_reg_EXMEM = fRS_IDEX)) THEN
		rd1_mux <= "10";
	END IF; 
	
	IF (fRegwrite_EXMEM and (fWrite_reg_EXMEM != 0) and (fWrite_reg_EXMEM = fRT_IDEX)) THEN
		rd2_mux = "10";
	END IF;
	
	--MEM hazard
	IF (fRegwrite_MEMWB and (MEM/WB.RegisterRd != 0) 
		and not (fRegwrite_EXMEM and (fWrite_reg_EXMEM != 0) 
		and (fWrite_reg_EXMEM = fRS_IDEX)) and (fWrite_reg_MEMWB = fRS_IDEX)) THEN
		
		rd1_mux = "01";
	END IF;
	
	IF (fRegwrite_MEMWB and (MEM/WB.RegisterRd != 0) 
		and not (fRegwrite_EXMEM and (fWrite_reg_EXMEM != 0) 
		and (fWrite_reg_EXMEM = fRT_IDEX)) and (fWrite_reg_MEMWB = fRT_IDEX)) THEN
		
		rd2_mux = "01";
	END IF
END PROCESS; 

--1a. EX/MEM.RegisterRd = ID/EX.RegisterRs
--1b. EX/MEM.RegisterRd = ID/EX.RegisterRt
--2a. MEM/WB.RegisterRd = ID/EX.RegisterRs
--2b. MEM/WB.RegisterRd = ID/EX.RegisterRt

--EX hazard
--if (EX/MEM.RegWrite and (EX/MEM.RegisterRd ≠ 0)
-- and (EX/MEM.RegisterRd = ID/EX.RegisterRs))
-- ForwardA = 10
--if (EX/MEM.RegWrite and (EX/MEM.RegisterRd ≠ 0)
-- and (EX/MEM.RegisterRd = ID/EX.RegisterRt))
-- ForwardB = 10
--MEM hazard
--if (MEM/WB.RegWrite and (MEM/WB.RegisterRd ≠ 0)
-- and (MEM/WB.RegisterRd = ID/EX.RegisterRs))
-- ForwardA = 01
--if (MEM/WB.RegWrite and (MEM/WB.RegisterRd ≠ 0)
-- and (MEM/WB.RegisterRd = ID/EX.RegisterRt))
-- ForwardB = 01

PROCESS (rd1_mux)
BEGIN
	WITH rd1_mux SELECT
	sRead_data1_out <= fRead_data1_in when "00",
							 fWrite_reg_MEMWB when "01",	--fWrite_reg_MEMWB	-- mem	
							 fWrite_reg_EXMEM when "10",	-- fWrite_reg_EXMEM	-- ALU
							 --A(3) when "11",
							 '0'  when others;
END PROCESS;

PROCESS (rd2_mux)
BEGIN
	WITH rd2_mux SELECT
	sRead_data2_out <= fRead_data2_in when "00",		-- recheck this next two, 
							 fWrite_reg_MEMWB when "01",	--fWrite_reg_MEMWB	-- mem	
							 fWrite_reg_EXMEM when "10",	-- fWrite_reg_EXMEM	-- ALU
							 --A(3) when "11",
							 '0'  when others;
END PROCESS;
	
	

--if (MEM/WB.RegWrite and (MEM/WB.RegisterRd ≠ 0)
-- and not (EX/MEM.RegWrite and (EX/MEM.RegisterRd ≠ 0)
-- and (EX/MEM.RegisterRd = ID/EX.RegisterRs))
-- and (MEM/WB.RegisterRd = ID/EX.RegisterRs))
-- ForwardA = 01
--if (MEM/WB.RegWrite and (MEM/WB.RegisterRd ≠ 0)
-- and not (EX/MEM.RegWrite and (EX/MEM.RegisterRd ≠ 0)
-- and (EX/MEM.RegisterRd = ID/EX.RegisterRt))
-- and (MEM/WB.RegisterRd = ID/EX.RegisterRt))
-- ForwardB = 01

pc_mips: PC PORT MAP  (
								clock => slow_clock, reset => local_reset, pc_output => pc_counter, 
								pc_input => mux_pc_input--mux_jump_output
							 );

--Mapped output to if/id stage

								  );									

							 
								
END behavior;