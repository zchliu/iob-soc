#
# SYNTHESIS AND IMPLEMENTATION SCRIPT
#

#select top module and FPGA decive
set TOP top_system
set INCLUDE [lindex $argv 0]
set DEFINE [lindex $argv 1]
set VSRC [lindex $argv 2]
set DEVICE [lindex $argv 3]

set USE_DDR [string last "USE_DDR" $DEFINE]

#verilog sources
foreach file [split $VSRC \ ] {
    if {$file != ""} {
        read_verilog -sv $file
    }
}

set_property part $DEVICE [current_project]
read_xdc ./top_system.xdc

if { $USE_DDR < 0 } {
    read_verilog verilog/clock_wizard.v
} else {


    if { ![file isdirectory "./ip"]} {
        file mkdir ./ip
    }

    #async interconnect MIG<->Cache
    if { [file isdirectory "./ip/axi_interconnect_0"] } {
        read_ip ./ip/axi_interconnect_0/axi_interconnect_0.xci
        report_property [get_files ./ip/axi_interconnect_0/axi_interconnect_0.xci]
    } else {

        create_ip -name axi_interconnect -vendor xilinx.com -library ip -version 1.7 -module_name axi_interconnect_0 -dir ./ip -force

        set_property -dict \
            [list \
                 CONFIG.NUM_SLAVE_PORTS {1}\
                 CONFIG.AXI_ADDR_WIDTH {29}\
                 CONFIG.ACLK_PERIOD {3333} \
                 CONFIG.INTERCONNECT_DATA_WIDTH {128}\
                 CONFIG.M00_AXI_IS_ACLK_ASYNC {1}\
                 CONFIG.M00_AXI_WRITE_FIFO_DEPTH {32}\
                 CONFIG.M00_AXI_READ_FIFO_DEPTH {32}\
                 CONFIG.S00_AXI_IS_ACLK_ASYNC {1}\
                 CONFIG.S00_AXI_READ_FIFO_DEPTH {32}\
                 CONFIG.S00_AXI_WRITE_FIFO_DEPTH {32}] [get_ips axi_interconnect_0]

        generate_target all [get_files ./ip/axi_interconnect_0/axi_interconnect_0.xci]

        report_property [get_ips axi_interconnect_0]
        report_property [get_files ./ip/axi_interconnect_0/axi_interconnect_0.xci]
        exec sed -i s/100/5/g ip/axi_interconnect_0/axi_interconnect_0_ooc.xdc
        synth_ip [get_files ./ip/axi_interconnect_0/axi_interconnect_0.xci]

    }
    
    if { [file isdirectory "./ip/ddr4_0"] } {
	read_ip ./ip/ddr4_0/ddr4_0.xci
        report_property [get_files ./ip/ddr4_0/ddr4_0.xci]
    } else {

        create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name ddr4_0 -dir ./ip -force
        
        set_property -dict \
        [list \
             CONFIG.C0.DDR4_TimePeriod {833} \
             CONFIG.C0.DDR4_InputClockPeriod {3332} \
             CONFIG.C0.DDR4_CLKOUT0_DIVIDE {5} \
             CONFIG.C0.DDR4_MemoryPart {MT40A256M16GE-075E} \
             CONFIG.C0.DDR4_DataWidth {16} \
             CONFIG.C0.DDR4_AxiSelection {true} \
             CONFIG.C0.DDR4_CasLatency {18} \
             CONFIG.C0.DDR4_CasWriteLatency {12} \
             CONFIG.C0.DDR4_AxiDataWidth {128} \
             CONFIG.C0.DDR4_AxiAddressWidth {29} \
             CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {100} \
             CONFIG.C0.BANK_GROUP_WIDTH {1}] [get_ips ddr4_0]
	
        generate_target all [get_files ./ip/ddr4_0/ddr4_0.xci]

        report_property [get_ips ddr4_0]
        report_property [get_files ./ip/ddr4_0/ddr4_0.xci]

        synth_ip [get_files ./ip/ddr4_0/ddr4_0.xci]
    }

    read_xdc ./ddr.xdc

}

synth_design -include_dirs $INCLUDE -verilog_define $DEFINE -part $DEVICE -top $TOP

opt_design

place_design

route_design

report_utilization

report_timing

file mkdir reports

report_timing -file reports/timing.txt -max_paths 30
report_clocks -file reports/clocks.txt
report_clock_interaction -file reports/clock_interaction.txt
report_cdc -details -file reports/cdc.txt
report_synchronizer_mtbf -file reports/synchronizer_mtbf.txt
report_utilization -hierarchical -file reports/utilization.txt

write_bitstream -force top_system.bit

write_verilog -force top_system.v

# write_project_tcl ./project_create.tcl