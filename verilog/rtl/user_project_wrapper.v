// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */
`default_nettype none
`ifdef OGFX_NO_INCLUDE
`else
`include "src/openGFX430_defines.v"
`endif
module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/
parameter LA_WIDTH = `VRAM_MSB+2+16;
//Unused Ports:
 assign user_irq[2:1]=2'b00;
 assign io_oeb[`MPRJ_IO_PADS-1:7]={30{1'b0}};
 assign io_out[`MPRJ_IO_PADS-1:32]={6{1'b0}};
 assign la_data_out[127:LA_WIDTH+`LRAM_MSB+14]={62{1'b0}};
 assign wbs_dat_o[31:0]={32{1'b0}};
 assign wbs_ack_o=1'b0;

openGFX430 GFX430 (
`ifdef USE_POWER_PINS
	.vccd1(vccd1),	// User area 1 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
`endif

// OUTPUTs
    .irq_gfx_o(user_irq[0]),                            // Graphic Controller interrupt

    .lt24_cs_n_o(io_oeb[0]),                           // LT24 Chip select (Active low)
    .lt24_rd_n_o(io_oeb[1]),                           // LT24 Read strobe (Active low)
    .lt24_wr_n_o(io_oeb[2]),                           // LT24 Write strobe (Active low)
    .lt24_rs_o(io_oeb[3]),                             // LT24 Command/Param selection (Cmd=0/Param=1)
    .lt24_d_o(io_out[15:0]),                              // LT24 Data output
    .lt24_d_en_o(io_oeb[4]),                           // LT24 Data output enable
    .lt24_reset_n_o(io_oeb[5]),                        // LT24 Reset (Active Low)
    .lt24_on_o(io_oeb[6]),                             // LT24 on/off

    .per_dout_o(io_out[31:16]),                            // Peripheral data output

`ifdef WITH_PROGRAMMABLE_LUT
    .lut_ram_addr_o(la_data_out[LA_WIDTH+`LRAM_MSB+1:LA_WIDTH+1]),                        // LUT-RAM address
    .lut_ram_wen_o(la_data_out[LA_WIDTH+`LRAM_MSB+2]),                         // LUT-RAM write enable (active low)
  .lut_ram_cen_o(la_data_out[LA_WIDTH+`LRAM_MSB+3]),                         // LUT-RAM enable (active low)
    .lut_ram_din_o(la_data_out[LA_WIDTH+`LRAM_MSB+19:LA_WIDTH+`LRAM_MSB+4]),                         // LUT-RAM data input
`endif

    .vid_ram_addr_o(la_data_out[`VRAM_MSB:0]),                        // Video-RAM address
    .vid_ram_wen_o(la_data_out[`VRAM_MSB+1]),                         // Video-RAM write enable (active low)
    .vid_ram_cen_o(la_data_out[`VRAM_MSB+2]),                         // Video-RAM enable (active low)
    .vid_ram_din_o(la_data_out[LA_WIDTH:`VRAM_MSB+3]),                         // Video-RAM data input

// INPUTs
    .dbg_freeze_i(wbs_cyc_i),                          // Freeze address auto-incr on read
    .mclk(wb_clk_i),                                  // Main system clock
    .per_addr_i(wbs_adr_i[13:0]),                            // Peripheral address
    .per_din_i(wbs_dat_i[15:0]),                             // Peripheral data input
    .per_en_i(wbs_stb_i),                              // Peripheral enable (high active)
    .per_we_i({wbs_sel_i[0],wbs_we_i}),                              // Peripheral write enable (high active)
    .puc_rst(wb_rst_i),                               // Main system reset

    .lt24_d_i(wbs_dat_i[31:16]),                              // LT24 Data input

`ifdef WITH_PROGRAMMABLE_LUT
  .lut_ram_dout_i(la_data_in[15:0]),                        // LUT-RAM data output
`endif
    .vid_ram_dout_i(wbs_dat_i[31:16])                         // Video-RAM data output
);
endmodule	// user_project_wrapper

`default_nettype wire
