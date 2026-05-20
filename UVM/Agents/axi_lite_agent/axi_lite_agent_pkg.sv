`ifndef AXI_LITE_AGENT_PKG
`define AXI_LITE_AGENT_PKG

package axi_lite_agent_pkg;
 
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // include Agent components : driver,monitor,sequencer
   /////////////////////////////////////////////////////////
   //import configurations_pkg::*;   
   
   `include "axi_lite_seq_item.sv"
   `include "axi_lite_sequencer.sv"
   `include "axi_lite_driver.sv"
   `include "axi_lite_monitor.sv"
   `include "axi_lite_agent.sv"

endpackage

`endif

