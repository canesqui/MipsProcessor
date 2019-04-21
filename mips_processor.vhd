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
	
	
PROCESS (pc_counter)
BEGIN
	pc_counter_input <= pc_counter + 4;
	PC_out <= pc_counter_input;
	--pc_counter_input <= pc_counter;
END PROCESS;

PROCESS (instruction)
BEGIN
	jump_address <= pc_counter_input + (instruction(25 DOWNTO 0)&"00");	
	instruction_out <= instruction;
	read_reg1_out <= instruction(25 DOWNTO 21);
	read_reg2_out <= instruction(20 DOWNTO 16);	
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

pc_mips: PC PORT MAP  (
								clock => slow_clock, reset => local_reset, pc_output => pc_counter, 
								pc_input => mux_pc_input--mux_jump_output
					  );


rom    : ROMVHDL PORT MAP (
								clock => fast_clock, address => pc_counter(7 DOWNTO 2), q => instruction
							 );

control: MIPS_CONTROL PORT MAP ( opcode => instruction(31 DOWNTO 26), funct => instruction(5 DOWNTO 0),
											RegWrite => regwrite_signal, RegDst => regdest, ALUSrc => alu_src, 
											ALUControl => alu_control, MemtoReg => mem_to_reg, Jal => jal_control,
											MemRead => mem_read, MemWrite => mem_write, Jump => jump_control,
											Beq => beq_control, Bne => bne_control, Jr => jr_control								
							  );							 
			
--Jal, Jr		: OUT STD_LOGIC;

							  
reg_file : register_file PORT MAP (	clock => slow_clock, reset => local_reset, RegWrite => regwrite_signal,
												read_reg1 => instruction(25 DOWNTO 21), read_reg2 => instruction(20 DOWNTO 16),
												write_reg => mux_write_register, read_data1 => read_data1_reg, read_data2 => read_data2_reg,
												write_data => write_data_input--alu_memory_result
											  );

mux_reg_file : mux PORT MAP ( input0 => instruction(20 DOWNTO 16), input1 => instruction(15 DOWNTO 11),
													 sel => regdest, output => regdestmux
											      );

mux_alu : mux32 PORT MAP ( input0 => read_data2_reg, input1 => alu_mux_input1,
													 sel => alu_src, output => alu_oper2 
											      );	

mux_memory : mux32 PORT MAP ( input0 => alu_result_internal, input1 => mux_memory_input1,
													 sel => mem_to_reg, output => alu_memory_result 
											      );	
																										
mux_jump : mux32 PORT MAP ( input0 => mux_jump_input0, input1 => jump_address,
													 sel => jump_control, output => mux_jump_output 
											      );	

mux_branch : mux32 PORT MAP ( input0 => pc_counter_input, input1 => mux_branch_input1,
													 sel => mux_branch_sel, output => mux_jump_input0 
											      );	

													
mux_writeregister : mux PORT MAP ( input0 => regdestmux, input1 => "11111",
													 sel => jal_control, output => mux_write_register 
											      );	
													
													
mux_jr : mux32 PORT MAP ( input0 => mux_jump_output, input1 => read_data1_reg,
													 sel => jr_control, output => mux_pc_input 
											      );														


mux_jal : mux32 PORT MAP ( input0 => alu_memory_result, input1 => pc_counter_input,
													 sel => jal_control, output => write_data_input 
											     );	

													
sign_extend : signextend PORT MAP ( input => instruction(15 DOWNTO 0), output => alu_mux_input1
											  );
												

alu_main : alu PORT MAP ( inputA => read_data1_reg, inputB => alu_oper2, 
								  ALUControl => alu_control, shamt => instruction(10 DOWNTO 6),
								  ALU_Result => alu_result_internal, Zero => alu_zero
								  );												

alu_branch : alu PORT MAP ( inputA => pc_counter_input, inputB => alu_branch_input1, 
								  ALUControl => "0010", shamt => "00000",
								  ALU_Result => mux_branch_input1
								  );								  
								  
								  
mem : RAM PORT MAP ( clock => fast_clock, address => alu_result_internal(7 DOWNTO 2), 
							data => read_data2_reg, rden => mem_read, 
							wren => mem_write, q => mux_memory_input1   
						  );	
								  								  
bne_and : andgate PORT MAP ( inputA => bne_control, inputB => not alu_zero, output => branch_bne_input
									);								  

beq_and : andgate PORT MAP ( inputA => beq_control, inputB => alu_zero, output => branch_beq_input
									);
									
branch : orgate PORT MAP ( inputA => branch_bne_input, inputB => branch_beq_input, output => mux_branch_sel
								  );									

							 
								
END behavior;