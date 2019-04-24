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
			Write_data_out          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END mips_processor;

ARCHITECTURE behavior OF mips_processor IS

SIGNAL pc_counter, pc_counter_input, instruction, alu_mux_input1 : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL read_data1_reg, read_data2_reg, alu_oper1, alu_oper2 : STD_LOGIC_VECTOR (31 DOWNTO 0); 
SIGNAL temp_calc, mux_branch_input1, mux_jump_input0, mux_pc_input, alu_branch_input1 : STD_LOGIC_VECTOR (31 DOWNTO 0); 
SIGNAL alu_result_internal, alu_memory_result, mux_memory_input1, write_data_input : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL jump_address, mux_jump_output : STD_LOGIC_VECTOR (31 DOWNTO 0);

SIGNAL regwrite_signal, regdest, alu_src, mem_to_reg, bne_control, beq_control, alu_zero, jal_control, jr_control : STD_LOGIC; 
SIGNAL mem_read, mem_write, jump_control, mux_branch_sel, branch_bne_input, branch_beq_input, local_reset, debug_reset: STD_LOGIC;

SIGNAL regdestmux, mux_write_register, read_reg1_input : STD_LOGIC_VECTOR (4 DOWNTO 0);

SIGNAL alu_control                    : STD_LOGIC_VECTOR (3 DOWNTO 0);
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
	--pc_counter_input <= pc_counter;
END PROCESS;

PROCESS (sinstruction_IFID)
BEGIN
	jump_address <= spc_IFID + (instruction(25 DOWNTO 0)&"00");	
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
PROCESS (clock)
BEGIN
	sinstruction_IFID <= instruction,
	spc_IFID <= pc_counter_input --mapped
END PROCESS;

--id/ex
PROCESS (clock)
BEGIN
	spc_IDEX <= spc_IFID,	
	--MIPS_CONTROL
	sregwrite_IDEX <= regwrite_signal,
	sregdest_IDEX <= regdest,
	salusrc_IDEX <= alu_src,
	salucontrol_IDEX <= alu_control,
	smemtoreg_IDEX <= mem_to_reg,
	sjal_IDEX <= jal_control,
	smemread_IDEX <= mem_read,
	smemwrite_IDEX <= mem_write,
	sjump_IDEX <= jump_control,
	sbeq_IDEX <= beq_control,
	sbne_IDEX <= bne_control,
	sjr_IDEX <= jr_control,
	--register_file
	sreaddata1_IDEX <= read_data1_reg,
	sreaddata2_IDEX <= read_data2_reg,
	--signextend
	ssignextend_IDEX <= alu_mux_input1,
	spc_IDEX <= spc_IFID,
	spc_IDEX <= spc_IFID,
	sjumpaddress_IDEX <= jump_address
	
END PROCESS;

--ex/mem
PROCESS (clock)
BEGIN
	spc_EXMEM <= spc_IDEX,	
	
	--MIPS_CONTROL
	sregwrite_EXMEM <= sregwrite_IDEX,
	smemread_EXMEM <= smemread_IDEX,
	smemwrite_EXMEM <= smemwrite_IDEX,
	smemtoreg_EXMEM <= smemtoreg_IDEX,
	sbeq_EXMEM <= sbeq_IDEX,
	sbne_EXMEM <= sbne_IDEX,
	sregdest_EXMEM <= sregdest_IDEX,
	sjal_EXMEM <= sjal_IDEX,	
	sjump_EXMEM <= sjump_IDEX,	
	sjr_EXMEM <= sjr_IDEX,
	--register_file
	sreaddata2_EXMEM <= sreaddata2_IDEX,
	
	
	--Stoped here
	--ALU branch
	slaubranchresult_EXMEM <= ???,
	--ALU Main
	salumainresult_EXMEM <= alu_result_internal,
	--szero_EXMEM <= ?????
	
	sjumpaddress_EXMEM <= sjumpaddress_IDEX
	
	
END PROCESS;

--mem/wb
PROCESS (clock)
BEGIN
	spc_MEMWB <= spc_EXMEM,
	
	--MIPS_CONTROL
	sregwrite_MEMWB <= sregwrite_EXMEM,	
	smemtoreg_MEMWB <= smemtoreg_EXMEM,
	sjal_MEMWB <= sjal_EXMEM
	
	
		
	--ALU Main
	salumainresult_MEMWB <= salumainresult_EXMEM	
	smemreaddata_MEMWB <= ?????
	
END PROCESS;




pc_mips: PC PORT MAP  (
								clock => slow_clock, reset => local_reset, pc_output => pc_counter, 
								pc_input => mux_pc_input--mux_jump_output
					  );

--Mapped output to if/id stage
rom    : ROMVHDL PORT MAP (
								clock => fast_clock, address => pc_counter(7 DOWNTO 2), q => instruction
							 );

control: MIPS_CONTROL PORT MAP ( opcode => sinstruction_IFID(31 DOWNTO 26), funct => sinstruction_IFID(5 DOWNTO 0),
											RegWrite => regwrite_signal, RegDst => regdest, ALUSrc => alu_src, 
											ALUControl => alu_control, MemtoReg => mem_to_reg, Jal => jal_control,
											MemRead => mem_read, MemWrite => mem_write, Jump => jump_control,
											Beq => beq_control, Bne => bne_control, Jr => jr_control								
							  );							 
			
--Jal, Jr		: OUT STD_LOGIC;

							  
reg_file : register_file PORT MAP (	clock => slow_clock, reset => local_reset, RegWrite => sregwrite_MEMWB,
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

mux_memory : mux32 PORT MAP ( input0 => alu_result_internal, input1 => mux_memory_input1,
													 sel => smemtoreg_MEMWB, output => alu_memory_result 
											      );	
																										
mux_jump : mux32 PORT MAP ( input0 => mux_jump_input0, input1 => jump_address,
													 sel => jump_control, output => mux_jump_output 
											      );	

mux_branch : mux32 PORT MAP ( input0 => spc_IDEX, input1 => mux_branch_input1,
													 sel => mux_branch_sel, output => mux_jump_input0 
											      );	

													
mux_writeregister : mux PORT MAP ( input0 => regdestmux, input1 => "11111",
													 sel => sjal_MEMWB, output => mux_write_register 
											      );	
													
													
mux_jr : mux32 PORT MAP ( input0 => mux_jump_output, input1 => sreaddata1_IDEX,
													 sel => sjr_IDEX, output => mux_pc_input 
											      );														


mux_jal : mux32 PORT MAP ( input0 => alu_memory_result, input1 => spc_MEMWB,
													 sel => sjal_MEMWB, output => write_data_input 
											     );	

													
sign_extend : signextend PORT MAP ( input => sinstruction_IFID(15 DOWNTO 0), output => alu_mux_input1
											  );
												

alu_main : alu PORT MAP ( inputA => sreaddata1_IDEX, inputB => alu_oper2, 
								  ALUControl => salucontrol_IDEX, shamt => sinstruction_IFID(10 DOWNTO 6),
								  ALU_Result => alu_result_internal, Zero => alu_zero
								  );												

alu_branch : alu PORT MAP ( inputA => pc_counter_input, inputB => alu_branch_input1, 
								  ALUControl => "0010", shamt => "00000",
								  ALU_Result => mux_branch_input1
								  );								  
								  
								  
mem : RAM PORT MAP ( clock => fast_clock, address => salumainresult_EXMEM(7 DOWNTO 2), 
							data => read_data2_reg, rden => smemread_EXMEM, 
							wren => smemwrite_EXMEM, q => mux_memory_input1   
						  );	
								  								  
bne_and : andgate PORT MAP ( inputA => sbne_EXMEM, inputB => not alu_zero, output => branch_bne_input
									);								  

beq_and : andgate PORT MAP ( inputA => sbeq_EXMEM, inputB => alu_zero, output => branch_beq_input
									);
									
branch : orgate PORT MAP ( inputA => branch_bne_input, inputB => branch_beq_input, output => mux_branch_sel
								  );									

							 
								
END behavior;