ROOT_DIR:=../../../..

BOARD=ZCU102
BOARD_SERVER=$(ZCU102_SERVER)
BOARD_USER=$(ZCU102_USER)

DEVICE=xczu9eg-ffvb1156-2-e

#specify any conditions that prevent running this FPGA
NORUN = 0

#DDR controller address and data widths
DDR_ADDR_W=29
DDR_DATA_W=128

VHDR+=ddr4_axi_wire.vh
ddr4_axi_wire.vh:
	$(LIB_DIR)/software/python/axi_gen.py axi_wire 'ddr4_' 'ddr4_' 'ddr4_'

include ../vivado.mk
