--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
--|
--| ALU OPCODES:
--|
--|     ADD     000
--|     SUB     001
--|     L SHIFT 010
--|     R SHIFT 011
--|     OR      100
--|     AND     101
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
-- TODO
    port (
        --inputs
        i_A : in std_logic_vector(7 downto 0);
        i_B : in std_logic_vector(7 downto 0);
        i_op : in std_logic_vector(2 downto 0);
        i_cycle : in std_logic_vector(3 downto 0);
        
        --outputs
        o_result : out std_logic_vector(7 downto 0);
        o_flags : out std_logic_vector(2 downto 0)
    );
end ALU;

architecture behavioral of ALU is 
  
	-- declare components and signals
    signal w_result : std_logic_vector(7 downto 0) := "00000000";
    signal w_flags : std_logic_vector(2 downto 0) := "000";
  
begin
	-- PORT MAPS ----------------------------------------
	process(i_A, i_B, i_op)
	    variable temp : std_logic_vector(8 downto 0);
        begin
           case i_op is
               when "000" => --add
                   temp := std_logic_vector(unsigned('0' & i_A) + unsigned('0' & i_B));
                   w_result <= temp(7 downto 0);
                   
                   if temp(8) = '1' then
                       w_flags(1) <= '1';
                   else
                       w_flags(1) <= '0';
                   end if;
                   
                   if w_result = "00000000" then
                       w_flags(0) <= '1';
                   else
                       w_flags(0) <= '0';
                   end if;

               when "001" => --sub
                   w_flags <= "000";
                   temp := std_logic_vector(unsigned('0' & i_A) - unsigned('0' & i_B));
                   w_result <= temp(7 downto 0);
                   
                   if unsigned(i_A) < unsigned(i_B) then
                       w_flags(2) <= '1';
                   else 
                       w_flags(2) <= '0';
                   end if;
                   
                   if w_result = "00000000" then
                       w_flags(0) <= '1';
                   else 
                       w_flags(0) <= '0';
                   end if;
                   
               when "010" => -- left shift  
                   w_result <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned(i_B))));
                   
               when "011" => -- right shift
                   w_result <= std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned(i_B))));
                   
               when "100" => --or
                   w_result <= std_logic_vector(unsigned(i_A) or unsigned(i_B));
                   
               when "101" => --and
                   w_result <= std_logic_vector(unsigned(i_A) and unsigned(i_B));
                   
               when others =>
                   w_result <= (others => '0');
                               
           end case;
    end process;
		
	
	-- CONCURRENT STATEMENTS ----------------------------
	o_result <= w_result;
	o_flags(0) <= w_flags(0) when i_cycle = "1000" else '0';
	o_flags(1) <= w_flags(1);
	o_flags(2) <= w_flags(2);
	
	

end behavioral;
