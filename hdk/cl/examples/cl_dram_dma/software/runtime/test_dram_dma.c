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
  int buffer_size;
  int image_size;
  sem_t * wrt_ahead;
  sem_t * rd_ahead;
  int fd;
  char * buffer;
};

// thread to copy images to FPGA
void * copy_to_fpga( void * args ) {
  struct image_info * image_buffer = ( struct image_info * ) args;
  long addr = 0;
  int i, j, k, j_idx, rc, idx;
  char * img_buf_a, *img_buf_b, * tmp_buff;
  char * src_imgs;
  int no_imgs = image_buffer->buffer_size/image_buffer->image_size;
  j_idx = 0;
  posix_memalign((void**)&(src_imgs), 4096, 10*image_buffer->image_size);
  posix_memalign((void**)&(img_buf_a), 4096, image_buffer->buffer_size);
  posix_memalign((void**)&(img_buf_b), 4096, image_buffer->buffer_size);
  const unsigned long * img_list[10] = { airplane4_image, automobile5_image, bird10_image,
					 cat9_image, deer7_image, dog9_image, frog10_image,
					 horse5_image, ship7_image, truck8_image };
  for ( j = 0; j < 10; j++ ) {
    const unsigned long * img = img_list[j % 10];
    for ( i = 0; i < image_buffer->image_size/64; i++ ) {
      for ( k = 0; k < 64; k++ ) {
	idx = ( ( image_buffer->image_size - (i+1)*64 + k )/8 ) % 1024;
	src_imgs[j*image_buffer->image_size + i*64 + k] = ( img[ idx ] >> (8*( k % 8 ) ) ) % 256;
      }
    }
  }
  j_idx = 0;
  while( 1 ) {
    for( j = 0; j < no_imgs; j++ ) {
      memcpy( ( char*)( img_buf_a + j*image_buffer->image_size ),
	      src_imgs + j_idx*image_buffer->image_size,
	      image_buffer->image_size );
      j_idx = ( j_idx + 1 ) % 10;
    }
    sem_wait( image_buffer->wrt_ahead );
    sem_post( image_buffer->rd_ahead );
    rc = pwrite( image_buffer->fd, img_buf_a, image_buffer->buffer_size, addr );
    if ( rc != image_buffer->buffer_size )
      printf( "write error %d\n", rc );
    addr = ( addr + image_buffer->buffer_size ) % MEM_16G;
    tmp_buff = img_buf_a;
    img_buf_a = img_buf_b;
    img_buf_b = tmp_buff;
  }
  printf( "freeing ...\n" );
  free( src_imgs );
  free( img_buf_a );
  free( img_buf_b );
  printf( "to fpga done\n" );
  return (void*)src_imgs;
}

// thread to copy result from FPGA to mem
void copy_from_fpga( void * args ) {
  struct image_info * image_buffer = ( struct image_info * ) args;
  long addr = 0;
  int rc;
  int i, j, idx, j_idx, img_cnt;
  char * src_imgs;
  int no_imgs = image_buffer->buffer_size/image_buffer->image_size;
  posix_memalign((void**)&(src_imgs), 4096, 10*image_buffer->image_size);
  const unsigned long * img_list[10] = { airplane4_mp_3, automobile5_mp_3, bird10_mp_3,
					 cat9_mp_3, deer7_mp_3, dog9_mp_3, frog10_mp_3,
					 horse5_mp_3, ship7_mp_3, truck8_mp_3 };
  clock_t start_time = clock();
  for ( j = 0; j < 10; j++ ) {
    const unsigned long * img = img_list[j % 10];
    for ( i = 0; i < image_buffer->image_size; i++ ) {
      idx = ( image_buffer -> image_size - i - 1 )/8;
      src_imgs[j*image_buffer->image_size + i] = ( img[ idx ] >> (8*( i % 8 )) ) % 256;
    }
  }
  j_idx = 0;
  img_cnt = 0;
  printf( "starting loop ...\n" );
  sem_wait( image_buffer->rd_ahead ); // give a buffer for read
  sem_wait( image_buffer->rd_ahead ); // give a buffer for read
  while( 1 ) {
    sem_wait( image_buffer->rd_ahead );
    rc = pread( image_buffer->fd,
		image_buffer->buffer,
		image_buffer->buffer_size,
		addr );
    sem_post( image_buffer->wrt_ahead );
    if ( rc != image_buffer->buffer_size )
      printf( "read error %d\n", rc );
    addr = ( addr + image_buffer->buffer_size ) % MEM_16G;
    img_cnt += 1;
    for ( j = 0; j < no_imgs; j++ ) {
      if ( memcmp( image_buffer->buffer + j*image_buffer->image_size,
		   ( src_imgs + j_idx*image_buffer->image_size ),
		   image_buffer->image_size ) ) {
	for (i = 0; i < image_buffer->image_size; ++i)
	  printf("%02x", src_imgs[i + j_idx*image_buffer->image_size] & 0xff);
	printf( "\n" );
	for (i = 0; i < image_buffer->image_size; ++i)
	  printf("%02x", image_buffer->buffer[i +j*image_buffer->image_size] & 0xff);
	printf( "\n" );
	printf( "mismatch (%d, %d, %d)\n", img_cnt, j, j_idx );
	return;
      }
      j_idx = ( j_idx + 1 ) % 10;
    }
    if ( img_cnt % 1000 == 0 ) {
      clock_t diff = clock() - start_time;
      double secs = ((double)diff)/CLOCKS_PER_SEC;
      printf( "rate = %f buffers/sec\n", img_cnt/secs );
    }

  }
  printf( "from fpga done\n" );
  return;
}

/*
 * Write 4 identical buffers to the 4 different DRAM channels of the AFI
 */
int dma_example(int slot_id) {
    int image_size = 8192;
    int no_img_in_buffer = 16;
    int sem_cnt_2G = 16;
    int write_fd, read_fd;
    sem_t * wrt_ahead = (sem_t*)malloc( sizeof( sem_t ) );
    sem_t * rd_ahead = (sem_t*)malloc( sizeof( sem_t ) );
    sem_init( wrt_ahead, 0, sem_cnt_2G );
    sem_init( rd_ahead, 0, 0 );
    struct image_info *image_in, *image_out;
    image_in = (struct image_info *)malloc( sizeof(struct image_info) );
    image_out = (struct image_info *)malloc( sizeof(struct image_info) );
    image_in->buffer_size = image_size * no_img_in_buffer;
    image_out->buffer_size = image_size * no_img_in_buffer;
    image_in->wrt_ahead = wrt_ahead;
    image_out->wrt_ahead = wrt_ahead;
    image_in->rd_ahead = rd_ahead;
    image_out->rd_ahead = rd_ahead;
    image_in->image_size = image_size;
    image_out->image_size = image_size;
    posix_memalign((void**)&read_buffer, 4096, (image_in->buffer_size));
    posix_memalign((void**)&write_buffer, 4096, (image_out->buffer_size));
    image_out->buffer = read_buffer;
    image_in->buffer = write_buffer;
    write_fd = -1;
    read_fd = -1;

    if ( read_buffer == NULL || write_buffer == NULL ) {
      printf( "Could not allocate memory\n" );
      return 1;
    }

    open_dma_queue(slot_id, &write_fd, &read_fd);

    image_in->fd = write_fd;
    image_out->fd = read_fd;

    pthread_t * cpy_to_fpga_thd = (pthread_t *)malloc(sizeof(pthread_t));

    pthread_create(cpy_to_fpga_thd, NULL, (void*)copy_to_fpga, image_in );
    // copy_to_fpga( image_in );
    copy_from_fpga( image_out );
    printf( "done ... \n" );
    free(read_buffer);
    free(write_buffer);
    free( image_in );
    free( image_out );
    free( cpy_to_fpga_thd );
    if (write_fd >= 0) {
        close(write_fd);
    }
    if (read_fd >= 0) {
        close(read_fd);
    }
    /* if there is an error code, exit with status 1 */
    return 0;
}
