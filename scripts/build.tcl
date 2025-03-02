# Generic project build tcl script

# read design sources (add one line for each file)
read_verilog -sv "top.sv"

# read ip sources
read_ip path/to/my_ip1.xci
generate_target all [get_ips my_ip1]

read_ip path/to/my_ip2.xci
generate_target all [get_ips my_ip2]

# read constraints
read_xdc "my_constraints.xdc"

# synth
synth_design -top "top" -part "" 
# insert part number in parentheses 

# place and route
opt_design
place_design
route_design

# Timing analysis
report_timing_summary -file reports/timing_summary.rpt
set timing_met [get_property SLACK [get_timing_paths -max_paths 1]]

# Write bitstream if timing met

if {$timing_met >= 0} {
    puts "Timing met! Generating bitstream..."
    write_bitstream -force "output/top.bit"
}

else {
    puts "Timing failed! No bitstream generation."
    exit 1
}
