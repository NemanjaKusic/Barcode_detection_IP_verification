`ifndef AXI_LITE_SEQUENCER_SV
`define AXI_LITE_SEQUENCER_SV

class axi_lite_sequencer extends uvm_sequencer#(axi_lite_seq_item);

   `uvm_component_utils(axi_lite_sequencer)

   function new(string name = "axi_lite_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction
   
   function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AXI_LITE_SEQUENCER", "build_phase running", UVM_LOW)
   endfunction : build_phase

endclass : axi_lite_sequencer

`endif
