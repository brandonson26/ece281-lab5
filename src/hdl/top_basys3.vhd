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
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
-- TODO
    port (
        --inputs
        clk : in std_logic;
        btnU : in std_logic;
        btnC : in std_logic;
        sw : in std_logic_vector(7 downto 0);
        
        --outputs
        led : out std_logic_vector(15 downto 0);
        seg : out std_logic_vector(6 downto 0);
        an : out std_logic_vector(3 downto 0)
    
    );
    
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	--declare components	
	component regA is
        port ( 
            i_A : in std_logic_vector(7 downto 0);
            i_cycle : in std_logic;
            o_A : out std_logic_vector(7 downto 0)
        );
    end component regA;
    
    component regB is
        port ( 
            i_B : in std_logic_vector(7 downto 0);
            i_cycle : in std_logic;
            o_B : out std_logic_vector(7 downto 0)
        );
    end component regB;
	
	component controller_fsm is
        port (
            i_clk : in std_logic;
            i_reset : in std_logic;
            i_adv : in std_logic;
            o_cycle : out std_logic_vector(3 downto 0)
        );
    end component controller_fsm;
	
    component ALU is
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
    end component ALU;
    
    component twoscomp_decimal is
        port (
            i_binary: in std_logic_vector(7 downto 0);
            o_negative: out std_logic_vector(3 downto 0);
            o_hundreds: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twoscomp_decimal;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        port ( i_clk        : in  STD_LOGIC;
               i_reset        : in  STD_LOGIC; -- asynchronous
               i_D3         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data        : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel        : out STD_LOGIC_VECTOR (3 downto 0)    -- selected data line (one-cold)
        );
    end component TDM4;
    
    component sevenSegDecoder is
        port ( i_D : in STD_LOGIC_VECTOR (3 downto 0);
               o_S : out STD_LOGIC_VECTOR (6 downto 0));
    end component sevenSegDecoder;
    
    component clock_divider_controller is
        generic ( constant k_DIV : natural := 2);
        port (i_clk : in std_logic;
              i_reset  : in std_logic; -- asynchronous
              o_clk    : out std_logic
        );
    end component clock_divider_controller;
    
    component clock_divider_TDM is
        generic ( constant k_DIV : natural := 2    );
        port (     i_clk    : in std_logic;
                i_reset  : in std_logic; -- asynchronous
                o_clk    : out std_logic 
        );
    end component clock_divider_TDM;
 
    
    --declare signals
    signal w_clk_controller, w_clk_TDM : std_logic;
    
    signal w_flags : std_logic_vector(2 downto 0);
    
    signal w_seg : std_logic_vector(6 downto 0);
    
    signal w_result, w_A, w_B, w_bin : std_logic_vector(7 downto 0);
    
    signal w_cycle, w_sign, w_hund, w_tens, w_ones, w_data, w_sel : std_logic_vector(3 downto 0);
  
begin
	-- PORT MAPS ----------------------------------------
	regA_inst : regA port map (
	   i_A => sw(7 downto 0),
	   i_cycle => w_cycle(1),
	   o_A => w_A
	);
	
	regB_inst : regB port map (
	   i_B => sw(7 downto 0),
	   i_cycle => w_cycle(2),
	   o_B => w_B
	);
	
	controller_fsm_inst : controller_fsm port map (
	   i_clk => clk,
	   i_reset => btnU,
	   i_adv => btnC,
	   o_cycle => w_cycle
	);
	
    ALU_inst : ALU port map (
        i_A => w_A,
        i_B => w_B,
        i_op => sw(2 downto 0),
        i_cycle => w_cycle,
        o_result => w_result,
        o_flags => w_flags

    );
    
    twoscomp_decimal_inst: twoscomp_decimal port map (
        i_binary => w_bin,
        o_negative => w_sign,
        o_hundreds => w_hund,
        o_tens => w_tens,
        o_ones => w_ones
    );
	
	TDM4_inst : TDM4 port map (
	   i_clk => w_clk_TDM,
	   i_reset => btnU,
	   i_D3 => w_sign,
	   i_D2 => w_hund,
	   i_D1 => w_tens,
	   i_D0 => w_ones,
	   o_data => w_data,
	   o_sel => w_sel
	);
	
	sevenSegDecoder_inst : sevenSegDecoder port map (
	   i_D => w_data,
	   o_S => w_seg
	);
	
	clock_divider_controller_inst : clock_divider_controller 
	generic map (k_div => 2000000)
	port map (
	   i_clk => clk,
	   i_reset => btnU,
	   o_clk => w_clk_controller
	);
	
	clock_divider_TDM_inst : clock_divider_TDM 
        generic map (k_div => 5000)
        port map (
           i_clk => clk,
           i_reset => btnU,
           o_clk => w_clk_TDM
        );
	
	 

	-- CONCURRENT STATEMENTS ----------------------------
	led(12 downto 4) <= (others => '0');
	led(3 downto 0) <= w_cycle;
	
	led(15) <= w_flags(0); -- zero
	led(14) <= w_flags(1); --carry
	led(13) <= w_flags(2); --negative

    w_bin <= w_A when w_cycle = "0010" else
             w_B when w_cycle = "0100" else
             w_result when w_cycle = "1000" else
             "00000000";

	an(3 downto 0) <= "1111" when w_cycle = "0001" else w_sel;	
	
	seg <= w_seg;
	--seg <= "0000001" when w_cycle = "1000" and w_sign = "0001" else w_seg;
	   
end top_basys3_arch;
