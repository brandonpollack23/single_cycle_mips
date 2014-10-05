library ieee;
use ieee.std_logic_1164.all;

entity single_cycle_datapath is
port
(
	clk,rst : in std_logic;
	RegDst,ExtOp,ALUSrc,MemtoReg,RegWr,shdir,JAL,LUI : in std_logic; --signals from controller
	ALUctr : in std_logic_vector(3 downto 0);
	instruction : in std_logic_vector(31 downto 0); --signal from instruction fetch unit and PC for JAL operation
	pc : in std_logic_vector(29 downto 0);
	z : out std_logic; --signal to instruction fetch unit
	data_address_out,data_memory_input,busA_out : out std_logic_vector(31 downto 0);
	data_memory_output : in std_logic_vector(31 downto 0)
);
end single_cycle_datapath;

architecture arch of single_cycle_datapath is

signal busB,busB_mux,imm32 : std_logic_vector(31 downto 0);

signal rs,rt,rw,rd,rd_pc_mux : std_logic_vector(4 downto 0); --Opcode Signals, rs is ra, rt is rb
signal shamt : std_logic_vector(4 downto 0);
signal immediate : std_logic_vector(15 downto 0);

signal busW : std_logic_vector(31 downto 0);

signal ALUout : std_logic_vector(31 downto 0);
--signal WriteBack : std_logic_vector(31 downto 0);
signal WriteBackSelect : std_logic_vector(2 downto 0);
signal busA : std_logic_vector(31 downto 0);
	
begin
	with JAL select --when JAL is true, write to register $31 the current address
		rd_pc_mux <= rd when '0',
					 "11111" when others;
					 
	with RegDst select --determine which is rw depending on controller output
		rw <= rt when '0',
			  rd_pc_mux when others;
	
	register_file: entity work.registerFile --register file
	generic map
	(
		WIDTH        => 32,
        NUMREGISTERS => 32
    )
	port map
	(	
		 rr0 => rs,
	     rr1 => rt,
	     rw  => rw,
	     q0  => busA,
	     q1  => busB,
	     d   => busW,
	     wr  => RegWr,
	     clk => clk,
	     clr => rst
	);
	
	immediate_extender_alu: entity work.extender --extender, ExtOp is true for loads and stores (signed), 0 for or immediate(unsigned), im not sure for And immediate
	port map
	(
		 in0  => immediate,
	     out0 => imm32,
	     sel  => ExtOp
	);
	
	with ALUsrc select --BUS B mux for immediate instruction select mux
		busB_mux <= busB when '0',
					imm32 when others;
		
	MIPS_ALU: entity work.alu32 --ALU
	generic map
	(
		WIDTH => 32
	)
	port map
	(
		 ia      => busA,
	     ib      => busB_mux,
	     control => ALUctr,
	     shamt   => shamt,
	     shdir   => shdir,
	     o 		 => ALUout,
	     z       => z
	);
	
	WriteBackSelect <= LUI & JAL & MemtoReg; --writeback select lines
	
	with WriteBackSelect select --write back select mux, combines all possible register write back values
		BusW <= immediate & x"0000" when "100", --load upper immediate
				PC & "00" when "010", --pc for JAL
				data_memory_output when "001", --data memory for loads
				ALUout when others; --ALUout otherwise				
	
--	with MemtoReg select --register write back mux, writeback is from memory or ALU result
--		WriteBack <= ALUout when '0',
--					 data_memory_output when others;
--				
--	with JAL select --JAL select mux, PC is program counter value for JAL
--		BusW <= WriteBack when '0',
--				PC & "00" when others;

	rs <= instruction(25 downto 21); --breakdown of instruction
	rt <= instruction(20 downto 16);
	rd <= instruction(15 downto 11);	
	shamt <= instruction(10 downto 6);
	immediate <= instruction(15 downto 0);	
	
	data_address_out <= ALUout;
	data_memory_input <= busB;
	busA_out <= busA;
end architecture arch;
