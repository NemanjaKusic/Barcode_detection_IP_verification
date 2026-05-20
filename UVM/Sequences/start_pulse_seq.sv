`ifndef START_PULSE_SEQ_SV
`define START_PULSE_SEQ_SV

class start_pulse_seq extends uvm_sequence #(axi_lite_seq_item);

    `uvm_object_utils(start_pulse_seq)

    // Register offset for the start register (from the AXI-Lite slave)
    bit [3:0] REG_START = 4'h0;

    function new(string name = "start_pulse_seq");
        super.new(name);
    endfunction

    task body();
        axi_lite_seq_item req;

        `uvm_info("START_PULSE_SEQ", "Starting start-pulse sequence", UVM_LOW)

        // Assert start (write 1 to the start register)
        req = axi_lite_seq_item::type_id::create("req_assert");
        start_item(req);
        if (!req.randomize() with {
            dir   == AXI_LITE_WRITE;
            addr  == REG_START;
            data  == 32'h0000_0001;
        })
            `uvm_fatal("START_PULSE_SEQ", "Randomization failed for start assert")
        finish_item(req);

        `uvm_info("START_PULSE_SEQ", "Start asserted", UVM_LOW)

        // Deassert start (write 0 to the start register)
        req = axi_lite_seq_item::type_id::create("req_deassert");
        start_item(req);
        if (!req.randomize() with {
            dir   == AXI_LITE_WRITE;
            addr  == REG_START;
            data  == 32'h0000_0000;
        })
            `uvm_fatal("START_PULSE_SEQ", "Randomization failed for start deassert")
        finish_item(req);

        `uvm_info("START_PULSE_SEQ", "Start deasserted, sequence complete", UVM_LOW)
    endtask

endclass : start_pulse_seq

`endif