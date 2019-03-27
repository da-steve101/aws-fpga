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
#include <math.h>

#include <utils/sh_dpi_tasks.h>

#ifdef SV_TEST
   #include "fpga_pci_sv.h"
#endif

#include "common_dma.h"
#include "dataset.h"

#ifndef SV_TEST
/* use the stdout logger */
const struct logger *logger = &logger_stdout;
#endif

//Main will be different for different simulators and also for C. The definition is in sdk/userspace/utils/include/sh_dpi_tasks.h file
#ifdef SV_TEST
//For cadence and questa simulators the main has to return some value
   #ifdef INT_MAIN
   int test_main(uint32_t *exit_code) {
   #else
   void test_main(uint32_t *exit_code) {
   #endif
#else
    int main(int argc, char **argv) {
#endif
    //The statements within SCOPE ifdef below are needed for HW/SW co-simulation with VCS
#ifdef SCOPE
  svScope scope;
  scope = svGetScopeFromName("tb");
  svSetScope(scope);
#endif

    int rc;
    int slot_id = 0;

#ifndef SV_TEST
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

    channel = 0;
    error_count = 0;

    /* setup logging to print to stdout */
    rc = log_init("test_dram_dma_hwsw_cosim");
    fail_on(rc, out, "Unable to initialize the log.");
    rc = log_attach(logger, NULL, 0);
    fail_on(rc, out, "%s", "Unable to attach to the log.");

    /* initialize the fpga_plat library */
    rc = fpga_mgmt_init();
    fail_on(rc, out, "Unable to initialize the fpga_mgmt library");

#endif

    rc = dma_example_hwsw_cosim(slot_id);

    fail_on(rc, out, "DMA example failed");

out:

   if (error_count > 0) {
      printf("TEST FAILED \n");
   }
   else {
      printf("TEST PASSED \n");
   }
   //For cadence and questa simulators the main has to return some value
   #ifdef INT_MAIN
   *exit_code = 0;
   return 0;
   #else
   *exit_code = 0;
   #endif
}

char * fill_image_inputs( const unsigned long ** img_list, int n ) {
  int i, j, k, idx, image_size;
  image_size = 8192;
  for ( j = 0; j < buffer_size/image_size; j++ ) {
    const unsigned long * img = img_list[j % n];
    for ( i = 0; i < image_size/64; i++ ) {
      for ( k = 0; k < 64; k++ ) {
	idx = ( ( image_size - (i+1)*64 + k )/8 ) % 1024;
	write_buffer[j*image_size + i*64 + k] = ( img[ idx ] >> (8*( k % 8 ) ) ) % 256;
      }
    }
  }
  return write_buffer;
}

float get_mean_of_img( char * img, int n ) {
  float sum = 0;
  int i;
  for ( i = 0; i < n; i++ )
    sum += (int)img[i];
  return sum/n;
}

float get_std_of_img( char * img, float mean, int n ) {
  float sum = 0;
  int i;
  for ( i = 0; i < n; i++ )
    sum += pow( ((float)img[i]) - mean, 2 );
  float std = sqrt( sum / n );
  if ( std < 1.0/n )
    return 1.0/n;
  return std;
}

short convert_rgb_to_fixed( char x, float mean, float std ) {
  float scaled = ( ((float)x) - mean )/ std;
  scaled *= ( 1 << 4 );
  return (short) scaled;
}

struct cifar_dataset * cifar_testset() {
  unsigned long ** imgs;
  char * labels;
  imgs = (unsigned long ** )malloc( cifar_no_imgs * sizeof( unsigned long *) );
  labels = (char *)malloc( cifar_no_imgs );
  struct cifar_dataset * dataset = (struct cifar_dataset * )malloc( sizeof( struct cifar_dataset ) );
  dataset->no_imgs = cifar_no_imgs;
  dataset->imgs = imgs;
  dataset->labels = labels;
  FILE * fp = fopen( cifar_fname, "r" );
  int i, j;
  // char * img_tmp = (char*)malloc( 3*1024 );
  char img_tmp[3*1024];
  printf( "begin load\n" );
  for ( i = 0; i < cifar_no_imgs; i++ ) {
    unsigned long * img = (unsigned long*)malloc( 1024*sizeof( unsigned long ) );
    printf( "malloc done\n" );
    fgets( &(labels[i]), 1, fp );
    fgets( img_tmp, 3*1024, fp );
    float mean = get_mean_of_img( img_tmp, 3*1024 );
    float std = get_std_of_img( img_tmp, mean, 3*1024 );
    for ( j = 0; j < 1024; j++ ) {
      unsigned long r = (unsigned long)convert_rgb_to_fixed( img_tmp[j], mean, std );
      unsigned long g = (unsigned long)convert_rgb_to_fixed( img_tmp[1024 + j], mean, std );
      unsigned long b = (unsigned long)convert_rgb_to_fixed( img_tmp[2*1024 + j], mean, std );
      // need scaling of image
      img[j] = ( b << ( 8*4 ) ) | ( g << ( 8*2 ) ) | r;
    }
    imgs[i] = img;
  }
  printf( "end loop\n" );
  // free( img_tmp );
  return dataset;
}

int cmp_image_outputs( const unsigned long ** img_list, int n ) {
  int i, j, idx, image_size;
  image_size = 8192;
  char * res_image = (char*)malloc( buffer_size );
  for ( j = 0; j < buffer_size/image_size; j++ ) {
    const unsigned long * img = img_list[j % n];
    for ( i = 0; i < image_size; i++ ) {
      idx = ( ( image_size - i - 1 )/8 ) % 1024;
      res_image[j*image_size + i] = ( img[ idx ] >> (8*( i % 8 )) ) % 256;
    }
  }
  int cmp = memcmp( read_buffer, res_image, buffer_size );
  if( cmp != 0 ) {
    error_count += 1;
    printf("Read:\n" );
    for ( i = 0; i < buffer_size; i++ )
      printf( "%02x", read_buffer[i] & 0xff );
    printf( "\n\n" );
    printf("Expected:\n" );
    for ( i = 0; i < buffer_size; i++ )
      printf( "%02x", res_image[i] & 0xff );
    printf( "\n\n" );
  } else
    printf( "matched\n" );
  return cmp;
}

/*
 * Write 4 identical buffers to the 4 different DRAM channels of the AFI
 */

int dma_example_hwsw_cosim(int slot_id) {
  int write_fd, read_fd, rc, i;

    read_buffer = NULL;
    write_buffer = NULL;
    write_fd = -1;
    read_fd = -1;

    write_buffer = (char *)malloc(buffer_size + 8);
    read_buffer = (char *)malloc(buffer_size + 8);
    if (write_buffer == NULL || read_buffer == NULL) {
        rc = -ENOMEM;
        goto out;
    }

#ifndef SV_TEST
    rc = open_dma_queue(slot_id, &write_fd, &read_fd);
    fail_on(rc, out, "open_dma_queue failed");
#else
    init_ddr();
#endif
    printf( "start ...\n" );
    struct cifar_dataset * dataset = cifar_testset();
    printf( "make testset\n" );
    // fill_image_inputs( sample_img_inputs, 10 );
    fill_image_inputs( dataset->imgs, dataset->no_imgs );
    printf( "fill buffer\n" );
    channel=0;
    sv_fpga_start_buffer_to_cl(slot_id, channel, buffer_size, write_buffer, 0);
    sv_fpga_start_buffer_to_cl(slot_id, channel, buffer_size, write_buffer, buffer_size);
    sv_fpga_start_buffer_to_cl(slot_id, channel, buffer_size, write_buffer, 2*buffer_size);
    sv_fpga_start_buffer_to_cl(slot_id, channel, buffer_size, write_buffer, 3*buffer_size);
    printf( "write loop start\n" );
    for ( int addr = 0; addr < buffer_size; addr += buffer_size ) {
      sv_fpga_start_buffer_to_cl(slot_id, channel, buffer_size, write_buffer, addr + 4*buffer_size);
      sv_pause(30);
      sv_fpga_start_cl_to_buffer(slot_id, channel, buffer_size, addr);
      printf( "cmp start\n" );
      cmp_image_outputs( sample_img_outputs, 10 );
    }

out:

#ifndef SV_TEST
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
#else
    return 0;
#endif
}
