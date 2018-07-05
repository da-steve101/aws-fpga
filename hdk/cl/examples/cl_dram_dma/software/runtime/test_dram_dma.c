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
#include "airplane.h"

#define	MEM_16G		(1ULL << 34)

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
    return rc;
}

/* 
 * Write 4 identical buffers to the 4 different DRAM channels of the AFI
 * using fsync() between the writes and read to insure order
 */

int dma_example(int slot_id) {
    int fd;
    int image_size = 8192;
    char * image_in, * image_out;
    int i, idx;

    read_buffer = NULL;
    write_buffer = NULL;
    fd = -1;

    write_buffer = (char *)malloc(buffer_size);
    read_buffer = (char *)malloc(buffer_size);
    image_in = (char*) malloc( image_size );
    image_out = (char*) malloc( image_size );
    if (write_buffer == NULL || read_buffer == NULL) {
        goto out;
    }

    fd = open_dma_queue(slot_id);

    for ( i = 0; i < image_size; i++ ) {
      idx = ( image_size - i - 1 )/8;
      image_in[i] = ( airplane4_image[ idx ] >> (8*( i % 8 )) ) % 256;
      image_out[i] = ( airplane4_mp_3[ idx ] >> (8*( i % 8 )) ) % 256;
    }

    int wrt_ch = 0;
    int rd_ch = 1;
    for ( i = 0; i < 8; i++ ) {
      memcpy( write_buffer, (char*)(image_in + buffer_size*i), buffer_size );
      fpga_write_buffer_to_cl(slot_id, wrt_ch, fd, buffer_size, (0x10000000 + wrt_ch*MEM_16G));
    }

    for ( i = 0; i < 8; i++ ) {
      fpga_read_cl_to_buffer(slot_id, rd_ch, fd, buffer_size, (0x10000000 + rd_ch*MEM_16G));
      dma_memcmp( (char*)(image_out + buffer_size*i), buffer_size );
    }

out:
    free(image_in);
    free(image_out);
    if (write_buffer != NULL) {
        free(write_buffer);
    }
    if (read_buffer != NULL) {
        free(read_buffer);
    }
    if (fd >= 0) {
        close(fd);
    }
    /* if there is an error code, exit with status 1 */
    return 0;
}
