`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ABR Inc
// Engineer: Aaron Belkin-Rosen
// 
// Create Date: 06/30/2024 02:41:16 PM
// Design Name: 
// Module Name: top
// Project Name: BRAM Controller 
// Target Devices: 
// Tool Versions: 
// Description: SPI master from MCU to utilize BRAM on FPGA
// 
// Additional Comments:
// 9/9: First Release
// 
//////////////////////////////////////////////////////////////////////////////////


module top
(
    // Ports List
    input logic  osc_clk_in,

    // SPI Interface
    input logic sclk_in,
    input logic mosi_in,
    input logic cs_in,
    output logic miso_out
);

// Internals
logic sys_clk_100;
logic sys_clk_200;
logic sys_rst;
logic [12:0] addr;
logic [7:0] wdata;
logic [7:0] rdata;
logic wen;
logic en;
logic miso;
  
// clocks and resets instantiation
clocks_and_resets clocks_and_resets_inst
(
    // Ports List
    .osc_clk_in         (osc_clk_in),

    .sys_clk_100_out    (sys_clk_100),
    .sys_clk_200_out    (sys_clk_200),
    .sys_rst_out        (sys_rst)
);

app app_inst
(
    // Ports List
    .sys_clk_100_in     (sys_clk_100),
    .sys_clk_200_in     (sys_clk_200),
    .sys_rst_in         (sys_rst),

    // SPI Interface
    .sclk_in            (sclk_in),
    .mosi_in            (mosi_in),
    .cs_in              (cs_in),
    .miso_out           (miso)
);

assign miso_out = miso; 

endmodule
