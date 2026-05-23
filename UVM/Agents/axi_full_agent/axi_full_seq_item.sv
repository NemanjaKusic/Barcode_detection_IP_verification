`ifndef AXI_FULL_SEQ_ITEM_SV
`define AXI_FULL_SEQ_ITEM_SV

// Direction enum
typedef enum bit {
    AXI_FULL_READ  = 1'b0,
    AXI_FULL_WRITE = 1'b1
} axi_full_dir_e;

// Burst type enum
typedef enum bit [1:0] {
    AXI_BURST_FIXED = 2'b00,
    AXI_BURST_INCR  = 2'b01,
    AXI_BURST_WRAP  = 2'b10,
    AXI_BURST_RSVD  = 2'b11
} axi_full_burst_e;

// Response enum
typedef enum bit [1:0] {
    AXI_FULL_OKAY   = 2'b00,
    AXI_FULL_EXOKAY = 2'b01,
    AXI_FULL_SLVERR = 2'b10,
    AXI_FULL_DECERR = 2'b11
} axi_full_resp_e;

class axi_full_seq_item extends uvm_sequence_item;

    // Address-channel read/write fields 
    rand axi_full_dir_e    dir;
    rand bit [0:0]         id;       
    rand bit [31:0]        addr;     
    rand bit [7:0]         len;      // burst length (beats - 1)
    rand bit [2:0]         size;     // (int'(3'b010))^2 = 4 bytes
    rand axi_full_burst_e  burst;    // burst type
    rand bit               lock;     // exclusive access (always 0 for our IP)
    rand bit [3:0]         cache;    // memory type (4'b0010 for our IP)
    rand bit [2:0]         prot;     // protection (always 3'b000 for our IP)
    rand bit [3:0]         qos;      // quality of service (always 0)

    // Data-channel fields
    rand bit [31:0] data [];

    // Write strobes - one element per transaction (of a whole burst), valid only for writes
    rand bit [3:0]  wstrb [];

    // Response fields
    // For writes: single BRESP value at end of burst
    // For reads:  RRESP per transaction beat (usually all the same)
    axi_full_resp_e  bresp;
    axi_full_resp_e  rresp [];

    // UVM field registration
    `uvm_object_utils_begin(axi_full_seq_item)
        `uvm_field_enum (axi_full_dir_e,   dir,   UVM_DEFAULT)
        `uvm_field_int  (id,                      UVM_DEFAULT)
        `uvm_field_int  (addr,                    UVM_DEFAULT)
        `uvm_field_int  (len,                     UVM_DEFAULT)
        `uvm_field_int  (size,                    UVM_DEFAULT)
        `uvm_field_enum (axi_full_burst_e, burst, UVM_DEFAULT)
        `uvm_field_int  (lock,                    UVM_DEFAULT)
        `uvm_field_int  (cache,                   UVM_DEFAULT)
        `uvm_field_int  (prot,                    UVM_DEFAULT)
        `uvm_field_int  (qos,                     UVM_DEFAULT)
        `uvm_field_array_int  (data,              UVM_DEFAULT)
        `uvm_field_array_int  (wstrb,             UVM_DEFAULT)
        `uvm_field_enum (axi_full_resp_e,  bresp, UVM_DEFAULT)
        `uvm_field_array_enum (axi_full_resp_e, rresp, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "axi_full_seq_item");
        super.new(name);
    endfunction

    // Constraints 
    // Burst length: IP always uses AWLEN/ARLEN = 255 (256 tranasctions)
    constraint c_len_always_255 {
        len == 8'hFF;
    }

    // Burst size: always 4 bytes = 3'b010
    constraint c_size_4_bytes {
        size == 3'b010;
    }

    // Burst type: always INCR
    constraint c_burst_incr {
        burst == AXI_BURST_INCR;
    }

    // ID: always 0
    constraint c_id_zero {
        id == 1'b0;
    }

    // Lock: always 0 (no exclusive accesses)
    constraint c_lock_zero {
        lock == 1'b0;
    }

    // Cache: always 4'b0010 (second bit set (other components, lite Interconnect can modify the burst), non-cacheable, non-bufferable)
    constraint c_cache_value {
        cache == 4'b0010;
    }

    // Prot: always 0
    constraint c_prot_zero {
        prot == 3'b000;
    }

    // Qos: always 0
    constraint c_qos_zero {
        qos == 4'b0000;
    }

    // Data array length must match burst length (len + 1 beats).
    // Wstrb array length must also match.
    // Rresp array length must also match for reads.
    constraint c_array_sizes {
        data.size()  == len + 1;
        wstrb.size() == len + 1;
        rresp.size() == len + 1;
    }

    // Wstrb default: all bytes enabled
    constraint c_wstrb_default {
        foreach (wstrb[i])
            wstrb[i] == 4'b1111;
    }

    //Print without arrays
    function string to_string();
        return $sformatf("dir=%s id=%0d addr=0x%08h len=%0d size=%0d burst=%s cache=0x%01h beats=%0d bresp=%s",
                         dir.name(), id, addr, len, size, burst.name(), cache, data.size(), bresp.name());
    endfunction

endclass : axi_full_seq_item

`endif