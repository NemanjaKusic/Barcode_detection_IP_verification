`ifndef AXI_LITE_SEQ_ITEM_SV
`define AXI_LITE_SEQ_ITEM_SV

    // Enumeration for direction
    typedef enum bit {
        AXI_LITE_READ  = 1'b0,
        AXI_LITE_WRITE = 1'b1
    } axi_lite_dir_e;

    // Enumeration for the response codes
    typedef enum bit [1:0] {
        AXI_LITE_OKAY   = 2'b00,
        AXI_LITE_EXOKAY = 2'b01,
        AXI_LITE_SLVERR = 2'b10,
        AXI_LITE_DECERR = 2'b11
    } axi_lite_resp_e;

class axi_lite_seq_item extends uvm_sequence_item;

    // Fields
    rand axi_lite_dir_e   dir;     // READ or WRITE
    rand bit [3:0]        addr;    //only 3 4-byte registers in address space(start, base_adress, ready)
    rand bit [31:0]       data;
    rand bit [3:0]        wstrb;   
    rand bit [2:0]        prot;    // AXI protection bits

    // Response - after the transaction completes
    axi_lite_resp_e       resp;

    `uvm_object_utils_begin(axi_lite_seq_item)
        `uvm_field_enum(axi_lite_dir_e,  dir,   UVM_DEFAULT)
        `uvm_field_int (addr,                   UVM_DEFAULT)
        `uvm_field_int (data,                   UVM_DEFAULT)
        `uvm_field_int (wstrb,                  UVM_DEFAULT)
        `uvm_field_int (prot,                   UVM_DEFAULT)
        `uvm_field_enum(axi_lite_resp_e, resp,  UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "axi_lite_seq_item");
        super.new(name);
    endfunction

    // Constraints
    // The 4-bit address must be 4 byte aligned. Error in Vitis otherwise
    constraint c_addr_aligned {
        addr[1:0] == 2'b00;
    }

    // All for bytes are read/written
    constraint c_wstrb_default {
        wstrb == 4'b1111;
    }

    // prot is always 0 - non-secure, unprivileged, data access.
    constraint c_prot_zero {
        prot == 3'b000;
    }
    
endclass : axi_lite_seq_item

`endif