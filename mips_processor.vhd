library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;  

ENTITY mips_processor IS
	PORT(
			reset 	 				   : IN STD_LOGIC;
			slow_clock					: IN STD_LOGIC;
			PC_out, Instruction_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			--Read_reg1_out				: OUT STD_LOGIC_VECTOR( 4 DOWNTO 0);
			--Read_reg2_out				: OUT STD_LOGIC_VECTOR( 4 DOWNTO 0);
			write_reg_out				: OUT STD_LOGIC_VECTOR( 4 DOWNTO 0);
			--Read_data1_out				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			--Read_data2_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			Write_data_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			reg_write_out				: OUT STD_LOGIC;
			reset_stages_out            : OUT STD_LOGIC;
			sregdest_MEMWB_out           : OUT STD_LOGIC;
			input0_out, input1_out        : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
			rd1_out_debug, rd2_out_debug : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			alu_oper2_out					  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			out_fWrite_reg_EXMEM, out_fWrite_reg_MEMWB, out_fRS_IDEX, out_fRT_IDEX : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
			ronaldo_mux_pc               : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			jal_out								: OUT STD_LOGIC);
			--ram_out				     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			--ram_in					   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			--alu_result                  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			--mem_to_reg_control          : OUT STD_LOGIC);
			--alu_in_b					  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END mips_processor;

ARCHITECTURE behavior OF mips_processor IS

SIGNAL pc_counter, pc_counter_input, spc_IFID, spc_IDEX, spc_EXMEM, spc_MEMWB, instruction, sinstruction_IFID, sinstruction_IDEX, sinstruction_EXMEM, sinstruction_MEMWB, alu_mux_input1, ssignextend_IDEX : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL read_data1_reg, sreaddata1_IDEX, sreaddata1_EXMEM, alu_input_intermed_a, alu_input_intermed_b, alu_input_a, alu_input_b, read_data2_reg, sreaddata2_IDEX, sreaddata2_EXMEM, alu_oper1, alu_oper2 : STD_LOGIC_VECTOR (31 DOWNTO 0); 
SIGNAL temp_calc, mux_branch_input1, smux_branch_input1_EXMEM, mux_jump_input0, mux_pc_input, mux_pc_output, alu_branch_input1 : STD_LOGIC_VECTOR (31 DOWNTO 0); 
SIGNAL alu_result_internal, salumainresult_EXMEM, salumainresult_MEMWB, alu_memory_result, mux_memory_input1, smemreaddata_MEMWB, write_data_input : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL jump_address, sjumpaddress_IDEX, sjumpaddress_EXMEM, mux_jump_output : STD_LOGIC_VECTOR (31 DOWNTO 0);

SIGNAL sregwrite_IDEX, sregwrite_EXMEM, sregwrite_MEMWB, regwrite_signal, sregdest_IDEX, sregdest_EXMEM, sregdest_MEMWB : STD_LOGIC; 
SIGNAL regdest, alu_src, salusrc_IDEX, mem_to_reg, smemtoreg_IDEX, smemtoreg_EXMEM : STD_LOGIC;
SIGNAL smemtoreg_MEMWB, bne_control, sbne_IDEX, sbne_EXMEM, beq_control, sbeq_IDEX : STD_LOGIC;
SIGNAL sbeq_EXMEM,alu_zero, salu_zero_EXMEM, sjal_IDEX, sjal_EXMEM, sjal_MEMWB, jal_control, jr_control, sjr_IDEX, sjr_EXMEM : STD_LOGIC; 
SIGNAL mem_read, smemread_IDEX, smemread_EXMEM, mem_write, smemwrite_IDEX, smemwrite_EXMEM : STD_LOGIC;
SIGNAL sjump_IDEX, sjump_EXMEM, jump_control, mux_branch_sel, branch_bne_input, branch_beq_input, local_reset, reset_stages, reset_branch, debug_reset: STD_LOGIC;

SIGNAL regdestmux, sregdestmux_IDEX, sregdestmux_MEMWB, mux_write_register, swriteregister_IDEX, swriteregister_EXMEM, swriteregister_MEMWB, read_reg1_input, sreadreg1_IF, sreadreg1_IFID, sreadreg2_IFID, sreadreg1_MEMWB, sreadreg2_MEMWB, sreadreg1_EXMEM, sreadreg2_EXMEM, sreadreg1_IDEX, sreadreg2_IDEX : STD_LOGIC_VECTOR (4 DOWNTO 0);

SIGNAL alu_control, salucontrol_IDEX                    : STD_LOGIC_VECTOR (3 DOWNTO 0);
COMPONENT PC IS
	PORT(
			clock, reset : IN  STD_LOGIC;
			pc_input	    : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);		
			pc_output    : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		  );
END COMPONENT;

COMPONENT ROMVHDL IS
	PORT
	(
		address		: IN  STD_LOGIC_VECTOR (5 DOWNTO 0);
		clock			: IN  STD_LOGIC;
		q				: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT mips_control IS
PORT (	opcode				: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			funct					: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
			RegDst, ALUSrc		: OUT STD_LOGIC;
			Jump, Jal, Jr		: OUT STD_LOGIC;
			Beq, Bne				: OUT	STD_LOGIC;
			MemRead, MemWrite	: OUT STD_LOGIC;
			RegWrite, MemtoReg: OUT STD_LOGIC;
			ALUControl			: OUT	STD_LOGIC_VECTOR(3 DOWNTO 0));
END COMPONENT;

COMPONENT register_file IS
	PORT (clock, reset, RegWrite : IN STD_LOGIC;
			read_reg1, read_reg2   : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
			write_reg				  : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
			write_data				  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);			
			read_data1, read_data2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END COMPONENT;

COMPONENT mux IS
  PORT( input0, input1	   : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
		  sel				    	: IN STD_LOGIC;
		  output	     		   : OUT STD_LOGIC_VECTOR(4 DOWNTO 0));
END COMPONENT;

COMPONENT mux32 IS
  PORT( input0, input1	   : IN STD_LOGIC_VECTOR( 31 DOWNTO 0);
		  sel				    	: IN STD_LOGIC;
		  output	     		   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END COMPONENT;

COMPONENT signextend IS
	PORT(			
			input							: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			output                  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END COMPONENT;

COMPONENT alu IS
  PORT( ALUControl			: IN STD_LOGIC_VECTOR( 3 DOWNTO 0);
		  inputA, inputB     : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		  shamt					: IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
		  Zero					: OUT STD_LOGIC;
		  ALU_Result			: OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END COMPONENT;

COMPONENT RAM IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
		clock		   : IN STD_LOGIC;
		data		   : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rden		   : IN STD_LOGIC  := '1';
		wren		   : IN STD_LOGIC ;
		q		      : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT andgate IS
    Port ( InputA         : IN  STD_LOGIC;
           InputB         : IN  STD_LOGIC;			  
           Output         : OUT STD_LOGIC);
END COMPONENT;

COMPONENT orgate IS
    Port ( InputA   : IN  STD_LOGIC;
           InputB   : IN  STD_LOGIC;
           Output   : OUT STD_LOGIC
			);  
END COMPONENT;

COMPONENT forwarding IS
	PORT(
			--reset 	 				   : OUT STD_LOGIC;
			
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
			rd1_out,rd2_out         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			fWrite_reg_EXMEM_out, fWrite_reg_MEMWB_out, fRS_IDEX_out, fRT_IDEX_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0));
			--write_data_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			--alu_result_out 			: OUT STD_LOGIC_VECTOR(31 DOWNTO 0));			
END COMPONENT;



----fRegwrite_EXMEM			: IN STD_LOGIC;	-- reg write signal from EX/Mem
----			fRegwrite_MEMWB         : IN STD_LOGIC;	-- reg write signal from Ex/Mem
--			
----			fRead_data1_in				: IN STD_LOGIC_VECTOR(31 DOWNTO 0);	-- readdata1 in from register file
----			fRead_data2_in          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);	-- readdata2 in from register file
--			fALU_result_EXMEM		   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);	-- EX/Mem ALU result
--			freg_writedata_MEMWB		: IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Mem/WB write register data 
--			
--			fWrite_reg_EXMEM			: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- write register from Ex/Mem 			
--			fWrite_reg_MEMWB			: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- write register from Mem/WB			
--			fRS_IDEX						: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- RS register from ID/EX
--			fRT_IDEX						: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- RT register from ID/EX
--			
--			fRead_data1_out			: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);	-- readdata1 out to alu
--			fRead_data2_out         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));	-- readdata2 out to alu


BEGIN
	PROCESS (reset)
	BEGIN
		local_reset <= reset;		 
	END PROCESS;
	
--Mapped output to if/id stage	
PROCESS (pc_counter)
BEGIN	
	pc_counter_input <= pc_counter + 4;
	
END PROCESS;

PC_out <= spc_MEMWB;

PROCESS (sinstruction_IFID)
BEGIN	
	jump_address <= pc_counter_input(31 DOWNTO 28) & (sinstruction_IFID(25 DOWNTO 0)&"00");	
	
	--read_reg1_out <= sinstruction_IFID(25 DOWNTO 21);
	--read_reg2_out <= sinstruction_IFID(20 DOWNTO 16);	
END PROCESS;

--PROCESS (regdestmux, read_data1_reg, read_data2_reg)
--BEGIN
	--Read_data1_out <= read_data1_reg;
	--Read_data2_out <= read_data2_reg;
	
	
--END PROCESS;

instruction_out <= sinstruction_MEMWB;
		
PROCESS (write_data_input, sregwrite_MEMWB, swriteregister_MEMWB, sregdest_MEMWB, sinstruction_MEMWB, sjal_MEMWB)
BEGIN
	reg_write_out <= sregwrite_MEMWB;	
	write_reg_out  <= swriteregister_MEMWB;
	write_data_out <= write_data_input;	
	sregdest_MEMWB_out <= sregdest_MEMWB;
	input0_out <= sinstruction_MEMWB(20 DOWNTO 16);
	input1_out <= sinstruction_MEMWB(15 DOWNTO 11);
	alu_oper2_out <= alu_oper2;
   jal_out <= sjal_MEMWB;	
	--ram_in <= sreaddata2_EXMEM;
	--alu_result <= alu_memory_result;
	--mem_to_reg_control <= smemtoreg_MEMWB;
END PROCESS;
		

PROCESS (ssignextend_IDEX)
BEGIN
	alu_branch_input1 <= std_logic_vector(shift_left(unsigned(ssignextend_IDEX), 2));
	--dbg_alu_max_input1 <= alu_mux_input1;
END PROCESS;


--if/id
PROCESS (slow_clock)
BEGIN
	IF RISING_EDGE(slow_clock) THEN
		IF (reset_stages = '1') THEN
			sinstruction_IFID <= X"00000000";
			spc_IFID <= X"00000000";
		ELSE
			sinstruction_IFID <= instruction;
			spc_IFID <= pc_counter_input; --mapped
			--debug_instruction_out <= pc_counter_input;
		END IF;
	END IF;
END PROCESS;

--id/ex
PROCESS (slow_clock)
BEGIN

	IF RISING_EDGE(slow_clock) THEN
		IF (reset_stages = '1') THEN
			spc_IDEX <= x"00000000";	
			--MIPS_CONTROL
			sregwrite_IDEX <= '0';
			sregdest_IDEX <= '0';
			salusrc_IDEX <= '0';
			salucontrol_IDEX <= "0000";
			smemtoreg_IDEX <= '0';
			sjal_IDEX <= '0';
			smemread_IDEX <= '0';
			smemwrite_IDEX <= '0';
			sjump_IDEX <= '0';
			sbeq_IDEX <= '0';
			sbne_IDEX <= '0';
			sjr_IDEX <= '0';
			--register_file
			sreaddata1_IDEX <= X"00000000";
			sreaddata2_IDEX <= X"00000000";
			--signextend
			ssignextend_IDEX <= X"00000000";	
			sjumpaddress_IDEX <= X"00000000";
			sreadreg1_IDEX <= "00000";
			sreadreg2_IDEX <= "00000";
			--swriteregister_IDEX <= "00000";
			--sregdestmux_IDEX <= "00000";
			sinstruction_IDEX <= X"00000000";
		ELSE
			spc_IDEX <= spc_IFID;	
			--MIPS_CONTROL
			sregwrite_IDEX <= regwrite_signal;
			sregdest_IDEX <= regdest;
			salusrc_IDEX <= alu_src;
			salucontrol_IDEX <= alu_control;
			smemtoreg_IDEX <= mem_to_reg;
			sjal_IDEX <= jal_control;
			smemread_IDEX <= mem_read;
			smemwrite_IDEX <= mem_write;
			sjump_IDEX <= jump_control;
			--ronaldo
			--sel_mux_jump <= jump_control;
			sbeq_IDEX <= beq_control;
			sbne_IDEX <= bne_control;
			sjr_IDEX <= jr_control;
			--register_file
			sreaddata1_IDEX <= read_data1_reg;
			sreaddata2_IDEX <= read_data2_reg;
			--signextend
			ssignextend_IDEX <= alu_mux_input1;	
			sjumpaddress_IDEX <= jump_address;
			--Going to go to the Forwarding Unit
			sreadreg1_IDEX <= sinstruction_IFID(25 DOWNTO 21);
			sreadreg2_IDEX <= sinstruction_IFID(20 DOWNTO 16);
			--swriteregister_IDEX <= mux_write_register;					
			--sregdestmux_IDEX <= regdestmux;
			sinstruction_IDEX <= sinstruction_IFID;
		END IF;
	END IF;

	
	
END PROCESS;

--ex/mem
PROCESS (slow_clock)
BEGIN
	IF RISING_EDGE(slow_clock) THEN
		IF (reset_stages = '1') THEN						
			spc_EXMEM <= x"00000000";		
			--MIPS_CONTROL
			sregwrite_EXMEM <= '0';
			smemread_EXMEM <= '0';
			smemwrite_EXMEM <= '0';
			smemtoreg_EXMEM <= '0';
			sbeq_EXMEM <= '0';
			sbne_EXMEM <= '0';
			--sregdest_EXMEM <= '0';
			sjal_EXMEM <= '0';	
			sjump_EXMEM <= '0';	
			sjr_EXMEM <= '0';
			--register_file
			sreaddata1_EXMEM <= X"00000000";
			sreaddata2_EXMEM <= X"00000000";				
			--ALU Main
			salumainresult_EXMEM <= X"00000000";				
			sjumpaddress_EXMEM <= X"00000000";
			sreadreg1_EXMEM <= "00000";
			sreadreg2_EXMEM <= "00000";
			swriteregister_EXMEM <= "00000";
			--sregdestmux_EXMEM <= "00000";
			sinstruction_EXMEM <= X"00000000";
			salu_zero_EXMEM <= '0';
		ELSE
			spc_EXMEM <= spc_IDEX;		
			--MIPS_CONTROL
			sregwrite_EXMEM <= sregwrite_IDEX;
			smemread_EXMEM <= smemread_IDEX;
			smemwrite_EXMEM <= smemwrite_IDEX;
			smemtoreg_EXMEM <= smemtoreg_IDEX;
			sbeq_EXMEM <= sbeq_IDEX;
			sbne_EXMEM <= sbne_IDEX;
			--sregdest_EXMEM <= sregdest_IDEX;
			sjal_EXMEM <= sjal_IDEX;	
			sjump_EXMEM <= sjump_IDEX;	
			--sel_mux_jump <= sjump_IDEX;
			
			sjr_EXMEM <= sjr_IDEX;
			--register_file
			sreaddata1_EXMEM <= sreaddata1_IDEX;
			sreaddata2_EXMEM <= sreaddata2_IDEX;				
			--ALU Main
			salumainresult_EXMEM <= alu_result_internal;				
			--
			sjumpaddress_EXMEM <= sjumpaddress_IDEX;
			--
			sreadreg1_EXMEM <= sreadreg1_IDEX;
			sreadreg2_EXMEM <= sreadreg2_IDEX;
			swriteregister_EXMEM <= regdestmux;
			--sregdestmux_EXMEM <= regdestmux;
			sinstruction_EXMEM <= sinstruction_IDEX;
			--mux_one <= sjumpaddress_EXMEM;					
			salu_zero_EXMEM <= alu_zero;
			smux_branch_input1_EXMEM <= mux_branch_input1;
			--debug only
			sregdest_EXMEM <= sregdest_IDEX;
			
		END IF;
	END IF;
END PROCESS;

--mem/wb
PROCESS (slow_clock)
BEGIN

	IF RISING_EDGE(slow_clock) THEN
		IF (reset_stages = '1' AND sjal_EXMEM = '0') THEN									
			spc_MEMWB <= x"00000000";	
			--MIPS_CONTROL
			sregwrite_MEMWB <= '0';	
			smemtoreg_MEMWB <= '0';
			sjal_MEMWB <= '0';				
			--ALU Main
			salumainresult_MEMWB <= X"00000000";
			smemreaddata_MEMWB <= X"00000000";
			sreadreg1_MEMWB <= "00000";
			sreadreg2_MEMWB <= "00000";
			swriteregister_MEMWB <= "00000";
			--sregdestmux_MEMWB <= "00000";
			sinstruction_MEMWB <= x"00000000";
		ELSE
			spc_MEMWB <= spc_EXMEM;	
			--MIPS_CONTROL
			sregwrite_MEMWB <= sregwrite_EXMEM;	
			smemtoreg_MEMWB <= smemtoreg_EXMEM;
			sjal_MEMWB <= sjal_EXMEM;				
			--ALU Main
			salumainresult_MEMWB <= salumainresult_EXMEM;
			smemreaddata_MEMWB <= mux_memory_input1;
			--
			--sregdest_MEMWB <= sregdest_EXMEM;
			--
			sreadreg1_MEMWB <= sreadreg1_EXMEM;
			sreadreg2_MEMWB <= sreadreg2_EXMEM;
			--
			swriteregister_MEMWB <= swriteregister_EXMEM;	
			--sregdestmux_MEMWB <= sregdestmux_EXMEM;			
			sinstruction_MEMWB <= sinstruction_EXMEM;
			--debug only
			sregdest_MEMWB <= sregdest_EXMEM;
		END IF;
	END IF;
	
END PROCESS;

PROCESS (mux_branch_sel,sjump_EXMEM, sjr_EXMEM)
BEGIN
	IF (mux_branch_sel = '1' OR sjump_EXMEM = '1' OR sjr_EXMEM = '1') THEN
			reset_stages <= '1';			
			--reset_branch <= '1';
		ELSE
			reset_stages <= '0';			
			--reset_branch <= '0';
	END IF;
	reset_stages_out <= reset_stages;
	--reset_stages_out <= reset_branch;
END PROCESS; 

ronaldo_mux_pc <= mux_pc_output;

mux_pc : mux32 PORT MAP ( input0 => pc_counter_input, input1 => mux_pc_input,
													 sel => reset_stages, output => mux_pc_output 
											      );


pc_mips: PC PORT MAP  (
								clock => slow_clock, reset => local_reset, pc_output => pc_counter, 
								pc_input => mux_pc_output --pc_counter_input--mux_pc_input--mux_jump_output
					  );

--Mapped output to if/id stage
rom    : ROMVHDL PORT MAP (
								clock => NOT slow_clock, address => pc_counter(7 DOWNTO 2), q => instruction
							 );

control: MIPS_CONTROL PORT MAP ( opcode => sinstruction_IFID(31 DOWNTO 26), funct => sinstruction_IFID(5 DOWNTO 0),
											RegWrite => regwrite_signal, RegDst => regdest, ALUSrc => alu_src, 																						
											ALUControl => alu_control, MemtoReg => mem_to_reg, Jal => jal_control,
											MemRead => mem_read, MemWrite => mem_write, Jump => jump_control,
											Beq => beq_control, Bne => bne_control, Jr => jr_control								
							  );							 
			
--Jal, Jr		: OUT STD_LOGIC;

							  
reg_file : register_file PORT MAP (	clock => NOT slow_clock, reset => local_reset, RegWrite => sregwrite_MEMWB,
												read_reg1 => sinstruction_IFID(25 DOWNTO 21), read_reg2 => sinstruction_IFID(20 DOWNTO 16),
												write_reg => mux_write_register, read_data1 => read_data1_reg, read_data2 => read_data2_reg,
												write_data => write_data_input
											  );

--mux_reg_file : mux PORT MAP ( input0 => sinstruction_IFID(20 DOWNTO 16), input1 => sinstruction_IFID(15 DOWNTO 11),
mux_reg_file : mux PORT MAP ( input0 => sinstruction_IDEX(20 DOWNTO 16), input1 => sinstruction_IDEX(15 DOWNTO 11),
													 sel => sregdest_IDEX, output => regdestmux
											      );

mux_alu : mux32 PORT MAP ( input0 => alu_input_b, input1 => ssignextend_IDEX,
													 sel => salusrc_IDEX, output => alu_oper2 
											      );	

mux_memory : mux32 PORT MAP ( input0 => salumainresult_MEMWB, input1 => smemreaddata_MEMWB,
													 sel => smemtoreg_MEMWB, output => alu_memory_result 
											      );	
																										
mux_jump : mux32 PORT MAP ( input0 => mux_jump_input0, input1 => sjumpaddress_EXMEM,
													 sel => sjump_EXMEM, output => mux_jump_output 
											      );	

mux_branch : mux32 PORT MAP ( input0 => spc_EXMEM, input1 => smux_branch_input1_EXMEM,
													 sel => mux_branch_sel, output => mux_jump_input0 
											      );	

													
mux_writeregister : mux PORT MAP ( input0 => swriteregister_MEMWB, input1 => "11111",
													 sel => sjal_MEMWB, output => mux_write_register 
											      );	
													
													
mux_jr : mux32 PORT MAP ( input0 => mux_jump_output, input1 => sreaddata1_EXMEM,
													 sel => sjr_EXMEM, output => mux_pc_input 
											      );														


mux_jal : mux32 PORT MAP ( input0 => alu_memory_result, input1 => spc_MEMWB,
													 sel => sjal_MEMWB, output => write_data_input 
											     );	

													
sign_extend : signextend PORT MAP ( input => sinstruction_IFID(15 DOWNTO 0), output => alu_mux_input1
											  );
												

alu_main : alu PORT MAP ( inputA => alu_input_a, inputB => alu_oper2, 
								  --inputA => sreaddata1_IDEX, inputB => alu_oper2,
								  ALUControl => salucontrol_IDEX, shamt => sinstruction_IDEX(10 DOWNTO 6),
								  ALU_Result => alu_result_internal, Zero => alu_zero
								  );												

alu_branch : alu PORT MAP ( inputA => spc_IDEX, inputB => alu_branch_input1, 
								  ALUControl => "0010", shamt => "00000",
								  ALU_Result => mux_branch_input1
								  );								  
								  
								  
mem : RAM PORT MAP ( clock => NOT slow_clock, address => salumainresult_EXMEM(7 DOWNTO 2), 
							data => sreaddata2_EXMEM, rden => smemread_EXMEM, 
							wren => smemwrite_EXMEM, q => mux_memory_input1   
						  );	

bne_and : andgate PORT MAP ( inputA => sbne_EXMEM, inputB => not salu_zero_EXMEM, output => branch_bne_input
									);								  

beq_and : andgate PORT MAP ( inputA => sbeq_EXMEM, inputB => salu_zero_EXMEM, output => branch_beq_input
									);
									
branch : orgate PORT MAP ( inputA => branch_bne_input, inputB => branch_beq_input, output => mux_branch_sel
								  );									
								  							  
--sregwrite_MEMWB <= sregwrite_EXMEM;	
--PROCESS (alu_input_a, alu_input_b)
--BEGIN
--	alu_in_a <= alu_input_a;
	--alu_in_b <= alu_input_b;
--END PROCESS;

							  
forward : forwarding PORT MAP ( 
										  fRegwrite_EXMEM => sregwrite_EXMEM, 
										  fRegwrite_MEMWB => sregwrite_MEMWB, 
										  fRead_data1_in => sreaddata1_IDEX, 
										  fRead_data2_in => sreaddata2_IDEX,
										  fALU_result_EXMEM => salumainresult_EXMEM, 
										  freg_writedata_MEMWB => write_data_input,
										  fWrite_reg_EXMEM => swriteregister_EXMEM, 
										  fWrite_reg_MEMWB => swriteregister_MEMWB,
										  fRS_IDEX => sreadreg1_IDEX, 
										  fRT_IDEX => sreadreg2_IDEX,
										  fRead_data1_out => alu_input_a, 
										  fRead_data2_out => alu_input_b,--,
										  rd1_out => rd1_out_debug,
										  rd2_out => rd2_out_debug,--,
										  --write_data_out => alu_input_a,
										  --alu_result_out => alu_input_b
										  fWrite_reg_EXMEM_out => out_fWrite_reg_EXMEM,
										  fWrite_reg_MEMWB_out => out_fWrite_reg_MEMWB,
										  fRS_IDEX_out => out_fRS_IDEX,
										  fRT_IDEX_out => out_fRT_IDEX
										);							 
		
END behavior;