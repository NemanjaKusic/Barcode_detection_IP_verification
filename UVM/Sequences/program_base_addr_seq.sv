`ifndef PROGRAM_BASE_ADDR_SEQ_SV
`define PROGRAM_BASE_ADDR_SEQ_SV

class program_base_addr_seq extends uvm_sequence #(axi_lite_seq_item);

    `uvm_object_utils(program_base_addr_seq)

    // Register offset for base_address 
    bit [3:0] REG_BASE_ADDRESS = 4'h4;

    // Default value 0x0000_0000
    bit [31:0] base_address_value = 32'h0000_0000;

    function new(string name = "program_base_addr_seq");
        super.new(name);
    endfunction

    // Body - one AXI-Lite write to the base_address register
    task body();
        axi_lite_seq_item req;

        `uvm_info("PROGRAM_BASE_ADDR_SEQ", $sformatf("Programming base_address = 0x%08h", base_address_value), UVM_LOW)

        req = axi_lite_seq_item::type_id::create("base_addr_write");
		
        start_item(req);
		
        if (!req.randomize() with {
            dir  == AXI_LITE_WRITE;
            addr == REG_BASE_ADDRESS;
            data == base_address_value;
        })
            `uvm_fatal("PROGRAM_BASE_ADDR_SEQ", "Randomization failed")
			
        finish_item(req);

        `uvm_info("PROGRAM_BASE_ADDR_SEQ", "Base address programmed", UVM_LOW)
    endtask

endclass

`endif