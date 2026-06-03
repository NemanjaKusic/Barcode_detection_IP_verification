`ifndef AXI_FULL_AGENT_PKG
`define AXI_FULL_AGENT_PKG

package axi_full_agent_pkg;
 
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // include Agent components : driver,monitor,sequencer
   /////////////////////////////////////////////////////////
   
   import config_pkg::*;   
   
   `include "memory_model.sv"
   `include "axi_full_seq_item.sv"
   `include "axi_full_sequencer.sv"
   `include "axi_full_driver.sv"
   `include "axi_full_monitor.sv"
   `include "axi_full_agent.sv"

endpackage

`endif

