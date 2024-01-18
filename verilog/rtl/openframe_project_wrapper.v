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
 * openframe_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user openframe project.
 *
 * Written by Tim Edwards
 * March 27, 2023
 * Efabless Corporation
 *
 *-------------------------------------------------------------
 */

module openframe_project_wrapper (
`ifdef USE_POWER_PINS
    inout vdda,		// User area 0 3.3V supply
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa,		// User area 0 analog ground
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd,		// Common 1.8V supply
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd,		// Common digital ground
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
    inout vddio,	// Common 3.3V ESD supply
    inout vssio,	// Common ESD ground
`endif

    /* Signals exported from the frame area to the user project */
    /* The user may elect to use any of these inputs.		*/

    input	 porb_h,	// power-on reset, sense inverted, 3.3V domain
    input	 porb_l,	// power-on reset, sense inverted, 1.8V domain
    input	 por_l,		// power-on reset, noninverted, 1.8V domain
    input	 resetb_h,	// master reset, sense inverted, 3.3V domain
    input	 resetb_l,	// master reset, sense inverted, 1.8V domain
    input [31:0] mask_rev,	// 32-bit user ID, 1.8V domain

    /* GPIOs.  There are 44 GPIOs (19 left, 19 right, 6 bottom). */
    /* These must be configured appropriately by the user project. */

    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    input  [`OPENFRAME_IO_PADS-1:0] gpio_in,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_in_h,
    output [`OPENFRAME_IO_PADS-1:0] gpio_out,
    output [`OPENFRAME_IO_PADS-1:0] gpio_oeb,
    output [`OPENFRAME_IO_PADS-1:0] gpio_inp_dis,	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    output [`OPENFRAME_IO_PADS-1:0] gpio_ib_mode_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_vtrip_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_slow_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_holdover,
    output [`OPENFRAME_IO_PADS-1:0] gpio_analog_en,
    output [`OPENFRAME_IO_PADS-1:0] gpio_analog_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_analog_pol,
    output [`OPENFRAME_IO_PADS-1:0] gpio_dm2,
    output [`OPENFRAME_IO_PADS-1:0] gpio_dm1,
    output [`OPENFRAME_IO_PADS-1:0] gpio_dm0,

    /* These signals correct directly to the pad.  Pads using analog I/O
     * connections should keep the digital input and output buffers turned
     * off.  Both signals connect to the same pad.  The "noesd" signal
     * is a direct connection to the pad;  the other signal connects through
     * a series resistor which gives it minimal ESD protection.  Both signals
     * have basic over- and under-voltage protection at the pad.  These
     * signals may be expected to attenuate heavily above 50MHz.
     */
    inout  [`OPENFRAME_IO_PADS-1:0] analog_io,
    inout  [`OPENFRAME_IO_PADS-1:0] analog_noesd_io,

    /* These signals are constant one and zero in the 1.8V domain, one for
     * each GPIO pad, and can be looped back to the control signals on the
     * same GPIO pad to set a static configuration at power-up.
     */
    input  [`OPENFRAME_IO_PADS-1:0] gpio_loopback_one,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_loopback_zero
);

    `define IO_NUM_CONFIGS 10

    /*
    IO_DIGITAL_DEFAULT
    
    (LSB)
    ib_mode_sel - 0 (CMOS)
    vtrip_sel   - 0 (CMOS)
    slow_sel    - 0 (fast, 2-12ns)
    holdover    - 0 (no override)
    analog_en   - 0 (no analog)
    analog_sel  - 0 (don't care)
    analog_pol  - 0 (don't care)
    dm2         - 1 
    dm1         - 1
    dm0         - 0 (dm2:0 strong)
    (MSB)
    */

    `define IO_DIGITAL_DEFAULT 10'b0110000000

    parameter [`OPENFRAME_IO_PADS*`IO_NUM_CONFIGS-1:0] IO_CONFIGS = {
        10'b1010101010,
        {`OPENFRAME_IO_PADS-1{`IO_DIGITAL_DEFAULT}}
    };

    generate
        genvar i;
        // Assign the gpio constants according to the io configuration
        for (i=0; i<`OPENFRAME_IO_PADS; i++) begin
            assign gpio_ib_mode_sel[i] = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 0] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
            assign gpio_vtrip_sel[i]   = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 1] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
            assign gpio_slow_sel[i]    = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 2] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
            assign gpio_holdover[i]    = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 3] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
            assign gpio_analog_en[i]   = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 4] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
            assign gpio_analog_sel[i]  = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 5] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
            assign gpio_analog_pol[i]  = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 6] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
            assign gpio_dm2[i]         = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 7] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
            assign gpio_dm1[i]         = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 8] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
            assign gpio_dm0[i]         = (IO_CONFIGS[i*`IO_NUM_CONFIGS + 9] == 1'b1) ? gpio_loopback_one[i] : gpio_loopback_zero[i];
        end
    endgenerate

    // Important!
    // Whenever you update SRAM_NUM_INSTANCES here,
    // you also need to update SRAM_NUM_INSTANCES
    // in sky130_top and reharden the macro
    localparam SRAM_NUM_INSTANCES = 8;
    localparam NUM_WMASKS = 4;
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH_DEFAULT = 9;
	
    // Port 0: RW
    wire [SRAM_NUM_INSTANCES-1:0]                          sram_clk0;
    wire [SRAM_NUM_INSTANCES-1:0]                          sram_csb0;
    wire [SRAM_NUM_INSTANCES-1:0]                          sram_web0;
    wire [(SRAM_NUM_INSTANCES*NUM_WMASKS)-1:0]             sram_wmask0;
    wire [(SRAM_NUM_INSTANCES*ADDR_WIDTH_DEFAULT)-1:0]     sram_addr0;
    wire [(SRAM_NUM_INSTANCES*DATA_WIDTH)-1:0]             sram_din0;
    wire [(SRAM_NUM_INSTANCES*DATA_WIDTH)-1:0]             sram_dout0;

    // Port 1: R
    wire [SRAM_NUM_INSTANCES-1:0]                          sram_clk1;
    wire [SRAM_NUM_INSTANCES-1:0]                          sram_csb1;
    wire [(SRAM_NUM_INSTANCES*ADDR_WIDTH_DEFAULT)-1:0]     sram_addr1;
    wire [(SRAM_NUM_INSTANCES*DATA_WIDTH)-1:0]             sram_dout1;

	
	sky130_top sky130_top_inst (
`ifdef USE_POWER_PINS
		.vccd1(vccd1),
		.vssd1(vssd1),
`endif
        // Clock and reset
        .clk_i      (gpio_in[0]),
        .rst_ni     (gpio_in[1]),
        
        // Blinky
        .led        (),
        
        // Uart
        .ser_tx     (),
        .ser_rx     (gpio_in[2]),
        
        // SPI signals
        .sck        (),
        .sdo        (),
        .sdi        (gpio_in[2]),
        .cs         (),

        // Port 0: RW
        .sram_clk0      (sram_clk0),
        .sram_csb0      (sram_csb0),
        .sram_web0      (sram_web0),
        .sram_wmask0    (sram_wmask0),
        .sram_addr0     (sram_addr0),
        .sram_din0      (sram_din0),
        .sram_dout0     (sram_dout0),

        // Port 1: R
        .sram_clk1      (sram_clk1),
        .sram_csb1      (sram_csb1),
        .sram_addr1     (sram_addr1),
        .sram_dout1     (sram_dout1)
    );

	// Generate SRAM macros in a loop
	// and assign signal directly from the huge arrays
    generate
        genvar i;

        // Forward signals to each SRAM macro
        for (i=0; i<SRAM_NUM_INSTANCES; i++) begin : srams
            
            sky130_sram_2kbyte_1rw1r_32x512_8 ram_inst (
            `ifdef USE_POWER_PINS
                .vccd1  (vccd1),
                .vssd1  (vssd1),
            `endif
                // Port 0: RW
                .clk0   (sram_clk0[i]),
                .csb0   (sram_csb0[i]),
                .web0   (sram_web0[i]),
                .wmask0 (sram_wmask0[i * NUM_WMASKS+:NUM_WMASKS]),
                .addr0  (sram_addr0[i * ADDR_WIDTH_DEFAULT+:ADDR_WIDTH_DEFAULT]),
                .din0   (sram_din0[i * DATA_WIDTH+:DATA_WIDTH]),
                .dout0  (sram_dout0[i * DATA_WIDTH+:DATA_WIDTH]),
                // Port 1: R
                .clk1   (sram_clk1[i]),
                .csb1   (sram_csb1[i]),
                .addr1  (sram_addr1[i * ADDR_WIDTH_DEFAULT+:ADDR_WIDTH_DEFAULT]),
                .dout1  (sram_dout1[i * DATA_WIDTH+:DATA_WIDTH])
            );
        end
    endgenerate

	(* keep *) vccd1_connection vccd1_connection ();
	(* keep *) vssd1_connection vssd1_connection ();

endmodule	// openframe_project_wrapper
