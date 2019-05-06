library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;  

ENTITY forwarding IS
	PORT(	fRegwrite_EXMEM			: IN STD_LOGIC;	-- reg write signal from EX/Mem
			fRegwrite_MEMWB         : IN STD_LOGIC;	-- reg write signal from Ex/Mem
			
			fRead_data1_in				: IN STD_LOGIC_VECTOR(31 DOWNTO 0);	-- readdata1 in from register file
			fRead_data2_in          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);	-- readdata2 in from register file
			fALU_result_EXMEM		   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);	-- EX/Mem ALU result
			freg_writedata_MEMWB		: IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Mem/WB write register data 
			
			fWrite_reg_EXMEM			: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- write register from Ex/Mem 			
			fWrite_reg_MEMWB			: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- write register from Mem/WB			
			fRS_IDEX						: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- RS register from ID/EX
			fRT_IDEX						: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- RT register from ID/EX
			
			fRead_data1_out			: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);	-- readdata1 out to alu
			fRead_data2_out         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));	-- readdata2 out to alu
END forwarding;

ARCHITECTURE behavior OF forwarding IS

SIGNAL rd1_mux 		: STD_LOGIC_VECTOR (1 DOWNTO 0);	-- 2 bit mux
SIGNAL rd2_mux			: STD_LOGIC_VECTOR (1 DOWNTO 0); -- 2 bit mux 
SIGNAL local_reset 	: STD_LOGIC;

BEGIN
	
PROCESS (fRegwrite_EXMEM, fRegwrite_MEMWB, fWrite_reg_EXMEM, fWrite_reg_MEMWB, fRS_IDEX, fRT_IDEX)
BEGIN
	--No hazard
	rd1_mux <= "00";
	rd2_mux <= "00";
	--EX hazard
	IF ((fRegwrite_EXMEM = '1') 
			AND (fWrite_reg_EXMEM /= "00000") 
			AND (fWrite_reg_EXMEM = fRS_IDEX)) THEN	
		rd1_mux <= "10"; 
	--MEM hazard
	ELSIF (fRegwrite_MEMWB = '1' 
			AND (fWrite_reg_MEMWB /= "00000") 
			AND NOT ((fRegwrite_EXMEM = '1')
			AND (fWrite_reg_EXMEM /= "00000") 
			AND (fWrite_reg_EXMEM = fRS_IDEX)) 
			AND (fWrite_reg_MEMWB = fRS_IDEX)) THEN	
		rd1_mux <= "01";
	END IF;
	--EX hazard
	IF ((fRegwrite_EXMEM = '1') 
			AND (fWrite_reg_EXMEM /= "00000") 
			AND (fWrite_reg_EXMEM = fRT_IDEX)) THEN
		rd2_mux <= "10";
	--MEM hazard
	ELSIF ((fRegwrite_MEMWB = '1')
			AND (fWrite_reg_MEMWB /= "00000")
			AND NOT ((fRegwrite_EXMEM = '1') 
			AND (fWrite_reg_EXMEM /= "00000") 
			AND (fWrite_reg_EXMEM = fRT_IDEX)) 
			AND (fWrite_reg_MEMWB = fRT_IDEX)) THEN
		rd2_mux <= "01";
	END IF;
--	if (	MEM/WB.RegWrite 
--			and (MEM/WB.RegisterRd ≠ 0)
--			and not (EX/MEM.RegWrite 
--			and (EX/MEM.RegisterRd ≠ 0)
--			and (EX/MEM.RegisterRd = ID/EX.RegisterRs))
--			and (MEM/WB.RegisterRd = ID/EX.RegisterRs))
--	 ForwardA = 01
--	if (	MEM/WB.RegWrite 
--			and (MEM/WB.RegisterRd ≠ 0)
--			and not (EX/MEM.RegWrite 
--			and (EX/MEM.RegisterRd ≠ 0)
--			and (EX/MEM.RegisterRd = ID/EX.RegisterRt))
--			and (MEM/WB.RegisterRd = ID/EX.RegisterRt))
--	 ForwardB = 01
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


WITH (rd1_mux) SELECT
fRead_data1_out <= fRead_data1_in when "00",
						 freg_writedata_MEMWB when "01",	--fWrite_reg_MEMWB	-- mem	
						 fALU_result_EXMEM when "10",	-- fWrite_reg_EXMEM	-- ALU
						 --X when "11",
						 X"00000000" when others;

WITH (rd2_mux) SELECT
fRead_data2_out <= fRead_data2_in when "00",		-- recheck this next two, 
						 freg_writedata_MEMWB when "01",	--fWrite_reg_MEMWB	-- mem	
						 fALU_result_EXMEM when "10",	-- fWrite_reg_EXMEM	-- ALU
						 --X when "11",
						 X"00000000" when others;
						 
END behavior;