// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.
#ifndef COMMON_DMA_H_
#define COMMON_DMA_H_

#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <poll.h>

#ifdef SV_TEST
   #include <fpga_pci_sv.h>
#else
   #include <fpga_pci.h>
   #include <fpga_mgmt.h>
   #include <utils/lcd.h>
#endif


static const size_t buffer_size = 8192;
int channel;
int error_count;
char *write_buffer, *read_buffer;

#define	MEM_16G		(1ULL << 34)

void usage(const char* program_name);

void rand_string(char *str, size_t size);

void fpga_write_buffer_to_cl(int slot_id, int channel, int fd, size_t buffer_size, size_t address);

void fpga_read_cl_to_buffer(int slot_id, int channel, int fd, size_t buffer_size, size_t address);

int dma_example_hwsw_cosim(int slot_id);

int dma_example(int slot_id);

int open_dma_queue(int slot_id, int *write_fd, int *read_fd);

#endif
