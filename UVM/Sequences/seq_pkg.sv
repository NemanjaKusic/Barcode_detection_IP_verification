`ifndef SEQ_PKG_SV
`define SEQ_PKG_SV

package seq_pkg;

	import uvm_pkg::*;      // import the UVM library
	`include "uvm_macros.svh" // Include the UVM macros
	
	//import axi_lite_agent_pkg::axi_lite_seq_item;
	//import axi_lite_agent_pkg::axi_lite_sequencer;
	import axi_lite_agent_pkg::*;  //need to add like this instead so that enums inside axi_lite_seq_item can be used
 
	`include "start_pulse_seq.sv"

endpackage 

`endif