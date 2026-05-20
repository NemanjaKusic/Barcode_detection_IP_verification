`ifndef TEST_PKG_SV
`define TEST_PKG_SV

package test_pkg;

	import uvm_pkg::*;
	`include "uvm_macros.svh"
	
	import axi_lite_agent_pkg::*;
	import seq_pkg::*;
	
	`include "sobel_env.sv"
	// Include all tests here:
	`include "base_test.sv"

endpackage

`include "axi_lite_if.sv"
`include "axi_full_if.sv"

`endif