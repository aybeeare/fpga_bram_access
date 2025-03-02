This project contains a full host PC to FPGA solution for accessing the BRAM of a Spartan-7 FPGA found on the Arty-S7 dev board. 

The host side runs software that drives a serial port, which connects to an arduino-based MCU acting as a UART to SPI bridge, 
and ultimately to an FPGA which uses custom SPI packets to read and write its embedded BRAM resources. SPI was chosen because 
it is simple, commonly used in embedded systems, and I like it. It could have just as easily been UART, I2C, or whatever else. 

The purpose of this project is to make use of an FPGA's embedded BRAM resources and to serve as a template for future projects 
that desire to use an FPGA's capabilities for some specific application.

Another purpose is also to provide a framework for good engineering practices in both software and firmware design. I believe
software and firmware should be modular, easy to follow, and well documented. RTL testbenches should be self checking and 
well commented as well. These practices enable future me and whoever else is interested to be able to pick up where I left off
with ease and hopefully joy.  





