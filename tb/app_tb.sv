`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2025 10:31:15 PM
// Design Name: 
// Module Name: app_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module app_tb(
);

// Constants
const realtime CLK_100MHZ_PERIOD = 10ns;
const realtime CLK_200MHZ_PERIOD = 5ns;
const realtime CLK_1MHZ_PERIOD = 1000ns;
const realtime SIM_DELAY = 10ns;

// Parameters
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 13;

// Clocks and Resets
logic clk_100mhz = 0;
logic clk_200mhz = 0;
logic rst_100mhz = 0;
logic sclk = 0;

// internal declarations
logic miso;
logic mosi;
logic cs;
logic sclk_r1, sclk_r2, sclk_re, sclk_fe;

logic [DATA_WIDTH-1:0] wdata, rdata;
logic [ADDR_WIDTH-1:0] addr;
logic wen, en;

// data to drive testbench with
logic [DATA_WIDTH-1:0] rx_head = 8'hDC;
logic [DATA_WIDTH-1:0] read_opcode = 8'hCB;
logic [DATA_WIDTH-1:0] write_opcode = 8'hAB;
logic [ADDR_WIDTH-1:0] addr_data1 = 13'd15;
logic [ADDR_WIDTH-1:0] addr_data2 = 13'b1100110011001;
logic [DATA_WIDTH-1:0] wdata_test1 = 8'hFE;
logic [DATA_WIDTH-1:0] wdata_test2 = 8'h01;
logic [2*DATA_WIDTH-1:0] read_data_rx = 16'h0;

// Testbench signals
logic [3:0] start_test = '0;
logic [3:0] done_test = '0;
logic [2:0] test_summary = '0;
logic [15:0] read_data_shift_in = 0;

// Generate TB clocks
always
begin
    sclk = ~sclk;
    #(CLK_1MHZ_PERIOD/2);
end

always
begin
    clk_100mhz = ~clk_100mhz;
    #(CLK_100MHZ_PERIOD/2);
end

always
begin
    clk_200mhz = ~clk_200mhz;
    #(CLK_200MHZ_PERIOD/2);
end

// SPI clock edge detection logic
always @(posedge clk_100mhz)
begin
    sclk_r1 <= sclk;
    sclk_r2 <= sclk_r1;
end

assign sclk_re = ~sclk_r1 & sclk;
assign sclk_fe = sclk_r1 & ~sclk;

// DUT instantiation

// spi slave to BRAM instance
spi_slave_to_bram
#(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)

spi2bram_inst
(
    // Ports List
    .sys_clk_in(clk_100mhz),
    .sys_rst_in(rst_100mhz),

    // SPI Interface
    .sclk_in(sclk),
    .mosi_in(mosi),
    .cs_in(cs),
    .miso_out(miso),

    // BRAM Interface
    .addr_out(addr),
    .wdata_out(wdata),
    .rdata_in(rdata),
    .wen_out(wen),
    .en_out(en)
);

// BRAM IP instantiation
blk_mem_gen_0 

blk_mem_gen_0_inst
(
    // bram interface
    .clka       (clk_200mhz),
    .ena        (en),
    .wea        (wen),
    .addra      (addr),
    .dina       (wdata),
    .douta      (rdata) // only output port
);

// Test 1: Write Followed By Read, Connected to BRAM
initial 
begin
    wait(start_test[0]);
    $display("Test 1: Testing SPI Write then Read BRAM Sequence...\n");

    // Write Transaction
    @(sclk_re);
    cs = 1'b0;

    // Shift out RX_HEAD from master
    for (int i = 0; i < DATA_WIDTH; i++)
    begin
        @(posedge sclk_fe);
        mosi = rx_head[(DATA_WIDTH-1)-i];
    end

    // Shift out "write_bram" opcode from master
    for (int i = 0; i < DATA_WIDTH; i++)
    begin
        @(posedge sclk_fe);
        mosi = write_opcode[(DATA_WIDTH-1)-i];
    end

    // Shift out address data from master
    for (int i = 0; i < ADDR_WIDTH; i++)
    begin
        @(posedge sclk_fe);
        mosi = addr_data1[(ADDR_WIDTH-1)-i];
    end

    // Shift out wdata byte from master
    for (int i = 0; i < DATA_WIDTH; i++)
    begin
        @(posedge sclk_fe);
        mosi = wdata_test1[(DATA_WIDTH-1)-i];
    end

    @(posedge sclk_re);
    @(posedge sclk_re);
    @(posedge sclk_re);
    @(posedge sclk_re);
    @(posedge sclk_re);
    cs = 1'b1;

    // Read Transaction
    #(100*SIM_DELAY);
    cs = 1'b0;

    // Shift out RX_HEAD from master
    for (int i = 0; i < DATA_WIDTH; i++)
    begin
        @(posedge sclk_fe);
        mosi = rx_head[(DATA_WIDTH-1)-i];
    end

    // Shift out "read_bram" opcode from master
    for (int i = 0; i < DATA_WIDTH; i++)
    begin
        @(posedge sclk_fe);
        mosi = read_opcode[(DATA_WIDTH-1)-i];
    end

    // Shift out address data from master
    for (int i = 0; i < ADDR_WIDTH; i++)
    begin
        @(posedge sclk_fe);
        mosi = addr_data1[(ADDR_WIDTH-1)-i];
    end

    // Wait for BRAM to be read and SPI transfer back to master to be completed
    
    wait(rdata == wdata_test1)
    $display("Successful readback of data written to BRAM!\n");

    wait(spi2bram_inst.current_state == 4'h6) // when in READ_BRAM_TX state

    for (int i = 0; i < 16; i++)
    begin
        @(posedge sclk_re); 
        read_data_rx[(2*DATA_WIDTH-1)-i] = miso;
    end

    // Check for successful tx of read data back to SPI master
    if (read_data_rx[7:0] == rdata)
    begin
        $display("Test 1 PASS!\n");
        test_summary[0] = 1'b1;
    end

    else
    begin
        $display("Test 1 FAIL!\n");
        test_summary[0] = 1'b0;
        $display("SPI Master Rx'd Read Data: %d", read_data_rx[7:0]);
        $display("Read Data from BRAM: %d", rdata);
    end 

    #(100*SIM_DELAY);
    done_test[0] = 1'b1; 
end


// Testbench Sequence
initial
begin

$display("Start of Simulation, Initializing All Values...\n");
rst_100mhz = 1'b1;
cs = 1'b1;
mosi = 1'b0;
rdata = 8'h0;

// Test 1 Sequence
#(5*SIM_DELAY);
$display("Releasing Reset...\n");
rst_100mhz = 1'b0;

$display("Starting Test 1...\n");
start_test[0] = 1'b1;
wait(done_test[0]);

$display("Simulation Complete!\n");
$stop;
end
endmodule
