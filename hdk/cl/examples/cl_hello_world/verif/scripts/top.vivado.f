# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

-define VIVADO_SIM

-sourcelibext .v
-sourcelibext .sv
-sourcelibext .svh

-sourcelibdir ${CL_ROOT}/../common/design
-sourcelibdir ${CL_ROOT}/design
-sourcelibdir ${CL_ROOT}/verif/sv
-sourcelibdir ${SH_LIB_DIR}
-sourcelibdir ${SH_INF_DIR}
-sourcelibdir ${SH_SH_DIR}
-sourcelibdir ${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/hdl
-sourcelibdir ${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/sim

-include ${CL_ROOT}/../common/design
-include ${CL_ROOT}/verif/sv
-include ${SH_LIB_DIR}
-include ${SH_INF_DIR}
-include ${SH_SH_DIR}
-include ${HDK_COMMON_DIR}/verif/include
-include ${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/ip/ip_0/hdl/verilog
-include ${HDK_SHELL_DESIGN_DIR}/ip/axi_register_slice_light/hdl

${CL_ROOT}/../common/design/cl_common_defines.vh
${CL_ROOT}/design/cl_hello_world_defines.vh
${CL_ROOT}/design/cl_hello_world_pkg.sv
${HDK_SHELL_DESIGN_DIR}/ip/ila_vio_counter/sim/ila_vio_counter.v
${HDK_SHELL_DESIGN_DIR}/ip/ila_0/sim/ila_0.v
${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/hdl/bd_a493.v
${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/ip/ip_0/sim/bd_a493_xsdbm_0.v
${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/ip/ip_0/hdl/xsdbm_v3_0_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/ip/ip_0/hdl/ltlib_v1_0_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/ip/ip_1/sim/bd_a493_lut_buffer_0.v
${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/ip/ip_1/hdl/lut_buffer_v2_0_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/bd_0/hdl/bd_a493_wrapper.v
${HDK_SHELL_DESIGN_DIR}/ip/cl_debug_bridge/sim/cl_debug_bridge.v
${HDK_SHELL_DESIGN_DIR}/ip/vio_0/sim/vio_0.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_register_slice_light/sim/axi_register_slice_light.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_register_slice/sim/axi_register_slice.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_dwidth_converter_512_to_64/sim/axi_dwidth_converter_512_to_64.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_dwidth_converter_64_to_512/sim/axi_dwidth_converter_64_to_512.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_data_fifo_sync_64/sim/axi_data_fifo_sync_64.v
${HDK_SHELL_DESIGN_DIR}/ip/fifo_1024bits/sim/fifo_1024bits.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_register_slice_light/hdl/axi_register_slice_v2_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_register_slice_light/hdl/axi_infrastructure_v1_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_dwidth_converter_512_to_64/hdl/axis_dwidth_converter_v1_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_dwidth_converter_512_to_64/hdl/axis_infrastructure_v1_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_dwidth_converter_512_to_64/hdl/axis_register_slice_v1_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_dwidth_converter_64_to_512/hdl/axis_dwidth_converter_v1_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_dwidth_converter_64_to_512/hdl/axis_infrastructure_v1_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_dwidth_converter_64_to_512/hdl/axis_register_slice_v1_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_data_fifo_sync_64/hdl/axis_data_fifo_v1_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_data_fifo_sync_64/hdl/axis_infrastructure_v1_1_vl_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/axi_data_fifo_sync_64/hdl/fifo_generator_v13_1_rfs.v
${HDK_SHELL_DESIGN_DIR}/ip/fifo_1024bits/hdl/fifo_generator_v13_1_rfs.v
${SH_LIB_DIR}/../ip/axi_clock_converter_0/sim/axi_clock_converter_0.v
${CL_ROOT}/design/Queue_1024.v
${CL_ROOT}/design/Queue_2048.v
${CL_ROOT}/design/Queue_4096.v
${CL_ROOT}/design/Vgg7.v
${CL_ROOT}/design/AWSVggWrapper.v
${CL_ROOT}/design/cl_hello_world.sv

-f ${HDK_COMMON_DIR}/verif/tb/filelists/tb.${SIMULATOR}.f

${TEST_NAME}
