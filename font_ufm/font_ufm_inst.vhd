	component font_ufm is
		port (
			addr       : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- addr
			data_valid : out std_logic;                                        -- data_valid
			dataout    : out std_logic_vector(15 downto 0);                    -- dataout
			nbusy      : out std_logic;                                        -- nbusy
			nread      : in  std_logic                     := 'X'              -- nread
		);
	end component font_ufm;

	u0 : component font_ufm
		port map (
			addr       => CONNECTED_TO_addr,       --       addr.addr
			data_valid => CONNECTED_TO_data_valid, -- data_valid.data_valid
			dataout    => CONNECTED_TO_dataout,    --    dataout.dataout
			nbusy      => CONNECTED_TO_nbusy,      --      nbusy.nbusy
			nread      => CONNECTED_TO_nread       --      nread.nread
		);

