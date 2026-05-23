`ifndef WAIT_FOR_READY_SEQ_SV
`define WAIT_FOR_READY_SEQ_SV

class wait_for_ready_seq extends uvm_sequence #(axi_lite_seq_item);

    `uvm_object_utils(wait_for_ready_seq)

    // Ready register address - at offset 0x8
    bit [3:0] REG_READY = 4'h8;   
	
	// How many reads were done until ready = 1
    int reads_done = 0;
	// Indication that ready became 1
	bit ready_observed = 0;

    function new(string name = "wait_for_ready_seq");
        super.new(name);
    endfunction

    task body();
		axi_lite_seq_item req;

		`uvm_info("WAIT_FOR_READY", "Beginning reading ready", UVM_LOW)

		while (!ready_observed) begin
			req = axi_lite_seq_item::type_id::create("poll_req");
			
			start_item(req);
			
			if (!req.randomize() with {
				dir  == AXI_LITE_READ;
				addr == REG_READY;
			})
				`uvm_fatal("WAIT_FOR_READY", "Randomization failed")
				
			finish_item(req);

			reads_done++;
			if (req.data[0] == 1'b1) begin
				ready_observed = 1;
				`uvm_info("WAIT_FOR_READY", $sformatf("Ready observed after %0d reads", reads_done), UVM_LOW)
			end else begin 
			    #100us;   // wait 100 microseconds between polls
            end
		end
	endtask

endclass : wait_for_ready_seq

`endif