`ifndef BASE_TEST_SV
`define BASE_TEST_SV 

//	import uvm_pkg::*;
//	`include "uvm_macros.svh"

class base_test extends uvm_test;

    `uvm_component_utils(base_test)
	
	sobel_env env;
	memory_model shared_mem;
	
	function new(string name = "base_test", uvm_component parent = null);
		super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("BASE_TEST", "build_phase running", UVM_LOW)
		
		shared_mem = memory_model::type_id::create("shared_mem");
        uvm_config_db#(memory_model)::set(this, "env.*", "shared_mem", shared_mem);
		env = sobel_env::type_id::create("env", this);  
    endfunction
    
    task run_phase(uvm_phase phase);
        start_pulse_seq seq;
        wait_for_ready_seq wait_seq;

        phase.raise_objection(this);
        `uvm_info("BASE_TEST", "run_phase running", UVM_LOW)

        // Check to see if there are a few non-zero values on the axi full rdata and wdata signals
        shared_mem.write_byte(20000, 255);

        // Create and start the sequence on the AXI-Lite sequencer
        seq = start_pulse_seq::type_id::create("seq");
        `uvm_info("BASE_TEST", "Issuing start pulse", UVM_LOW)
        seq.start(env.lite_slave_agent.seqr);
        
        // Create the sequence that waits for ready to become 1
        `uvm_info("BASE_TEST", "Waiting for DUT ready (timeout: 100 ms)", UVM_LOW)
        wait_seq = wait_for_ready_seq::type_id::create("wait_seq");

        fork
            begin
                // Starting sequence that waits for ready to become 1
                wait_seq.start(env.lite_slave_agent.seqr);
            end
            begin
                #100ms;
                `uvm_warning("BASE_TEST", "Timeout waiting for ready")
            end
        join_any
        disable fork;
        
        if (wait_seq.ready_observed) begin
            `uvm_info("BASE_TEST", $sformatf("DUT ready after %0d polls. Dumping memory.", wait_seq.reads_done), UVM_LOW)
        end 
        else begin
            `uvm_error("BASE_TEST", "DUT did not assert ready within watchdog timeout")
        end
        
        #100ns;   // small drain time so any pending bus activity finishes cleanly

        phase.drop_objection(this);
    endtask
    
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
    
endclass
  
`endif