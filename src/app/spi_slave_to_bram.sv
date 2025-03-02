`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ABR Inc
// Engineer: Aaron Belkin-Rosen
// 
// Create Date: 06/30/2024 02:41:16 PM
// Design Name: 
// Module Name: spi_slave_to_bram
// Project Name: FPGA Mem Interface
// Target Devices: 
// Tool Versions: 
// Description: SPI master from MCU to utilize BRAM on FPGA
// 
// Notes:
// 
// SPI slave designed for SPI Mode 0 operation (master samples on rising edge and
// shifts out on the falling edge (slave samples on rising and shifts out on falling) 
// https://www.analog.com/en/resources/analog-dialogue/articles/introduction-to-spi-interface.html
//
//////////////////////////////////////////////////////////////////////////////////


module spi_slave_to_bram
#(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 13
)

(
    // Ports List
    input  logic                      sys_clk_in,
    input  logic                      sys_rst_in,

    // SPI Interface
    input  logic                      sclk_in,
    input  logic                      mosi_in,
    input  logic                      cs_in,
    output logic                      miso_out,

    // BRAM Interface
    output logic [ADDR_WIDTH-1:0]     addr_out,
    output logic [DATA_WIDTH-1:0]     wdata_out,
    input  logic [DATA_WIDTH-1:0]     rdata_in,
    output logic                      wen_out,
    output logic                      en_out
);

// SM Definition
typedef enum bit [3:0] {IDLE, RX_HEAD, OPCODE, ADDR, WDATA, READ_BRAM, READ_BRAM_TX, WRITE_BRAM, DONE} state;
state current_state;
state next_state;

localparam [7:0] HEAD = 8'hDC;
localparam [7:0] TX_HEAD = 8'hBC;
localparam [7:0] READ_OPCODE = 8'hCB;
localparam [7:0] WRITE_OPCODE = 8'hAB;
localparam int BRAM_READ_DELAY = 1; // BRAM runs at 200 MHz, 2 clock cycles to do read, 1 sys_clk period

// Internal Signals
logic           sclk_r1;
logic           sclk_r2;
logic           sclk_re;
logic           sclk_fe;
logic [7:0]     rdata_r1;
logic [7:0]     rdata_r2;
logic           miso;
logic           mosi_r1;
logic           mosi_r2;

logic           cs_r1;
logic           cs_r2;
logic           cs_fe;

logic [15:0]            read_data_tx;
logic [DATA_WIDTH-1:0]  rx_head;
logic [DATA_WIDTH-1:0]  opcode;
logic [DATA_WIDTH-1:0]  wdata;
logic [ADDR_WIDTH-1:0]  addr;

logic           wen;
logic           en;
logic           addr_done;
logic           rx_head_done;
logic           opcode_done;
logic           wdata_done;
logic           read_bram_done;
logic           read_bram_tx_done;
logic           write_bram_done;

logic [7:0]     counter;


// edge detection assigns
assign cs_fe = cs_r2 & ~cs_r1;
assign sclk_re = ~sclk_r2 & sclk_r1;
assign sclk_fe = sclk_r2 & ~sclk_r1;

// Pipelining
always_ff @(posedge sys_clk_in)
begin
    if (sys_rst_in)
    begin
        sclk_r1 <=  1'b0;
        sclk_r2 <=  1'b0;
        mosi_r1 <=  1'b0;
        mosi_r2 <=  1'b0;
        cs_r1 <=    1'b0;
        cs_r2 <=    1'b0;
        rdata_r1 <= 8'h00;
        rdata_r2 <= 8'h00;
    end

    else // register inputs
    begin
        sclk_r1 <=      sclk_in;
        sclk_r2 <=      sclk_r1;
        mosi_r1 <=      mosi_in;
        mosi_r2 <=      mosi_r1;
        cs_r1 <=        cs_in;
        cs_r2 <=        cs_r1;
        rdata_r1 <=     rdata_in;
        rdata_r2 <=     rdata_r1;
    end
end

// SM Transition Logic 
always_comb
begin
    case(current_state)
        IDLE:
        begin
            if (cs_fe)
            begin
                next_state = RX_HEAD;
            end

            else
            begin
                next_state = IDLE;
            end
        end

        RX_HEAD:
        begin
            if (rx_head_done && rx_head == HEAD)
            begin
                next_state = OPCODE;
            end

            else
            begin
                next_state = RX_HEAD;
            end
        end

        OPCODE:
        begin
            if (opcode_done)
            begin
                next_state = ADDR;
            end

            else
            begin
                next_state = OPCODE;
            end
        end

        ADDR:
        begin
            if (addr_done && opcode == READ_OPCODE)
            begin
                next_state = READ_BRAM;
            end

            else if (addr_done && opcode == WRITE_OPCODE)
            begin
                next_state = WDATA;
            end

            else 
            begin
                next_state = ADDR;
            end
        end

        WDATA:
        begin
            if (wdata_done)
            begin
                next_state = WRITE_BRAM;
            end

            else
            begin
                next_state = WDATA;
            end   
        end

        READ_BRAM:
        begin
            if (read_bram_done)
            begin
                next_state = READ_BRAM_TX;
            end

            else
            begin
                next_state = READ_BRAM;
            end   
        end

        READ_BRAM_TX:
        begin
            if (read_bram_tx_done)
            begin
                next_state = DONE;
            end

            else
            begin
                next_state = READ_BRAM_TX;
            end   
        end

        WRITE_BRAM:
        begin
            if (write_bram_done)
            begin
                next_state = DONE;
            end

            else
            begin
                next_state = WRITE_BRAM;
            end
        end

        DONE:
        begin
            next_state = IDLE;
        end

        default: 
        begin
            next_state = IDLE;
        end
    endcase  
end

// Synchronous Logic
always_ff @(posedge sys_clk_in) 
begin
    if (sys_rst_in)
    begin
        current_state <= IDLE;
    end

    else
    begin
        current_state <= next_state;
    end
end

// SM Output Logic
always_ff @(posedge sys_clk_in)
begin
    case(current_state)
        IDLE:
        begin
            wen <=               1'b0;
            en <=                1'b0;
            counter <=             '0;
            rx_head <=             '0;
            opcode <=              '0;
            addr <=                '0;
            wdata <=               '0;
            read_data_tx <=        '0;
            rx_head_done <=      1'b0;
            opcode_done <=       1'b0;
            addr_done <=         1'b0;
            wdata_done <=        1'b0;
            read_bram_done <=    1'b0;
            read_bram_tx_done <= 1'b0;
            write_bram_done <=   1'b0;
            miso <=              1'b0;   
        end

        RX_HEAD:
        begin
            miso <= 1'b0; 

            if (~rx_head_done && counter < DATA_WIDTH)
            begin
                if (sclk_re)
                begin
                    rx_head <= {rx_head[DATA_WIDTH-2:0], mosi_r2};
                    counter <= counter + 1;
                end
            end

            else
            begin
                rx_head_done <= 1'b1;
                counter <= 0;
            end
        end

        OPCODE:
        begin
            miso <= 1'b0; 

            if (~opcode_done && counter < DATA_WIDTH)
            begin
                if (sclk_re)
                begin
                    opcode <= {opcode[DATA_WIDTH-2:0], mosi_r2};
                    counter <= counter + 1;
                end
            end

            else
            begin
                opcode_done <= 1'b1;
                counter <= 0;
            end
        end

        ADDR:
        begin
            miso <= 1'b0; 

            if (~addr_done && counter < ADDR_WIDTH)
            begin
                if (sclk_re)
                begin
                    addr <= {addr[ADDR_WIDTH-2:0], mosi_r2};
                    counter <= counter + 1;
                end
            end

            else
            begin
                addr_done <= 1'b1;
                counter <= 0;
            end
        end

        WDATA:
        begin
            miso <= 1'b0; 

            if (~wdata_done && counter < DATA_WIDTH)
            begin
                if (sclk_re)
                begin
                    wdata <= {wdata[DATA_WIDTH-2:0], mosi_r2};
                    counter <= counter + 1;
                end
            end

            else
            begin
                wdata_done <= 1'b1;
                counter <= 0;
            end
        end

        READ_BRAM:
        begin
            miso <= 1'b0; 
            
            if (~read_bram_done)
            begin
                wen <= 1'b0;
                en <= 1'b1;

                counter <= counter + 1;

                if (counter > BRAM_READ_DELAY)
                begin
                    read_data_tx <= {TX_HEAD, rdata_r2};
                    read_bram_done <= 1'b1;
                    counter <= '0;
                end
            end
        end

        READ_BRAM_TX:
        begin
            if (~read_bram_tx_done && counter < 16)
            begin
                if (sclk_fe)
                begin
                    miso <= read_data_tx[15 - counter];
                    counter <= counter + 1;
                end
            end

            else
            begin
                read_bram_tx_done <= 1'b1;
                counter <= 0;
            end
        end

        WRITE_BRAM:
        begin
            miso <= 1'b0; 

            if (~write_bram_done)
            begin
                if (sclk_re)
                begin
                    wen <= 1'b1;
                    en <= 1'b1;
                    write_bram_done <= 1'b1;
                end
            end
        end

        DONE:
        begin
            wen <=               1'b0;
            en <=                1'b0;
            counter <=             '0;
            rx_head <=             '0;
            opcode <=              '0;
            addr <=                '0;
            wdata <=               '0;
            read_data_tx <=        '0;
            rx_head_done <=      1'b0;
            opcode_done <=       1'b0;
            addr_done <=         1'b0;
            wdata_done <=        1'b0;
            read_bram_done <=    1'b0;
            read_bram_tx_done <= 1'b0;
            write_bram_done <=   1'b0;
        end
    endcase  
end

// Assign Internals to Output Ports
assign addr_out = addr;
assign wdata_out = wdata;
assign wen_out = wen;
assign en_out = en;
assign miso_out = miso;
    

endmodule
