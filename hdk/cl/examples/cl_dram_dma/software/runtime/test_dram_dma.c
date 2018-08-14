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
#include <pthread.h>
#include <semaphore.h>
#include <time.h>

#include "common_dma.h"
#include "airplane.h"
#include "automobile.h"
#include "bird.h"
#include "cat.h"
#include "deer.h"
#include "dog.h"
#include "frog.h"
#include "horse.h"
#include "ship.h"
#include "truck.h"

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
    return rc;
}

struct image_info {
  char * buffer;
  sem_t * cnt;
  sem_t * neg_cnt;
  sem_t * syncd;
  sem_t * neg_syncd;
  int buffer_size;
  int image_size;
  int fd;
  int slot_id;
};

// thread to copy images into mem
// have a semaphore to get available slots
void* copy_into_mem( void * args ) {
  struct image_info * image_buffer = ( struct image_info * ) args;
  int i, idx, addr;
  addr = 0;
  char * airplane = (char*)malloc( image_buffer->image_size );
  for ( i = 0; i < image_buffer->image_size; i++ ) {
    idx = ( image_buffer -> image_size - i - 1 )/8;
    airplane[i] = ( airplane4_image[ idx ] >> (8*( i % 8 )) ) % 256;
  }
  while ( 1 ) {
    // copy up to 3 into buffer
    sem_wait( image_buffer->neg_cnt ); // blocking here ...
    memcpy( image_buffer->buffer + addr, airplane, image_buffer->image_size );
    addr = ( addr + image_buffer->image_size ) % image_buffer->buffer_size;
    // ready to copy to fpga
    sem_post( image_buffer->cnt );
  }
  free( airplane );
  printf( "mem done\n" );
  return NULL;
}

// thread to copy images to FPGA
void * copy_to_fpga( void * args ) {
  struct image_info * image_buffer = ( struct image_info * ) args;
  int wrt_ch = 0;
  int addr = 0;
  int rc, i;
  // FILE * fp = fdopen( image_buffer->fd, "w" );
  while( 1 ) {
    // if there is enough space in fpga queue
    sem_wait( image_buffer->neg_syncd );
    // when image ready to copy
    sem_wait( image_buffer->cnt );
    for ( i = 0; i < 8; i++ ) {
      rc = pwrite( image_buffer->fd, (char*)(image_buffer->buffer + i*buffer_size + addr), buffer_size, 0x10000000 + wrt_ch*MEM_16G );
      if ( rc != buffer_size )
        printf( "write error %d\n", rc );
    }
    /*
    fseek( fp, 0x10000000 + wrt_ch*MEM_16G, SEEK_SET );
    rc = fwrite( (char*)(image_buffer->buffer + addr),
		 1,
		 image_buffer->image_size,
		 fp );
    if ( rc != image_buffer->image_size )
      printf( "write error %d\n", rc );
    */
    sem_post( image_buffer->neg_cnt );
    fsync( image_buffer->fd );
    sem_post( image_buffer->syncd );
    addr = ( addr + image_buffer->image_size ) % image_buffer->buffer_size;
  }
  printf( "to fpga done\n" );
  return NULL;
}

// thread to copy result from FPGA to mem
void * copy_from_fpga( void * args ) {
  struct image_info * image_buffer = ( struct image_info * ) args;
  int rd_ch = 1;
  int addr = 0;
  int rc, i;
  // FILE * fp = fdopen( image_buffer->fd, "r" );
  while( 1 ) {
    // if an image is ready
    sem_wait( image_buffer->syncd );
    // if there is enough space to copy out
    sem_wait( image_buffer->neg_cnt ); // blocking here ...
    for ( i = 0; i < 8; i++ ) {
      rc = pread( image_buffer->fd,
	(char*)(image_buffer->buffer + i*buffer_size + addr),
	buffer_size,
	0x10000000 + rd_ch*MEM_16G);
      /*
      fseek( fp, 0x10000000 + rd_ch*MEM_16G, SEEK_SET );
      rc = fread( (char*)(image_buffer->buffer + i*buffer_size + addr),
		  1,
		  buffer_size,
		  fp );
      */
      if ( rc != buffer_size )
	printf( "read error %d\n", rc );
    }
    sem_post( image_buffer->cnt );
    sem_post( image_buffer->neg_syncd );
    addr = ( addr + image_buffer->image_size ) % image_buffer->buffer_size;
  }
  printf( "from fpga done\n" );
  return NULL;
}

int verify_result( struct image_info * image_buffer ) {
  // measure throughput here ...
  int i, idx;
  int addr = 0;
  clock_t start_time = clock();
  int img_cnt = 0;
  char * airplane_out = (char*)malloc( image_buffer->image_size );
  for ( i = 0; i < image_buffer -> image_size; i++ ) {
    idx = ( image_buffer -> image_size - i - 1 )/8;
    airplane_out[i] = ( airplane4_mp_3[ idx ] >> (8*( i % 8 )) ) % 256;
  }
  while( 1 ) {
    sem_wait( image_buffer->cnt ); // blocking here
    if ( memcmp( image_buffer->buffer + addr, airplane_out, image_buffer->image_size ) ) {
      printf( "mismatch %d\n", img_cnt );
      return 1;
    }
    sem_post( image_buffer->neg_cnt );
    img_cnt += 1;
    addr = ( addr + image_buffer->image_size ) % image_buffer->buffer_size;
    if ( img_cnt % 10000 == 0 ) {
      clock_t diff = clock() - start_time;
      double secs = ((double)diff)/CLOCKS_PER_SEC;
      printf( "rate = %f images/sec\n", img_cnt/secs );
    }
  }
  free( airplane_out );
  printf( "verify done\n" );
  return 0;
}

/*
 * Write 4 identical buffers to the 4 different DRAM channels of the AFI
 */
int dma_example(int slot_id) {
    int image_size = 8192;
    struct image_info image_in, image_out;
    int sem_cnt = 4;
    sem_t * syncd = ( sem_t * ) malloc( sizeof(sem_t) );
    sem_t * neg_syncd = ( sem_t * ) malloc( sizeof(sem_t) );
    image_in.cnt = ( sem_t * ) malloc( sizeof(sem_t) );
    image_out.cnt = ( sem_t * ) malloc( sizeof(sem_t) );
    image_in.neg_cnt = ( sem_t * ) malloc( sizeof(sem_t) );
    image_out.neg_cnt = ( sem_t * ) malloc( sizeof(sem_t) );
    image_in.syncd = syncd;
    image_out.syncd = syncd;
    image_in.neg_syncd = neg_syncd;
    image_out.neg_syncd = neg_syncd;
    image_in.buffer_size = image_size * sem_cnt;
    image_out.buffer_size = image_size * sem_cnt;
    image_in.image_size = image_size;
    image_out.image_size = image_size;
    sem_init( image_in.cnt, 0, 0 );
    sem_init( image_out.cnt, 0, 0 );
    sem_init( image_in.neg_cnt, 0, sem_cnt );
    sem_init( image_out.neg_cnt, 0, sem_cnt );
    sem_init( syncd, 0, 0 );
    sem_init( neg_syncd, 0, sem_cnt );
    image_in.slot_id = slot_id;
    image_out.slot_id = slot_id;
    image_in.buffer = (char*) malloc( image_in.buffer_size  );
    image_out.buffer = (char*) malloc( image_out.buffer_size  );
    int write_fd, read_fd;

    read_buffer = NULL;
    write_buffer = NULL;
    write_fd = -1;
    read_fd = -1;

    open_dma_queue(slot_id, &write_fd, &read_fd);

    image_in.fd = write_fd;
    image_out.fd = read_fd;

    pthread_t * cpy_to_mem_thd = (pthread_t *)malloc(sizeof(pthread_t));
    pthread_t * cpy_to_fpga_thd = (pthread_t *)malloc(sizeof(pthread_t));
    pthread_t * cpy_from_fpga_thd = (pthread_t *)malloc(sizeof(pthread_t));

    pthread_create(cpy_to_mem_thd, NULL, (void*)copy_into_mem, &image_in );
    pthread_create(cpy_to_fpga_thd, NULL, (void*)copy_to_fpga, &image_in );
    pthread_create(cpy_from_fpga_thd, NULL, (void*)copy_from_fpga, &image_out );
    //copy_into_mem( &image_in );
    // copy_to_fpga( &image_in );
    // copy_from_fpga( &image_out );
    verify_result( &image_out );

    free(image_in.buffer);
    free(image_out.buffer);
    free(image_in.cnt);
    free(image_out.cnt);
    free(image_in.neg_cnt);
    free(image_out.neg_cnt);
    free( cpy_to_mem_thd );
    free( cpy_to_fpga_thd );
    free( cpy_from_fpga_thd );
    free( syncd );
    free( neg_syncd );
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
    return 0;
}
