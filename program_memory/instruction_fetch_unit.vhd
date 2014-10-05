library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_fetch_unit is
port
(
	clk,rst : in std_logic;
	branch,jump,JumpReg : in std_logic;  --controller signals
	z : in std_logic; --alu signals
	instruction,busA : in std_logic_vector(31 downto 0); --instruction signal, busA from ALU (RS selects this)
	pc : out std_logic_vector(29 downto 0) --this is to be connected to the instruction memory
);
end instruction_fetch_unit;

architecture arch of instruction_fetch_unit is

signal pc_next,pc_add_b,pc_branch_inc,pc_jump : std_logic_vector(29 downto 0); --current PC, next pc, branch offset input of PC, PC as result of inc (and possible branch), pc as result of jump

signal imm_30, pc_internal : std_logic_vector(29 downto 0); --sign extended 32 bit value of immediate

begin
	process(clk,rst)
	begin
		if(rst = '1') then
			pc_internal <= "00" & x"0400000"; --pc_internal reset value
		elsif(falling_edge(clk)) then
			pc_internal <= pc_next;
		end if;
	end process;
	
	immediate_extender: entity work.signext --sign extender for the immediate value
	generic map
	(
		WIDTH_IN => 16,
		WIDTH_OUT => 30
	)
	port map
	(
		in0  => instruction(15 downto 0),
		out0 => imm_30
	);
	
	with (branch and z) select --MUX selecting to add immediate value or zero, going to adder 
		pc_add_b <= imm_30 when '1',
					(others => '0') when others;
					
	address_adder: entity work.adder_gen --next address adder, takes into account possible branch from previous mux
	generic map
	(
		WIDTH => 30
	)
	port map
	(
		 a      => PC_internal,
	     b      => pc_add_b,
	     cin    => '1',
	     output => pc_branch_inc
	);
	
	with JumpReg select --mux in front of jump mux selecting either low instruction bits and upper PC bits or register jump
		pc_jump <= pc_internal(29 downto 26) & instruction(25 downto 0) when '0',
				   busA(31 downto 2) when others;
	
	with jump select --finally if this is a jump, use the bottom 26 bits in instruction and the upper 4 bits of pc_internal to jump, otherwise use branch/inc value
		pc_next <= pc_branch_inc when '0',
				   pc_jump when others;
				   
	pc <= pc_internal; --put pc value to output port
end architecture arch;
