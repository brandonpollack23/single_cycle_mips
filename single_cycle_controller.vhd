library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity single_cycle_controller is
port
(
	instruction : in std_logic_vector(31 downto 0);
	RegDst,ExtOp,ALUSrc,MemtoReg,RegWr,shdir,MemWr,Branch,Jump,JumpReg,z_controller,JAL,LUI : out std_logic; --signals from controller
	ALUctr : out std_logic_vector(3 downto 0);
	byteena : out  std_logic_vector(3 downto 0);
	z : in std_logic
);
end single_cycle_controller;

architecture arch of single_cycle_controller is
	
signal func : std_logic_vector(5 downto 0);
signal ALUop : std_logic_vector(2 downto 0);
signal opcode : std_logic_vector(5 downto 0);
	
begin
	ALU32CONTROL : entity work.alu32control --ALUctr generation
	port map
	(
		 func    => func,
	     ALUop   => ALUop,
	     control => ALUctr
	);
	
	process(opcode,func,z)
	begin
		RegDst <= '1'; --default is Rd
		ExtOp <= 'X'; --dont care unless using extender
		ALUSrc <= '0'; --default busB is register, otherwise sign extended immediate value
		MemtoReg <= '0'; --default ALU result is writeback
		RegWr <= '1'; --default is write back value
		shdir <= 'X'; --only used during shifts
		MemWr <= '0'; --default reading from data memory
		Branch <= '0'; --default do not branch
		Jump <= '0'; --default do not jump
		JumpReg <= '0'; --default do not jump from register
		JAL <= '0';
		LUI <= '0';
		ALUop <= "XXX";
		z_controller <= z;
		
		byteena <= (others => '1'); --default reading word from data memory
		
		ALUop <= (others => '0');
		
		case opcode is
			
		when "000000" => --R type function, ALU32control will determine ALUctr from func
			ALUop <= "010"; --use func
			case func is
				
			when "001000" => --jump register
				Jump <= '1';
				JumpReg <= '1';
				RegWr <= '0';
				
			when "000000" => --shift left logical
				shdir <= '0'; --left
				
			when "000010" => --shift right logical
				shdir <= '1'; --right
				
			when others => --add,addu,and,nor,or,slt,sltu,sub,subu all use default values
				null;				
			end case;
			
		when "001000" => --add immediate signed
			ALUop <= "000"; --add
			ExtOp <= '1'; --signed extension
			ALUSrc <= '1'; --immediate value is second operand
			RegDst <= '0'; --t is destination for immediates
			
		when "001001" => --add immediate unsigned turns out it just doesn't execute a trap, which this CPU doesn't support
			ALUop <= "000"; --add
			ExtOp <= '0'; --signed extension
			ALUSrc <= '1'; --immediate value is second operand
			RegDst <= '0'; --t is destination for immediates
			
		when "001100" => --and immediate
			ALUop <= "011"; --and
			ExtOp <= '0'; --zero extension
			ALUSrc <= '1'; --immediate value is second operand
			RegDst <= '0'; --t is destination for immediates
			
		when "000100" => --beq
			ALUop <= "001"; --subtract
			Branch <= '1'; --branch if z is true, no need to not z
			RegWr <= '0'; --do not write back value
			
		when "000101" => --bne
			ALUop <= "001"; --subtract
			Branch <= '1'; --branch if z is false
			z_controller <= not z; --if z is false we'll branch
			RegWr <= '0'; --do not write back value
			
		when "000010" => --jump
			Jump <= '1';
			RegWr <= '0'; --do not write back value
			
		when "000011" => --jal
			Jump <= '1';
			JAL <= '1';
			
		when "100100" => --load byte unsigned
			ALUop <= "000"; --add to get address offset
			byteena <= "0001"; --only enable one byte from memory
			MemtoReg <= '1'; --result from memory not ALU
			ExtOp <= '1'; --signed extension on immediate value
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for loads
			
		when "100101" => --load halfword unsigned
			ALUop <= "000"; --add to get address offset
			byteena <= "0001"; --only enable 2 bytes from memory
			MemtoReg <= '1'; --result from memory not ALU
			ExtOp <= '1'; --signed extension on immediate value
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for loads
			
		when "001111" => --lui
			LUI <= '1'; --select immediate value to be written back with padded 16 lower half zeros, before sign extender
			RegDst <= '0'; --t is destination for loads
			
		when "100011" => --load word
			ALUop <= "000"; --add to get address offset, default byteena of 1111 is good
			MemtoReg <= '1'; --result from memory not ALU
			ExtOp <= '1'; --signed extension on immediate value
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for loads
			
		when "001101" => --or immediate
			ALUop <= "100"; --or
			ExtOp <= '0'; --zero extension
			ALUsrc <= '1'; --immediate value is second operand
			RegDst <= '0'; --t is destination for immediates
			
		when "001010" => --slti
			ALUop <= "101"; --slt
			ExtOp <= '1'; --signed comparison
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for immediates
			
		when "001011" => --sltiu
			ALUop <= "110"; --sltu
			ExtOp <= '0'; --unsigned comparison
			ALUsrc <= '1'; --immediate operand
			RegDst <= '0'; --t is destination for immediates
			
		when "101000" => --store byte
			ALUop <= "000"; --add to get address offset
			byteena <= "0001"; --only enable one byte to memory
			MemWr <= '1'; --write operation
			RegWr <= '0'; --do not writeback reg
			ExtOp <= '1'; --signed extension on immediate value
			
		when "101001" => --store halfword
			ALUop <= "000"; --add to get address offset
			byteena <= "0011"; --only enable 2 bytes to memory
			MemWr <= '1'; --write operation
			RegWr <= '0'; --do not writeback reg
			ExtOp <= '1'; --signed extension on immediate value
			
		when "101011" => --store word
			ALUop <= "000"; --add to get address offset, all bytes enabled
			MemWr <= '1'; --write operation
			RegWr <= '0'; --do not writeback reg
			ExtOp <= '1'; --signed extension on immediate value
			
		when others =>
			null;
		end case;		
	end process;
	
	
	func <= instruction(5 downto 0);
	opcode <= instruction(31 downto 26);	
end architecture arch;
