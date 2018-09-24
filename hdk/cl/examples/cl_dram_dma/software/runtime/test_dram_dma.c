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

#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <poll.h>

#include "common_dma.h"

#define	MEM_16G		(1ULL << 34)
#define USER_INTERRUPTS_MAX  (16)

#ifndef SV_TEST
/* use the stdout logger */
const struct logger *logger = &logger_stdout;
#endif

int main(int argc, char **argv) {
    int rc;
    int slot_id = 0;

    switch (argc) {
    case 1:
        break;
    case 3:
        sscanf(argv[2], "%x", &slot_id);
        break;
    default:
        usage(argv[0]);
        return 1;
    }

    error_count = 0;

    /* setup logging to print to stdout */
    rc = log_init("test_dram_dma");
    fail_on(rc, out, "Unable to initialize the log.");
    rc = log_attach(logger, NULL, 0);
    fail_on(rc, out, "%s", "Unable to attach to the log.");

    /* initialize the fpga_plat library */
    rc = fpga_mgmt_init();
    fail_on(rc, out, "Unable to initialize the fpga_mgmt library");

    rc = dma_example(slot_id);
    fail_on(rc, out, "DMA example failed");

out:
    if (rc || (error_count > 0)) {
        printf("TEST FAILED \n");
	rc = (rc) ? rc : 1;
    }
    else {
        printf("TEST PASSED \n");
    }
    return rc;
}

/* 
 * Write 4 identical buffers to the 4 different DRAM channels of the AFI
 */

int dma_example(int slot_id) {
    int write_fd, read_fd, rc;

    read_buffer = NULL;
    write_buffer = NULL;
    write_fd = -1;
    read_fd = -1;

    write_buffer = (char *)malloc(buffer_size);
    read_buffer = (char *)malloc(buffer_size);
    if (write_buffer == NULL || read_buffer == NULL) {
        rc = -ENOMEM;
        goto out;
    }

    rc = open_dma_queue(slot_id, &write_fd, &read_fd);
    fail_on(rc, out, "open_dma_queue failed");

    channel = 0;
    for ( int addr = 0; addr < buffer_size; addr += buffer_size ) {
        rand_string(write_buffer, buffer_size);
        fpga_write_buffer_to_cl(slot_id, channel, write_fd, buffer_size, (0x00000000 + channel*MEM_16G + addr));
        fpga_read_cl_to_buffer(slot_id, channel, read_fd, buffer_size, (0x00000000 + channel*MEM_16G + addr));
    }

out:
    if (write_buffer != NULL) {
        free(write_buffer);
    }
    if (read_buffer != NULL) {
        free(read_buffer);
    }
    if (write_fd >= 0) {
        close(write_fd);
    }
    if (read_fd >= 0) {
        close(read_fd);
    }
    /* if there is an error code, exit with status 1 */
    return (rc != 0 ? 1 : 0);
}
