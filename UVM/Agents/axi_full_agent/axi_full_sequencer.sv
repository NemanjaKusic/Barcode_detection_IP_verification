`ifndef AXI_FULL_SEQUENCER_SV
`define AXI_FULL_SEQUENCER_SV

class axi_full_sequencer extends uvm_sequencer#(axi_full_seq_item);

   `uvm_component_utils(axi_full_sequencer)

   function new(string name = "axi_full_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction
   
   function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AXI_FULL_SEQUENCER", "build_phase running", UVM_LOW)
   endfunction : build_phase

endclass : axi_full_sequencer

`endif
