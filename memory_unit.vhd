library ieee;
use ieee.std_logic_1164.all;

entity memory_unit is
port
(
	mem_clk : in std_logic;
	address_prog,address_data,data_in : in std_logic_vector(31 downto 0);
	data_out, instruction : out std_logic_vector(31 downto 0);	
	byteena : in std_logic_vector(3 downto 0);--controller signals
	MemWr : in std_logic
);
end memory_unit;

architecture arch of memory_unit is

signal data_mem_en,prog_mem_en : std_logic;	

begin
	process(address_prog,address_data) --memory mapping
	begin
		if(address_prog >= x"00400000") then
			prog_mem_en <= '1';
		else
			prog_mem_en <= '0';
		end if;
		
		if(address_data >= x"10000000") then
			data_mem_en <= '1';
		else
			data_mem_en <= '0';
		end if;
	end process;
	
	data_mem8bit: entity work.data_memory
	port map
	(
		 address => address_data(7 downto 0),
	     byteena => byteena,
	     clock   => mem_clk,
	     data    => data_in,
	     rden    => data_mem_en,
	     wren    => MemWr,
	     q       => data_out
	);
	
	prog_mem8bit: entity work.prog_mem
	port map
	(
		 address => address_prog(7 downto 0),
	     clock   => mem_clk,
	     data    => (others => '0'), --can make program memory writable?
	     rden    => prog_mem_en,
	     wren    => '0',
	     q       => instruction
	);
	
end architecture arch;
