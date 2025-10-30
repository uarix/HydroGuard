
module font_ufm (
	addr,
	data_valid,
	dataout,
	nbusy,
	nread);	

	input	[8:0]	addr;
	output		data_valid;
	output	[15:0]	dataout;
	output		nbusy;
	input		nread;
endmodule
