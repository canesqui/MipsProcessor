library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;  

ENTITY mips_processor IS
	PORT(
			reset 	 				   : IN STD_LOGIC;
			slow_clock, fast_clock  : IN STD_LOGIC;
			PC_out, Instruction_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			Read_reg1_out				: OUT STD_LOGIC_VECTOR( 4 DOWNTO 0);
			Read_reg2_out				: OUT STD_LOGIC_VECTOR( 4 DOWNTO 0);
			Write_reg_out				: OUT STD_LOGIC_VECTOR( 4 DOWNTO 0);
			Read_data1_out				: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			Read_data2_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			Write_data_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			mux_one						: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			sel_mux_jump			   : OUT STD_LOGIC);
END mips_processor;

ARCHITECTURE behavior OF mips_processor IS

SIGNAL pc_counter, pc_counter_input, spc_IFID, spc_IDEX, spc_EXMEM, spc_MEMWB, instruction, sinstruction_IFID, alu_mux_input1, ssignextend_IDEX : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL read_data1_reg, sreaddata1_IDEX, sreaddata1_EXMEM, alu_input_a, alu_input_b, read_data2_reg, sreaddata2_IDEX, sreaddata2_EXMEM, alu_oper1, alu_oper2 : STD_LOGIC_VECTOR (31 DOWNTO 0); 
SIGNAL temp_calc, mux_branch_input1, mux_jump_input0, mux_pc_input, alu_branch_input1 : STD_LOGIC_VECTOR (31 DOWNTO 0); 
SIGNAL alu_result_internal, salumainresult_EXMEM, salumainresult_MEMWB, alu_memory_result, mux_memory_input1, smemreaddata_MEMWB, write_data_input : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL jump_address, sjumpaddress_IDEX, sjumpaddress_EXMEM, mux_jump_output : STD_LOGIC_VECTOR (31 DOWNTO 0);

SIGNAL sregwrite_IDEX, sregwrite_EXMEM, sregwrite_MEMWB, regwrite_signal, sregdest_IDEX, sregdest_EXMEM, sregdest_MEMWB : STD_LOGIC; 
SIGNAL regdest, alu_src, salusrc_IDEX, mem_to_reg, smemtoreg_IDEX, smemtoreg_EXMEM : STD_LOGIC;
SIGNAL smemtoreg_MEMWB, bne_control, sbne_IDEX, sbne_EXMEM, beq_control, sbeq_IDEX : STD_LOGIC;
SIGNAL sbeq_EXMEM,alu_zero, sjal_IDEX, sjal_EXMEM, sjal_MEMWB, jal_control, jr_control, sjr_IDEX, sjr_EXMEM : STD_LOGIC; 
SIGNAL mem_read, smemread_IDEX, smemread_EXMEM, mem_write, smemwrite_IDEX, smemwrite_EXMEM : STD_LOGIC;
SIGNAL sjump_IDEX, sjump_EXMEM, jump_control, mux_branch_sel, branch_bne_input, branch_beq_input, local_reset, reset_stages, debug_reset: STD_LOGIC;

SIGNAL regdestmux, mux_write_register, swriteregister_IDEX, swriteregister_EXMEM, swriteregister_MEMWB, read_reg1_input, sreadreg1_IF, sreadreg1_IFID, sreadreg2_IFID, sreadreg1_MEMWB, sreadreg2_MEMWB, sreadreg1_EXMEM, sreadreg2_EXMEM, sreadreg1_IDEX, sreadreg2_IDEX : STD_LOGIC_VECTOR (4 DOWNTO 0);

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
			fRead_data2_out         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));	-- readdata2 out to alu 
END COMPONENT;


BEGIN
	PROCESS (reset)
	BEGIN
		local_reset <= reset;		 
	END PROCESS;
	
--Mapped output to if/id stage	
PROCESS (pc_counter)
BEGIN	
	pc_counter_input <= pc_counter + 4;
	PC_out <= pc_counter_input;
END PROCESS;

PROCESS (sinstruction_IFID)
BEGIN
	--ronaldo
	jump_address <= pc_counter_input(31 DOWNTO 28) & (sinstruction_IFID(25 DOWNTO 0)&"00");	
	instruction_out <= sinstruction_IFID;
	read_reg1_out <= sinstruction_IFID(25 DOWNTO 21);
	read_reg2_out <= sinstruction_IFID(20 DOWNTO 16);	
END PROCESS;

PROCESS (regdestmux, read_data1_reg, read_data2_reg, write_data_input, mux_write_register)
BEGIN
	Read_data1_out <= read_data1_reg;
	Read_data2_out <= read_data2_reg;
	Write_data_out <= write_data_input;
	write_reg_out  <= mux_write_register;
END PROCESS;
		

PROCESS (alu_mux_input1)
BEGIN
	alu_branch_input1 <= std_logic_vector(shift_left(unsigned(alu_mux_input1), 2));
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
			swriteregister_IDEX <= "00000";
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
			swriteregister_IDEX <= mux_write_register;
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
			sregdest_EXMEM <= '0';
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
		ELSE
			spc_EXMEM <= spc_IDEX;		
			--MIPS_CONTROL
			sregwrite_EXMEM <= sregwrite_IDEX;
			smemread_EXMEM <= smemread_IDEX;
			smemwrite_EXMEM <= smemwrite_IDEX;
			smemtoreg_EXMEM <= smemtoreg_IDEX;
			sbeq_EXMEM <= sbeq_IDEX;
			sbne_EXMEM <= sbne_IDEX;
			sregdest_EXMEM <= sregdest_IDEX;
			sjal_EXMEM <= sjal_IDEX;	
			sjump_EXMEM <= sjump_IDEX;	
			sel_mux_jump <= sjump_IDEX;
			
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
			swriteregister_EXMEM <= swriteregister_IDEX;
			
			mux_one <= sjumpaddress_EXMEM;			
			
		END IF;
	END IF;
END PROCESS;

--mem/wb
PROCESS (slow_clock)
BEGIN

	IF RISING_EDGE(slow_clock) THEN
		IF (reset_stages = '1') THEN									
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
		END IF;
	END IF;
	
END PROCESS;

PROCESS (mux_branch_sel,sjump_EXMEM)
BEGIN
	IF (mux_branch_sel = '1' OR sjump_EXMEM = '1') THEN
			reset_stages <= '1';
		ELSE
			reset_stages <= '0';
	END IF;
END PROCESS; 


pc_mips: PC PORT MAP  (
								clock => slow_clock, reset => local_reset, pc_output => pc_counter, 
								pc_input => mux_pc_input--mux_jump_output
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

mux_reg_file : mux PORT MAP ( input0 => sinstruction_IFID(20 DOWNTO 16), input1 => sinstruction_IFID(15 DOWNTO 11),
													 sel => regdest, output => regdestmux
											      );

mux_alu : mux32 PORT MAP ( input0 => sreaddata2_IDEX, input1 => ssignextend_IDEX,
													 sel => salusrc_IDEX, output => alu_oper2 
											      );	

mux_memory : mux32 PORT MAP ( input0 => alu_result_internal, input1 => smemreaddata_MEMWB,
													 sel => smemtoreg_MEMWB, output => alu_memory_result 
											      );	
																										
mux_jump : mux32 PORT MAP ( input0 => mux_jump_input0, input1 => sjumpaddress_EXMEM,
													 sel => sjump_EXMEM, output => mux_jump_output 
											      );	

mux_branch : mux32 PORT MAP ( input0 => spc_EXMEM, input1 => mux_branch_input1,
													 sel => mux_branch_sel, output => mux_jump_input0 
											      );	

													
mux_writeregister : mux PORT MAP ( input0 => regdestmux, input1 => "11111",
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
												

alu_main : alu PORT MAP ( inputA => alu_input_a, inputB => alu_input_b, 
								  ALUControl => salucontrol_IDEX, shamt => sinstruction_IFID(10 DOWNTO 6),
								  ALU_Result => alu_result_internal, Zero => alu_zero
								  );												

alu_branch : alu PORT MAP ( inputA => pc_counter_input, inputB => alu_branch_input1, 
								  ALUControl => "0010", shamt => "00000",
								  ALU_Result => mux_branch_input1
								  );								  
								  
								  
mem : RAM PORT MAP ( clock => NOT slow_clock, address => salumainresult_EXMEM(7 DOWNTO 2), 
							data => read_data2_reg, rden => smemread_EXMEM, 
							wren => smemwrite_EXMEM, q => mux_memory_input1   
						  );	
								  								  
bne_and : andgate PORT MAP ( inputA => sbne_EXMEM, inputB => not alu_zero, output => branch_bne_input
									);								  

beq_and : andgate PORT MAP ( inputA => sbeq_EXMEM, inputB => alu_zero, output => branch_beq_input
									);
									
branch : orgate PORT MAP ( inputA => branch_bne_input, inputB => branch_beq_input, output => mux_branch_sel
								  );									
								  							  
--sregwrite_MEMWB <= sregwrite_EXMEM;	

							  
forward : forwarding PORT MAP ( fRegwrite_EXMEM => sregwrite_EXMEM, 
										  fRegwrite_MEMWB => sregwrite_MEMWB, 
										  fRead_data1_in => sreaddata1_IDEX, 
										  fRead_data2_in => sreaddata2_IDEX,
										  fALU_result_EXMEM => salumainresult_EXMEM, 
										  freg_writedata_MEMWB => alu_memory_result,
										  fWrite_reg_EXMEM => swriteregister_EXMEM, 
										  fWrite_reg_MEMWB => swriteregister_MEMWB,
										  fRS_IDEX => sreadreg1_IDEX, 
										  fRT_IDEX => sreadreg2_IDEX,
										  fRead_data1_out => alu_input_a, 
										  fRead_data2_out => alu_input_b
										);							 
		
END behavior;