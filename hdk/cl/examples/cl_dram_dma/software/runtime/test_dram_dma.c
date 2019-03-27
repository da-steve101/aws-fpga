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
#include "dataset.h"
#include "compute_classification.h"

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

#include "cifar_test_img/img_0.h"
#include "cifar_test_img/img_1.h"
#include "cifar_test_img/img_2.h"
#include "cifar_test_img/img_3.h"
#include "cifar_test_img/img_4.h"
#include "cifar_test_img/img_5.h"
#include "cifar_test_img/img_6.h"
#include "cifar_test_img/img_7.h"
#include "cifar_test_img/img_8.h"
#include "cifar_test_img/img_9.h"
#include "cifar_test_img/img_10.h"
#include "cifar_test_img/img_11.h"
#include "cifar_test_img/img_12.h"
#include "cifar_test_img/img_13.h"
#include "cifar_test_img/img_14.h"
#include "cifar_test_img/img_15.h"
#include "cifar_test_img/img_16.h"
#include "cifar_test_img/img_17.h"
#include "cifar_test_img/img_18.h"
#include "cifar_test_img/img_19.h"
#include "cifar_test_img/img_20.h"
#include "cifar_test_img/img_21.h"
#include "cifar_test_img/img_22.h"
#include "cifar_test_img/img_23.h"
#include "cifar_test_img/img_24.h"
#include "cifar_test_img/img_25.h"
#include "cifar_test_img/img_26.h"
#include "cifar_test_img/img_27.h"
#include "cifar_test_img/img_28.h"
#include "cifar_test_img/img_29.h"
#include "cifar_test_img/img_30.h"
#include "cifar_test_img/img_31.h"

#define NO_SAMPLE 10
#define NO_CIFAR_TEST 32
#define USE_SAMPLE 1

/*
const unsigned long * sample_img_inputs[NO_SAMPLE] = { airplane4_image, automobile5_image, bird10_image,
						       cat9_image, deer7_image, dog9_image, frog10_image,
						       horse5_image, ship7_image, truck8_image };

const unsigned long * sample_img_outputs[NO_SAMPLE] = { airplane4_mp_3, automobile5_mp_3, bird10_mp_3,
						 cat9_mp_3, deer7_mp_3, dog9_mp_3, frog10_mp_3,
						 horse5_mp_3, ship7_mp_3, truck8_mp_3 };
*/
const unsigned long * sample_img_inputs[NO_SAMPLE] = { img_0_image, img_1_image, img_2_image, img_3_image, img_4_image, img_5_image, img_6_image, img_7_image, img_8_image, img_9_image };

const unsigned long * sample_img_outputs[NO_SAMPLE] = { img_0_mp_3, img_1_mp_3, img_2_mp_3, img_3_mp_3, img_4_mp_3, img_5_mp_3, img_6_mp_3, img_7_mp_3, img_8_mp_3, img_9_mp_3 };

const unsigned long * cifar_test_inputs[NO_CIFAR_TEST] = { img_0_image, img_1_image, img_2_image, img_3_image, img_4_image, img_5_image, img_6_image, img_7_image, img_8_image, img_9_image, img_10_image, img_11_image, img_12_image, img_13_image, img_14_image, img_15_image, img_16_image, img_17_image, img_18_image, img_19_image, img_20_image, img_21_image, img_22_image, img_23_image, img_24_image, img_25_image, img_26_image, img_27_image, img_28_image, img_29_image, img_30_image, img_31_image };

const unsigned long * cifar_test_outputs[NO_CIFAR_TEST] = { img_0_mp_3, img_1_mp_3, img_2_mp_3, img_3_mp_3, img_4_mp_3, img_5_mp_3, img_6_mp_3, img_7_mp_3, img_8_mp_3, img_9_mp_3, img_10_mp_3, img_11_mp_3, img_12_mp_3, img_13_mp_3, img_14_mp_3, img_15_mp_3, img_16_mp_3, img_17_mp_3, img_18_mp_3, img_19_mp_3, img_20_mp_3, img_21_mp_3, img_22_mp_3, img_23_mp_3, img_24_mp_3, img_25_mp_3, img_26_mp_3, img_27_mp_3, img_28_mp_3, img_29_mp_3, img_30_mp_3, img_31_mp_3 };

#define	MEM_16G		(1ULL << 34)
#define USER_INTERRUPTS_MAX  (16)
// #define CLASSIFY 1 // compute dense layers in C ( runs alot slower )
#define PAGE_SIZE 4096

#ifdef CLASSIFY
#define IMG_CNT_RPT 100
#define CIFAR_TEST 1 // run on the CIFAR testset of 10000 imgs ( only with CLASSIFY )
#else
#define IMG_CNT_RPT 10000
#endif

#ifndef SV_TEST
/* use the stdout logger */
const struct logger *logger = &logger_stdout;
#endif

// convert each pixel ( unsigned long ) into a char array in the right order for the FPGA
char * fill_image_inputs( unsigned long ** img_list, int n, char * output ) {
  int i, j, k, idx, image_size;
  image_size = 8192;
  for ( j = 0; j < n; j++ ) {
    const unsigned long * img = img_list[j % n];
    for ( i = 0; i < image_size/64; i++ ) {
      for ( k = 0; k < 64; k++ ) {
	idx = ( ( image_size - (i+1)*64 + k )/8 ) % 1024;
	output[j*image_size + i*64 + k] = ( img[ idx ] >> (8*( k % 8 ) ) ) % 256;
      }
    }
  }
  return output;
}

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
  struct cifar_dataset * img_dset;
  sem_t * wrt_ahead;
  sem_t * rd_ahead;
  int fd;
  char * buffer;
};

// thread to copy images to FPGA
void * copy_to_fpga( void * args ) {
  struct image_info * image_buffer = ( struct image_info * ) args;
  long addr = 0;
  int j, j_idx, rc;
  char * img_buf_a, *img_buf_b, * tmp_buff;
  int no_imgs = image_buffer->buffer_size/image_buffer->image_size;
  j_idx = 0;
  char * src_imgs;

#ifdef CIFAR_TEST
  posix_memalign((void**)&(src_imgs), PAGE_SIZE, (image_buffer->img_dset->no_imgs)*image_buffer->image_size);
#else
  #ifdef USE_SAMPLE
    posix_memalign((void**)&(src_imgs), PAGE_SIZE, NO_SAMPLE*image_buffer->image_size);
  #else
    posix_memalign((void**)&(src_imgs), PAGE_SIZE, NO_CIFAR_TEST*image_buffer->image_size);
  #endif
#endif

  posix_memalign((void**)&(img_buf_a), PAGE_SIZE, image_buffer->buffer_size);
  posix_memalign((void**)&(img_buf_b), PAGE_SIZE, image_buffer->buffer_size);

#ifdef CIFAR_TEST
  fill_image_inputs( image_buffer->img_dset->imgs, image_buffer->img_dset->no_imgs, src_imgs );
#else

#ifdef USE_SAMPLE
  // sample of an image from each class
  fill_image_inputs( sample_img_inputs, NO_SAMPLE, src_imgs );
#else
  fill_image_inputs( cifar_test_inputs, NO_CIFAR_TEST, src_imgs );
#endif

#endif
  int cnt = 0;
  // while( 1 ) {
  while( cnt < 8 ) {
    for( j = 0; j < no_imgs; j++ ) {
      memcpy( ( char*)( img_buf_a + j*image_buffer->image_size ),
	      src_imgs + j_idx*image_buffer->image_size,
	      image_buffer->image_size );
#ifdef CIFAR_TEST
      j_idx = ( j_idx + 1 ) % image_buffer->img_dset->no_imgs;
#else
  #ifdef USE_SAMPLE
      j_idx = ( j_idx + 1 ) % NO_SAMPLE;
  #else
      j_idx = ( j_idx + 1 ) % NO_CIFAR_TEST;
  #endif
#endif
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
    cnt += 1;
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
  int i, j, img_cnt;
  int no_imgs = image_buffer->buffer_size/image_buffer->image_size;
#ifndef CLASSIFY
  char * src_imgs;
#ifdef USE_SAMPLE
  posix_memalign((void**)&(src_imgs), PAGE_SIZE, NO_SAMPLE*image_buffer->image_size);
  for ( j = 0; j < NO_SAMPLE; j++ ) {
    const unsigned long * img = sample_img_outputs[j % NO_SAMPLE];
#else
  posix_memalign((void**)&(src_imgs), PAGE_SIZE, NO_CIFAR_TEST*image_buffer->image_size);
  for ( j = 0; j < NO_CIFAR_TEST; j++ ) {
    const unsigned long * img = cifar_test_outputs[j % NO_CIFAR_TEST];
#endif
    for ( i = 0; i < image_buffer->image_size; i++ ) {
      int idx = ( image_buffer -> image_size - i - 1 )/8;
      src_imgs[j*image_buffer->image_size + i] = ( img[ idx ] >> (8*( i % 8 )) ) % 256;
    }
  }
#endif
  clock_t start_time = clock();
  img_cnt = 0;
  int j_idx = 0;
#ifdef CIFAR_TEST
  int good_cnt, err_cnt;
  good_cnt = 0;
  err_cnt = 0;
#endif
  printf( "starting loop ...\n" );
  // while( 1 ) {
  while( img_cnt < 2 ) {
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
#ifdef CLASSIFY
      short output_ary[10];
      const short * input_img = (short*)(image_buffer->buffer + j*image_buffer->image_size);
      compute_mat( input_img, (short*)output_ary );
      short max = output_ary[0];
      int max_idx = 0;
      for ( i = 1; i < 10; i++ ) {
	if ( output_ary[i] > max ) {
	  max = output_ary[i];
	  max_idx = i;
	}
      }
#ifdef CIFAR_TEST
      printf( "expected class %i, got class %i\n", image_buffer->img_dset->labels[j_idx], max_idx );
      printf( "output_ary[%i] = ", image_buffer->img_dset->labels[j_idx] );
      for ( i = 0; i < 10; i++ )
	printf( "%04x,", output_ary[i] & 0xffff );
      printf( "\n" );
      if ( max_idx != image_buffer->img_dset->labels[j_idx] ) {
	err_cnt += 1;
      } else
	good_cnt += 1;
#else
      printf( "expected class %i, got class %i\n", j_idx, max_idx );
      if ( max_idx != j_idx )
	printf( "mismatch expected class %i, got class %i\n", j_idx, max_idx );
#endif
#else
      if ( memcmp( image_buffer->buffer + j*image_buffer->image_size,
		   ( src_imgs + j_idx*image_buffer->image_size ),
		   image_buffer->image_size ) ) {
	for (i = 0; i < image_buffer->image_size; ++i)
	  printf("%02x", src_imgs[i + j_idx*image_buffer->image_size] & 0xff);
	printf( "\n" );
	for (i = 0; i < image_buffer->image_size; ++i)
	  printf("%02x", image_buffer->buffer[i + j*image_buffer->image_size] & 0xff);
	printf( "\n" );
	printf( "mismatch (%d, %d, %d)\n", img_cnt, j, j_idx );
	return;
      }
#endif
#ifdef USE_SAMPLE
      j_idx = ( j_idx + 1 ) % NO_SAMPLE;
#else
      j_idx = ( j_idx + 1 ) % NO_CIFAR_TEST;
#endif
    }
    if ( img_cnt % IMG_CNT_RPT == 0 ) {
      clock_t diff = clock() - start_time;
      double secs = ((double)diff)/CLOCKS_PER_SEC;
      printf( "rate = %f imgs/sec\n", no_imgs*img_cnt/secs );
#ifdef CIFAR_TEST
      printf( "good_cnt = %i, err_cnt = %i\n", good_cnt, err_cnt );
#endif
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
    int sem_cnt_2G = 64;
    int write_fd, read_fd;
    sem_t * wrt_ahead = (sem_t*)malloc( sizeof( sem_t ) );
    sem_t * rd_ahead = (sem_t*)malloc( sizeof( sem_t ) );
    sem_init( wrt_ahead, 0, sem_cnt_2G );
    sem_init( rd_ahead, 0, 0 );
    struct image_info *image_in, *image_out;
    image_in = (struct image_info *)malloc( sizeof(struct image_info) );
    image_out = (struct image_info *)malloc( sizeof(struct image_info) );
#ifdef CIFAR_TEST
    struct cifar_dataset * img_dset = cifar_testset();
    image_in->img_dset = img_dset;
    image_out->img_dset = img_dset;
#endif
    image_in->buffer_size = image_size * no_img_in_buffer;
    image_out->buffer_size = image_size * no_img_in_buffer;
    image_in->wrt_ahead = wrt_ahead;
    image_out->wrt_ahead = wrt_ahead;
    image_in->rd_ahead = rd_ahead;
    image_out->rd_ahead = rd_ahead;
    image_in->image_size = image_size;
    image_out->image_size = image_size;
    posix_memalign((void**)&read_buffer, PAGE_SIZE, (image_in->buffer_size));
    posix_memalign((void**)&write_buffer, PAGE_SIZE, (image_out->buffer_size));
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

    // pthread_create(cpy_to_fpga_thd, NULL, (void*)copy_to_fpga, image_in );
    copy_to_fpga( image_in );
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
