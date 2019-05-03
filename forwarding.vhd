library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;  

ENTITY forwarding IS
	PORT(
			--reset 	 				   : OUT STD_LOGIC;
			--slow_clock				   : IN STD_LOGIC;
			
			fRegwrite_EXMEM			: IN STD_LOGIC;	-- reg write signal from EX/Mem
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
			fRead_data2_out         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);	-- readdata2 out to alu
			rd1_out,rd2_out         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));			
END forwarding;

ARCHITECTURE behavior OF forwarding IS

SIGNAL rd1_mux : STD_LOGIC_VECTOR (1 DOWNTO 0);	-- 2 bit mux
SIGNAL rd2_mux	: STD_LOGIC_VECTOR (1 DOWNTO 0); -- 2 bit mux 
--SIGNAL sRead_data1_out	: STD_LOGIC_VECTOR (31 DOWNTO 0); -- signal for output
--SIGNAL sRead_data2_out	: STD_LOGIC_VECTOR (31 DOWNTO 0); -- signal for output
SIGNAL local_reset, fReg_write_MEMWB : STD_LOGIC;

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
	
--	PROCESS (reset)
--	BEGIN
--		local_reset <= reset;
--	END PROCESS;

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

PROCESS (fRegwrite_EXMEM, fRegwrite_MEMWB, fWrite_reg_EXMEM, fWrite_reg_MEMWB, fRS_IDEX, fRT_IDEX)
BEGIN
	--No hazard
	rd1_mux <= "00";
	rd2_mux <= "00";
	--EX hazard
	IF (((fRegwrite_EXMEM = '1') 
		and (fWrite_reg_EXMEM /= "00000") 
		and (fWrite_reg_EXMEM = fRS_IDEX))) THEN	
		rd1_mux <= "10"; 
	--MEM hazard
	ELSIF (((fRegwrite_MEMWB = '1') 
		and (fWrite_reg_MEMWB /= "00000") 
		and not ((fRegwrite_EXMEM = '1') 
		and (fWrite_reg_EXMEM /= "00000") -- make sure that the not is for the combination of the two
		and (fWrite_reg_EXMEM = fRS_IDEX)) 
		and (fWrite_reg_MEMWB = fRS_IDEX))) THEN
		
		rd1_mux <= "01";
	END IF;
	--EX hazard
	IF (((fRegwrite_EXMEM = '1') 
		and (fWrite_reg_EXMEM /= "00000") 
		and (fWrite_reg_EXMEM = fRT_IDEX))) THEN
		rd2_mux <= "10";
	--MEM hazard
	ELSIF (((fRegwrite_MEMWB = '1') 
		and (fWrite_reg_MEMWB /= "00000")
		and not ((fRegwrite_EXMEM = '1') 
		and (fWrite_reg_EXMEM /= "00000") 
		and (fWrite_reg_EXMEM = fRT_IDEX)) 
		and (fWrite_reg_MEMWB = fRT_IDEX))) THEN
		
		rd2_mux <= "01";
	END IF;
	
	--MEM hazard
--	IF (((fRegwrite_MEMWB = '1') and (fWrite_reg_MEMWB /= 0) 
--		and not (fRegwrite_EXMEM =  (fWrite_reg_EXMEM /= 0) 
--		and (fWrite_reg_EXMEM = fRS_IDEX)) and (fWrite_reg_MEMWB = fRS_IDEX)) = true) THEN
--		
--		rd1_mux <= "01";
--	END IF;
--	
--	IF (((fRegwrite_MEMWB = '1') and (fWrite_reg_MEMWB /= 0)
--		and not (fRegwrite_EXMEM = '1' and (fWrite_reg_EXMEM /= 0) 
--		and (fWrite_reg_EXMEM = fRT_IDEX)) and (fWrite_reg_MEMWB = fRT_IDEX)) = true) THEN
--		
--		rd2_mux <= "01";
--	END IF;
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

	process(rd1_mux, rd2_mux)
	begin
		rd1_out <= fRead_data1_in;
		rd2_out <= fRead_data2_in;
	end process;
	
	WITH (rd1_mux) SELECT
	fRead_data1_out <= fRead_data1_in when "00",
							 freg_writedata_MEMWB when "01",	--fWrite_reg_MEMWB	-- mem	
							 fALU_result_EXMEM when "10",	-- fWrite_reg_EXMEM	-- ALU
							 --A(3) when "11",
							 X"00000000" when others;


	WITH (rd2_mux) SELECT
	fRead_data2_out <= fRead_data2_in when "00",		-- recheck this next two, 
							 freg_writedata_MEMWB when "01",	--fWrite_reg_MEMWB	-- mem	
							 fALU_result_EXMEM when "10",	-- fWrite_reg_EXMEM	-- ALU
							 --A(3) when "11",
							 X"00000000" when others;

	
	

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

--Mapped output to if/id stage
							
							 
								
END behavior;