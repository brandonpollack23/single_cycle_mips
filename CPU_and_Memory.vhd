library ieee;
use ieee.std_logic_1164.all;

entity CPU_and_Memory is
port
(
	mem_clk,rst : std_logic
);
end CPU_and_Memory;

architecture arch of CPU_and_Memory is

signal clk,MemWr : std_logic;

signal address_prog,address_data,instruction : std_logic_vector(31 downto 0);
signal data_from_CPU_to_Memory : std_logic_vector(31 downto 0);
signal data_from_Memory_to_CPU : std_logic_vector(31 downto 0);
signal byteena : std_logic_vector(3 downto 0);

begin
	process(mem_clk, rst) is --clk generation
	begin
		if(rst = '1') then
			clk <= '0';
		elsif(rising_edge(mem_clk)) then
			clk <= not clk;
		end if;
	end process;
	
	MIPS_CPU: entity work.single_cycle_cpu
	port map
	(
		 clk          => clk,
	     rst          => rst,
	     address_prog => address_prog,
	     data_memory_input     => data_from_CPU_to_Memory,
	     data_memory_output	  => data_from_Memory_to_CPU,
	     address_data => address_data,
	     MemWr        => MemWr,
	     byteena	  => byteena,
	     instruction  => instruction
	);
	
	MEMORY_BLOCK: entity work.memory_unit
	port map
	(
		 mem_clk      => mem_clk,
	     address_prog => address_prog,
	     address_data => address_data,
	     data_in      => data_from_CPU_to_Memory,
	     data_out     => data_from_Memory_to_CPU,
	     instruction  => instruction,
	     byteena      => byteena,
	     MemWr        => MemWr
	);
	
end architecture arch;