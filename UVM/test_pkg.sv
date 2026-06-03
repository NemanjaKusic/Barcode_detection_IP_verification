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

endpackage

`include "axi_lite_if.sv"
`include "axi_full_if.sv"

`endif