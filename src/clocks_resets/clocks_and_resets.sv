`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ABR Inc
// Engineer: Aaron Belkin-Rosen
// 
// Create Date: 06/30/2024 02:41:16 PM
// Design Name: 
// Module Name: clocks_and_resets
// Project Name: FPGA Mem Interface
// Target Devices: 
// Tool Versions: 
// Description: SPI master from MCU to utilize BRAM on FPGA
// 
// Additional Comments:
// 9/9: First Release
// 
//////////////////////////////////////////////////////////////////////////////////


module clocks_and_resets
(
    // Ports List
    input logic  osc_clk_in,
    //input logic  ext_rst_in, // no external async reset for now

    // Syncrhonized clk and reset generator
    output logic sys_clk_100_out,
    output logic sys_clk_200_out,
    output logic sys_rst_out
);

// Internal signals for reset gen logic
logic mmcm_lock;
logic mmcm_lock_r1, mmcm_lock_r2;
logic mmcm_lock_d1, mmcm_lock_d1;
//logic ext_rst_r1, ext_rst_r2;
logic sys_clk_100;
logic sys_clk_200;
logic sys_rst;

clk_wiz_0 clk_wiz_inst
(
// Clock out ports
.clk_out1(sys_clk_100),
.clk_out2(sys_clk_200),

// Status and control signals
.reset(),
.locked(mmcm_lock),

// Clock in ports
.clk_in1(osc_clk_in)
);

// Sync reset with 100 MHz sys clock
always @(posedge sys_clk_100)
begin
    mmcm_lock_r1 <= mmcm_lock;
    mmcm_lock_r2 <= mmcm_lock_r1;

    if (mmcm_lock_r2) // also need ext_rst_r2 to come with mmcm_lock_r2 to release release reset...
    begin
        sys_rst <= 1'b0; // release reset case
    end

    else
    begin
        sys_rst <= 1'b1; // hold in reset 
    end
end

// Sync reset with 200 MHz sys clock
always @(posedge sys_clk_200)
begin
    mmcm_lock_d1 <= mmcm_lock;
    mmcm_lock_d2 <= mmcm_lock_d1;
    
    if (mmcm_lock_d2) // also need ext_rst_r2 to come with mmcm_lock_r2 to release release reset...
    begin
        sys_rst <= 1'b0; // release reset case
    end

    else
    begin
        sys_rst <= 1'b1; // hold in reset 
    end
end

assign sys_rst_out = sys_rst; 
assign sys_clk_100_out = sys_clk_100;
assign sys_clk_200_out = sys_clk_200;

endmodule
