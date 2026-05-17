`ifndef BASE_TEST_SV
`define BASE_TEST_SV 

//	import uvm_pkg::*;
//	`include "uvm_macros.svh"

class base_test extends uvm_test;

    `uvm_component_utils(base_test)
	
	function new(string name = "base_test", uvm_component parent = null);
		super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("BASE_TEST", "build_phase running", UVM_LOW)
    endfunction
    
    task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		`uvm_info("BASE_TEST", "run_phase running", UVM_LOW)
		#1000;
		phase.drop_objection(this);
    endtask
endclass
  
`endif