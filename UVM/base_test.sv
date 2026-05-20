`ifndef BASE_TEST_SV
`define BASE_TEST_SV 

//	import uvm_pkg::*;
//	`include "uvm_macros.svh"

class base_test extends uvm_test;

    `uvm_component_utils(base_test)
	
	sobel_env env;
	
	function new(string name = "base_test", uvm_component parent = null);
		super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("BASE_TEST", "build_phase running", UVM_LOW)
		
		env = sobel_env::type_id::create("env", this);  
    endfunction
    
    task run_phase(uvm_phase phase);
        start_pulse_seq seq;

        phase.raise_objection(this);
        `uvm_info("BASE_TEST", "run_phase running", UVM_LOW)

        // Create and start the sequence on the AXI-Lite sequencer
        seq = start_pulse_seq::type_id::create("seq");
        seq.start(env.lite_slave_agent.seqr);

        `uvm_info("BASE_TEST", "Sequence finished, waiting briefly for bus quiescence", UVM_LOW)
        #100ns;   // small drain time so any pending bus activity finishes cleanly

        phase.drop_objection(this);
    endtask
    
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
    
endclass
  
`endif