`ifndef TEST_PKG_SV
`define TEST_PKG_SV

package test_pkg;

	import uvm_pkg::*;
	`include "uvm_macros.svh"
	
	import config_pkg::*;
	import axi_lite_agent_pkg::*;
	import axi_full_agent_pkg::*;
	import seq_pkg::*;
	
	`include "sobel_scoreboard.sv"
	`include "sobel_env.sv"
	// Include all tests here:
	`include "Tests/base_test.sv"
	`include "Tests/test_basic_uniform.sv"
	`include "Tests/test_basic_barcode.sv"
	`include "Tests/test_stress_latency.sv"
	`include "Tests/test_stress_backpressure.sv"
	`include "Tests/test_stress_combined.sv"
	`include "Tests/test_basic_v_edge.sv"
	`include "Tests/test_zero_image.sv"
	`include "Tests/test_max_image.sv"
	`include "Tests/test_v_edge_neg.sv"
	`include "Tests/test_h_edge_pos.sv"
	`include "Tests/test_diagonal.sv"
	`include "Tests/test_chessboard.sv"
	`include "Tests/test_impulse.sv"
	`include "Tests/test_stripe_edge.sv"
	`include "Tests/test_realistic_1.sv"
	`include "Tests/test_realistic_2.sv"
	`include "Tests/test_realistic_3.sv"
	`include "Tests/test_realistic_4.sv"
	`include "Tests/test_realistic_5.sv"
	`include "Tests/test_back_to_back_start.sv"
	`include "Tests/test_start_while_busy.sv"
	`include "Tests/test_base_addr_low.sv"
	`include "Tests/test_base_addr_high.sv"
	`include "Tests/test_dirty_ddr.sv"
	`include "Tests/test_misaligned_addr.sv"
	`include "Tests/test_slverr.sv"
	`include "Tests/test_decerr.sv"

endpackage

`include "axi_lite_if.sv"
`include "axi_full_if.sv"

`endif