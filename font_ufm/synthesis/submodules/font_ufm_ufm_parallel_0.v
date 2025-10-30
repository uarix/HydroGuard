//altufm_parallel ACCESS_MODE="READ_ONLY" CBX_AUTO_BLACKBOX="ALL" CBX_SINGLE_OUTPUT_FILE="ON" DEVICE_FAMILY="MAX II" ERASE_TIME=500000000 LPM_FILE="E:/intelFPGA/Projects/HydroGuard/fusion-pixel-8px-monospaced-latin.mif" OSC_FREQUENCY=180000 PROGRAM_TIME=1600000 WIDTH_ADDRESS=9 WIDTH_DATA=16 WIDTH_UFM_ADDRESS=9 addr data_valid dataout nbusy nread
//VERSION_BEGIN 18.0 cbx_a_gray2bin 2018:04:24:18:04:18:SJ cbx_a_graycounter 2018:04:24:18:04:18:SJ cbx_altufm_parallel 2018:04:24:18:04:18:SJ cbx_cycloneii 2018:04:24:18:04:18:SJ cbx_lpm_add_sub 2018:04:24:18:04:18:SJ cbx_lpm_compare 2018:04:24:18:04:18:SJ cbx_lpm_counter 2018:04:24:18:04:18:SJ cbx_lpm_decode 2018:04:24:18:04:18:SJ cbx_lpm_mux 2018:04:24:18:04:18:SJ cbx_maxii 2018:04:24:18:04:18:SJ cbx_mgl 2018:04:24:18:08:49:SJ cbx_nadder 2018:04:24:18:04:18:SJ cbx_stratix 2018:04:24:18:04:18:SJ cbx_stratixii 2018:04:24:18:04:18:SJ cbx_util_mgl 2018:04:24:18:04:18:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2018  Intel Corporation. All rights reserved.
//  Your use of Intel Corporation's design tools, logic functions 
//  and other software and tools, and its AMPP partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Intel Program License 
//  Subscription Agreement, the Intel Quartus Prime License Agreement,
//  the Intel FPGA IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Intel and sold by Intel or its authorized distributors.  Please
//  refer to the applicable agreement for further details.



//synthesis_resources = lpm_counter 1 lut 62 maxii_ufm 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
(* ALTERA_ATTRIBUTE = {"suppress_da_rule_internal=c101;suppress_da_rule_internal=c103;suppress_da_rule_internal=c104;suppress_da_rule_internal=r101;suppress_da_rule_internal=s104;suppress_da_rule_internal=s102"} *)
module  font_ufm_ufm_parallel_0
	( 
	addr,
	data_valid,
	dataout,
	nbusy,
	nread) /* synthesis synthesis_clearbox=1 */;
	input   [8:0]  addr;
	output   data_valid;
	output   [15:0]  dataout;
	output   nbusy;
	input   nread;

	reg	[8:0]	A;
	reg	data_valid_out_reg;
	reg	data_valid_reg;
	reg	deco1_dffe;
	reg	decode_dffe;
	reg	gated_clk1_dffe;
	reg	gated_clk2_dffe;
	reg	real_decode2_dffe;
	reg	real_decode_dffe;
	reg	[15:0]	sipo_dffe;
	wire	[15:0]	wire_tmp_do_d;
	reg	[15:0]	tmp_do;
	wire	[15:0]	wire_tmp_do_ena;
	wire  [4:0]   wire_cntr2_q;
	wire  wire_maxii_ufm_block1_bgpbusy;
	wire  wire_maxii_ufm_block1_drdout;
	wire  wire_maxii_ufm_block1_osc;
	wire  add_en;
	wire  add_load;
	wire  arclk;
	wire  busy_arclk;
	wire  busy_drclk;
	wire  control_mux;
	wire  copy_tmp_decode;
	wire  data_valid_en;
	wire  dly_tmp_decode;
	wire  drdin;
	wire  gated1;
	wire  gated2;
	wire  hold_decode;
	wire  in_read_data_en;
	wire  in_read_drclk;
	wire  in_read_drshft;
	wire  mux_nread;
	wire oscena;
	wire  q0;
	wire  q1;
	wire  q2;
	wire  q3;
	wire  q4;
	wire  read;
	wire  read_op;
	wire  real_decode;
	wire  [8:0]  shiftin;
	wire  [15:0]  sipo_q;
	wire  start_decode;
	wire  start_op;
	wire  stop_op;
	wire  tmp_add_en;
	wire  tmp_add_load;
	wire  tmp_arclk;
	wire  tmp_arclk0;
	wire  tmp_ardin;
	wire  tmp_arshft;
	wire  tmp_data_valid2;
	wire  tmp_decode;
	wire  tmp_drclk;
	wire  tmp_in_read_data_en;
	wire  tmp_in_read_drclk;
	wire  tmp_in_read_drshft;
	wire  tmp_read;
	wire  ufm_arclk;
	wire  ufm_ardin;
	wire  ufm_arshft;
	wire  ufm_bgpbusy;
	wire  ufm_drclk;
	wire  ufm_drdin;
	wire  ufm_drdout;
	wire  ufm_drshft;
	wire  ufm_osc;
	wire  ufm_oscena;
	wire  [8:0]  X_var;
	wire  [8:0]  Y_var;
	wire  [8:0]  Z_var;

	// synopsys translate_off
	initial
		A = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (add_en == 1'b1)   A <= {Z_var};
	// synopsys translate_off
	initial
		data_valid_out_reg = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		  data_valid_out_reg <= (data_valid_reg & (~ tmp_decode));
	// synopsys translate_off
	initial
		data_valid_reg = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (data_valid_en == 1'b1)   data_valid_reg <= tmp_data_valid2;
	// synopsys translate_off
	initial
		deco1_dffe = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (start_op == 1'b1)   deco1_dffe <= mux_nread;
	// synopsys translate_off
	initial
		decode_dffe = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		  decode_dffe <= copy_tmp_decode;
	// synopsys translate_off
	initial
		gated_clk1_dffe = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		  gated_clk1_dffe <= busy_arclk;
	// synopsys translate_off
	initial
		gated_clk2_dffe = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		  gated_clk2_dffe <= busy_drclk;
	// synopsys translate_off
	initial
		real_decode2_dffe = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		  real_decode2_dffe <= real_decode_dffe;
	// synopsys translate_off
	initial
		real_decode_dffe = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		  real_decode_dffe <= start_decode;
	// synopsys translate_off
	initial
		sipo_dffe = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (in_read_data_en == 1'b1)   sipo_dffe <= {sipo_q[14:0], ufm_drdout};
	// synopsys translate_off
	initial
		tmp_do[0:0] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[0:0] == 1'b1)   tmp_do[0:0] <= wire_tmp_do_d[0:0];
	// synopsys translate_off
	initial
		tmp_do[1:1] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[1:1] == 1'b1)   tmp_do[1:1] <= wire_tmp_do_d[1:1];
	// synopsys translate_off
	initial
		tmp_do[2:2] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[2:2] == 1'b1)   tmp_do[2:2] <= wire_tmp_do_d[2:2];
	// synopsys translate_off
	initial
		tmp_do[3:3] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[3:3] == 1'b1)   tmp_do[3:3] <= wire_tmp_do_d[3:3];
	// synopsys translate_off
	initial
		tmp_do[4:4] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[4:4] == 1'b1)   tmp_do[4:4] <= wire_tmp_do_d[4:4];
	// synopsys translate_off
	initial
		tmp_do[5:5] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[5:5] == 1'b1)   tmp_do[5:5] <= wire_tmp_do_d[5:5];
	// synopsys translate_off
	initial
		tmp_do[6:6] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[6:6] == 1'b1)   tmp_do[6:6] <= wire_tmp_do_d[6:6];
	// synopsys translate_off
	initial
		tmp_do[7:7] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[7:7] == 1'b1)   tmp_do[7:7] <= wire_tmp_do_d[7:7];
	// synopsys translate_off
	initial
		tmp_do[8:8] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[8:8] == 1'b1)   tmp_do[8:8] <= wire_tmp_do_d[8:8];
	// synopsys translate_off
	initial
		tmp_do[9:9] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[9:9] == 1'b1)   tmp_do[9:9] <= wire_tmp_do_d[9:9];
	// synopsys translate_off
	initial
		tmp_do[10:10] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[10:10] == 1'b1)   tmp_do[10:10] <= wire_tmp_do_d[10:10];
	// synopsys translate_off
	initial
		tmp_do[11:11] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[11:11] == 1'b1)   tmp_do[11:11] <= wire_tmp_do_d[11:11];
	// synopsys translate_off
	initial
		tmp_do[12:12] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[12:12] == 1'b1)   tmp_do[12:12] <= wire_tmp_do_d[12:12];
	// synopsys translate_off
	initial
		tmp_do[13:13] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[13:13] == 1'b1)   tmp_do[13:13] <= wire_tmp_do_d[13:13];
	// synopsys translate_off
	initial
		tmp_do[14:14] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[14:14] == 1'b1)   tmp_do[14:14] <= wire_tmp_do_d[14:14];
	// synopsys translate_off
	initial
		tmp_do[15:15] = 0;
	// synopsys translate_on
	always @ ( posedge ufm_osc)
		if (wire_tmp_do_ena[15:15] == 1'b1)   tmp_do[15:15] <= wire_tmp_do_d[15:15];
	assign
		wire_tmp_do_d = {sipo_q[15:0]};
	assign
		wire_tmp_do_ena = {16{(data_valid_reg & (~ tmp_decode))}};
	lpm_counter   cntr2
	( 
	.clk_en(tmp_decode),
	.clock(ufm_osc),
	.cout(),
	.eq(),
	.q(wire_cntr2_q)
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_off
	`endif
	,
	.aclr(1'b0),
	.aload(1'b0),
	.aset(1'b0),
	.cin(1'b1),
	.cnt_en(1'b1),
	.data({5{1'b0}}),
	.sclr(1'b0),
	.sload(1'b0),
	.sset(1'b0),
	.updown(1'b1)
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_on
	`endif
	);
	defparam
		cntr2.lpm_direction = "UP",
		cntr2.lpm_modulus = 28,
		cntr2.lpm_port_updown = "PORT_UNUSED",
		cntr2.lpm_width = 5,
		cntr2.lpm_type = "lpm_counter";
	maxii_ufm   maxii_ufm_block1
	( 
	.arclk(ufm_arclk),
	.ardin(ufm_ardin),
	.arshft(ufm_arshft),
	.bgpbusy(wire_maxii_ufm_block1_bgpbusy),
	.busy(),
	.drclk(ufm_drclk),
	.drdin(ufm_drdin),
	.drdout(wire_maxii_ufm_block1_drdout),
	.drshft(ufm_drshft),
	.osc(wire_maxii_ufm_block1_osc),
	.oscena(ufm_oscena)
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_off
	`endif
	,
	.erase(1'b0),
	.program(1'b0)
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_on
	`endif
	// synopsys translate_off
	,
	.ctrl_bgpbusy(1'b0),
	.devclrn(1'b1),
	.devpor(1'b1),
	.sbdin(1'b0),
	.sbdout()
	// synopsys translate_on
	);
	defparam
		maxii_ufm_block1.address_width = 9,
		maxii_ufm_block1.erase_time = 500000000,
		maxii_ufm_block1.init_file = "E:/intelFPGA/Projects/HydroGuard/fusion-pixel-8px-monospaced-latin.mif",
		maxii_ufm_block1.mem1 = 512'h00000000000006000000000000544A3400000000004C1064000000000034FE4C00000000007E247E00000000000600060000000000005E000000000000000000,
		maxii_ufm_block1.mem10 = 512'h0000000000304830000000000070087800000000007038780000000000407E02000000000068107E00000000007A88880000000000407A48000000000070087E,
		maxii_ufm_block1.mem11 = 512'h0000000000786078000000000018207800000000007840380000000000483C08000000000028785000000000000810780000000000F8483000000000003048F8,
		maxii_ufm_block1.mem12 = 512'hFFFFFFFFFFFFFFFF00000000001018080000000000106C82000000000000FE000000000000826C100000000000485868000000000078A0980000000000681068,
		maxii_ufm_block1.mem13 = 512'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
		maxii_ufm_block1.mem14 = 512'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
		maxii_ufm_block1.mem15 = 512'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
		maxii_ufm_block1.mem16 = 512'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
		maxii_ufm_block1.mem2 = 512'h00000000000638C000000000000040000000000000101010000000000000408000000000001038100000000000281C280000000000007C820000000000827C00,
		maxii_ufm_block1.mem3 = 512'h00000000000E720200000000003A4A7C0000000000324A4E00000000007E24380000000000344A4200000000004C52620000000000407E4400000000003E427C,
		maxii_ufm_block1.mem4 = 512'h00000000000C52040000000000102844000000000028282800000000004428100000000000004880000000000000480000000000003E525C0000000000364A74,
		maxii_ufm_block1.mem5 = 512'h000000000072423C00000000000A0A7E00000000004A4A7E00000000003C427E000000000042423C0000000000344A7E00000000007C127C00000000005C5A3C,
		maxii_ufm_block1.mem6 = 512'h00000000003C423C00000000007C027E00000000007E0C7E000000000040407E000000000076087E00000000003E40200000000000427E4200000000007E087E,
		maxii_ufm_block1.mem7 = 512'h00000000007E307E00000000001E207E00000000007E407E0000000000027E020000000000324A4400000000006C127E0000000000BC423C00000000000C127E,
		maxii_ufm_block1.mem8 = 512'h00000000008080800000000000040204000000000000FE820000000000C03806000000000082FE000000000000465A6200000000000E700E0000000000661866,
		maxii_ufm_block1.mem9 = 512'h000000000078A89000000000000A7C08000000000058683000000000007E48300000000000484830000000000030487E00000000007848300000000000040200,
		maxii_ufm_block1.osc_sim_setting = 180000,
		maxii_ufm_block1.program_time = 1600000,
		maxii_ufm_block1.lpm_type = "maxii_ufm";
	assign
		add_en = (tmp_add_en & read_op),
		add_load = (tmp_add_load & read_op),
		arclk = (tmp_arclk0 & read_op),
		busy_arclk = arclk,
		busy_drclk = in_read_drclk,
		control_mux = (((~ q4) & ((q3 | q2) | q1)) | q4),
		copy_tmp_decode = tmp_decode,
		data_valid = data_valid_out_reg,
		data_valid_en = ((q4 & q3) & q1),
		dataout = tmp_do,
		dly_tmp_decode = decode_dffe,
		drdin = 1'b0,
		gated1 = gated_clk1_dffe,
		gated2 = gated_clk2_dffe,
		hold_decode = ((~ real_decode2_dffe) & real_decode),
		in_read_data_en = (tmp_in_read_data_en & read_op),
		in_read_drclk = (tmp_in_read_drclk & read_op),
		in_read_drshft = (tmp_in_read_drshft & read_op),
		mux_nread = (((~ control_mux) & read) | (control_mux & (~ data_valid_en))),
		nbusy = ((~ dly_tmp_decode) & (~ ufm_bgpbusy)),
		oscena = 1'b1,
		q0 = wire_cntr2_q[0],
		q1 = wire_cntr2_q[1],
		q2 = wire_cntr2_q[2],
		q3 = wire_cntr2_q[3],
		q4 = wire_cntr2_q[4],
		read = (~ nread),
		read_op = tmp_read,
		real_decode = start_decode,
		shiftin = {A[7:0], 1'b0},
		sipo_q = {sipo_dffe[15:0]},
		start_decode = (mux_nread & (~ ufm_bgpbusy)),
		start_op = (hold_decode | stop_op),
		stop_op = ((((q4 & q3) & (~ q2)) & q1) & q0),
		tmp_add_en = ((~ q4) & ((~ q3) | ((~ q2) & (~ q1)))),
		tmp_add_load = (~ ((~ q4) & (((((~ q3) & q2) | ((~ q3) & q0)) | ((~ q3) & q1)) | ((q3 & (~ q2)) & (~ q1))))),
		tmp_arclk = (gated1 & (~ ufm_osc)),
		tmp_arclk0 = ((~ q4) & ((~ q3) | (((~ q2) & (~ q1)) & (~ q0)))),
		tmp_ardin = A[8],
		tmp_arshft = add_en,
		tmp_data_valid2 = (stop_op & read_op),
		tmp_decode = tmp_read,
		tmp_drclk = (gated2 & (~ ufm_osc)),
		tmp_in_read_data_en = (((~ q4) & ((q3 & q2) | (q3 & q1))) | (q4 & (((~ q3) | ((~ q2) & (~ q1))) | (q1 & (~ q0))))),
		tmp_in_read_drclk = (((~ q4) & ((q3 & q2) | (q3 & q1))) | (q4 & (((~ q3) | ((~ q2) & (~ q1))) | (q1 & (~ q0))))),
		tmp_in_read_drshft = (~ (((((~ q4) & q3) & (~ q2)) & q1) & q0)),
		tmp_read = deco1_dffe,
		ufm_arclk = tmp_arclk,
		ufm_ardin = tmp_ardin,
		ufm_arshft = tmp_arshft,
		ufm_bgpbusy = wire_maxii_ufm_block1_bgpbusy,
		ufm_drclk = tmp_drclk,
		ufm_drdin = drdin,
		ufm_drdout = wire_maxii_ufm_block1_drdout,
		ufm_drshft = in_read_drshft,
		ufm_osc = wire_maxii_ufm_block1_osc,
		ufm_oscena = oscena,
		X_var = (shiftin & {9{(~ add_load)}}),
		Y_var = (addr & {9{add_load}}),
		Z_var = (X_var | Y_var);
endmodule //font_ufm_ufm_parallel_0
//VALID FILE
