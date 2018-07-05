# This contains the CL specific constraints for Top level PNR

create_pblock pblock_CL_top
add_cells_to_pblock [get_pblocks pblock_CL_top] [get_cells -quiet -hierarchical -filter {NAME =~ CL/cifar10/vgg/SparseMatMul}]
add_cells_to_pblock [get_pblocks pblock_CL_top] [get_cells -quiet -hierarchical -filter {NAME =~ CL/cifar10/vgg/SparseMatMul_1}]
add_cells_to_pblock [get_pblocks pblock_CL_top] [get_cells -quiet -hierarchical -filter {NAME =~ CL/cifar10/vgg/SparseMatMulSerial}]
add_cells_to_pblock [get_pblocks pblock_CL_top] [get_cells -quiet -hierarchical -filter {NAME =~ CL/cifar10/vgg/SparseMatMulSerial_1}]
resize_pblock [get_pblocks pblock_CL_top] -add {CLOCKREGION_X0Y10:CLOCKREGION_X5Y14}
set_property PARENT pblock_CL [get_pblocks pblock_CL_top]

create_pblock pblock_CL_mid
add_cells_to_pblock [get_pblocks pblock_CL_mid] [get_cells -quiet -hierarchical -filter {NAME =~ CL/cifar10/vgg/SparseMatMulSerial_2}]
#add_cells_to_pblock [get_pblocks pblock_CL_mid] [get_cells [list CL/CL_PCIM_MSTR/PCI_AXI4_REG_SLC]]
resize_pblock [get_pblocks pblock_CL_mid] -add {CLOCKREGION_X0Y5:CLOCKREGION_X3Y9}
set_property PARENT pblock_CL [get_pblocks pblock_CL_mid]

create_pblock pblock_CL_bot
add_cells_to_pblock [get_pblocks pblock_CL_bot] [get_cells -quiet -hierarchical -filter {NAME =~ CL/cifar10/vgg/SparseMatMulSerial_3}]
#Reassign select cells to parent Pblock for better QoR
#set pblock_cells [get_cells {CL/CL_DMA_PCIS_SLV/CL_TST_DDR_D/CL_TST/sync_rst_n_reg CL/CL_DMA_PCIS_SLV/CL_TST_DDR_D/CL_TST/pre_sync_rst_n_reg}]
#add_cells_to_pblock [get_pblocks pblock_CL] $pblock_cells
resize_pblock [get_pblocks pblock_CL_bot] -add {CLOCKREGION_X0Y0:CLOCKREGION_X3Y4}
set_property PARENT pblock_CL [get_pblocks pblock_CL_bot]

set_clock_groups -name TIG_SRAI_1 -asynchronous -group [get_clocks -of_objects [get_pins static_sh/SH_DEBUG_BRIDGE/inst/bsip/inst/USE_SOFTBSCAN.U_TAP_TCKBUFG/O]] -group [get_clocks -of_objects [get_pins SH/kernel_clks_i/clkwiz_sys_clk/inst/CLK_CORE_DRP_I/clk_inst/mmcme3_adv_inst/CLKOUT0]]
set_clock_groups -name TIG_SRAI_2 -asynchronous -group [get_clocks -of_objects [get_pins static_sh/SH_DEBUG_BRIDGE/inst/bsip/inst/USE_SOFTBSCAN.U_TAP_TCKBUFG/O]] -group [get_clocks drck]
set_clock_groups -name TIG_SRAI_3 -asynchronous -group [get_clocks -of_objects [get_pins static_sh/SH_DEBUG_BRIDGE/inst/bsip/inst/USE_SOFTBSCAN.U_TAP_TCKBUFG/O]] -group [get_clocks -of_objects [get_pins static_sh/pcie_inst/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]]


