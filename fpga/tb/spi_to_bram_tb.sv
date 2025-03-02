`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2025 10:31:15 PM
// Design Name: 
// Module Name: spi_to_bram_tb
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


module spi_to_bram_tb(
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
logic [DATA_WIDTH-1:0] read_data;
logic [2*DATA_WIDTH-1:0] read_data_rx = 0;

// Testbench signals
logic [3:0] start_test = '0;
logic [3:0] done_test = '0;
logic [2:0] test_summary = '0;


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



// Test 1: Test SPI Read BRAM Opcode
initial 
begin
    wait(start_test[0]);
    $display("Test 1: Testing SPI Read BRAM Sequence...\n");

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

    for (int i = 0; i < DATA_WIDTH; i++)
    begin
        @(posedge sclk_fe);
        read_data[(DATA_WIDTH-1)-i] = miso;
    end

    // Sample slave as master to ensure SPI transactions were correct

    wait(spi2bram_inst.current_state == 4'h6) // when in READ_BRAM_TX state

    for (int i = 0; i < 16; i++)
    begin
        @(posedge sclk_re); 
        read_data_rx[(2*DATA_WIDTH-1)-i] = miso;
    end

    if (spi2bram_inst.read_data_tx == read_data_rx[7:0])
    begin
        $display("Test 1 PASS!\n");
        test_summary[0] = 1'b1;
    end

    else
    begin
        $display("Test 1 FAIL!\n");
        test_summary[0] = 1'b0;
        $display("Internal Read Data: %d", spi2bram_inst.read_data_tx);
        $display("Read Data RX: %d", read_data_rx[7:0]);
    end   

    #(100*SIM_DELAY);
    done_test[0] = 1'b1;
end

// Test 2: Test SPI Write BRAM Opcode
initial 
begin
    wait(start_test[1]);
    $display("Test 2: Testing SPI Write BRAM Sequence...\n");

    #(100*SIM_DELAY);
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

    wait(spi2bram_inst.wdata_done);
    if (spi2bram_inst.wdata == wdata_test1)
    begin
        $display("Test 2 PASS!\n");
    end

    else
    begin
        $display("Test 2 FAIL!\n");
        $display("Wdata Internal: %x", spi2bram_inst.wdata);
        $display("Wdata Sent: %x", wdata_test1);
    end   

    #(100*SIM_DELAY);
    done_test[1] = 1'b1;
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
$display("Re-Initializing Values\n");

rst_100mhz = 1'b1;
cs = 1'b1;
mosi = 1'b0;
rdata = 8'h0;

// Test 2 Sequence
#(5*SIM_DELAY);
$display("Releasing Reset...\n");
rst_100mhz = 1'b0;

$display("Starting Test 2..\n");
start_test[1] = 1'b1;
wait(done_test[1]);

$display("Simulation Complete!\n");
$stop;
end
endmodule
