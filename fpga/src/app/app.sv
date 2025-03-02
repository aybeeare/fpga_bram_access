`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ABR Inc
// Engineer: Aaron Belkin-Rosen
// 
// Create Date: 06/30/2024 02:41:16 PM
// Design Name: 
// Module Name: app
// Project Name: BRAM Controller 
// Target Devices: 
// Tool Versions: 
// Description: SPI master from MCU to utilize BRAM on FPGA
// 
// Additional Comments:
// 9/9: First Release
// 
//////////////////////////////////////////////////////////////////////////////////


module app
(
    // Ports List
    input logic sys_clk_100_in,
    input logic sys_clk_200_in,
    input logic sys_rst_in,

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
logic miso;

logic [12:0] addr;
logic [7:0] wdata;
logic [7:0] rdata;
logic wen;
logic en;


// App instantiation
spi_slave_to_bram spi_slave2bram_inst
(
    // Ports List
    .sys_clk            (sys_clk_100_in),
    .sys_rst            (sys_rst_in),

    // SPI Interface
    .sclk_in            (sclk_in),
    .mosi_in            (mosi_in),
    .cs_in              (cs_in),
    .miso_out           (miso),

    // BRAM Interface
    .addr_out           (addr),
    .wdata_out          (wdata),
    .rdata_in           (rdata),
    .wen_out            (wen),
    .en_out             (en)
);


// BRAM IP instantiation
blk_mem_gen_0 blk_mem_gen_0_inst
(
// bram interface
.clka       (sys_clk_200),
.ena        (en),
.wea        (wen),
.addra      (addr),
.dina       (wdata),
.douta      (rdata), // only output port
);

assign miso_out = miso; 

endmodule
