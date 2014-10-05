library ieee;
use ieee.std_logic_1164.all;

entity single_cycle_cpu is --contains controller, datapath with data memory, instruction fetch unit with program memory
port
(
	clk,rst : in std_logic;
	address_prog,data_memory_input,address_data : out std_logic_vector(31 downto 0);
	MemWr : out std_logic;--controller output signals to memory
	instruction,data_memory_output : in std_logic_vector(31 downto 0);
	byteena : out std_logic_vector(3 downto 0)
);
end single_cycle_cpu;

architecture arch of single_cycle_cpu is

signal branch,jump,z,RegDst,ExtOp,ALUSrc,MemtoReg,RegWr,shdir : std_logic;
signal ALUctr : std_logic_vector(3 downto 0);

signal pc : std_logic_vector(29 downto 0);
signal JumpReg : std_logic;
signal busA : std_logic_vector(31 downto 0);
signal z_controller : std_logic;
signal JAL : std_logic;
signal LUI : std_logic;
	
begin		
	MIPS_INSTRUCTION_FETCH: entity work.instruction_fetch_unit
	port map
	(
		 clk         => clk,
	     rst         => rst,
	     branch      => branch,
	     jump        => jump,
	     JumpReg	 => JumpReg,
	     z           => z_controller, --possibly notted z
	     instruction => instruction,
	     busA		 => busA,
	     pc          => pc
	);
	MIPS_DATAPATH: entity work.single_cycle_datapath
	port map
	(
		 clk         => clk,
	     rst         => rst,
	     RegDst      => RegDst,
	     ExtOp       => ExtOp,
	     ALUSrc      => ALUSrc,
	     MemtoReg    => MemtoReg,
	     RegWr       => RegWr,
	     shdir       => shdir,
	     ALUctr      => ALUctr,
	     JAL		 => JAL,
	     LUI		 => LUI,
	     PC			 => PC,
	     instruction => instruction,
	     z           => z,
	     busA_out	 => busA,
	     data_address_out     => address_data,
	     data_memory_input => data_memory_input,
	     data_memory_output => data_memory_output
	);
	
	MIPS_CONTROLLER: entity work.single_cycle_controller
	port map
	(
		 instruction => instruction,
	     RegDst      => RegDst,
	     ExtOp       => ExtOp,
	     ALUSrc      => ALUSrc,
	     MemtoReg    => MemtoReg,
	     RegWr       => RegWr,
	     shdir       => shdir,
	     MemWr       => MemWr,
	     ALUctr      => ALUctr,
	     byteena	 => byteena,
	     branch		 => branch,
	     jump		 => jump,
	     JumpReg	 => JumpReg,
	     JAL		 => JAL,
	     LUI		 => LUI,
	     z			 => z, --is notted if BNE instead of BEQ
	     z_controller => z_controller
     );
	
	address_prog <= pc & "00";
end architecture arch;
