
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>

#ifdef SV_TEST
   #include "fpga_pci_sv.h"
#else
   #include <fpga_pci.h>
   #include <fpga_mgmt.h>
#endif
#include <utils/lcd.h>
#include <utils/sh_dpi_tasks.h>
#include "common_dma.h"

#define	MEM_16G		(1ULL << 34)

int verify_image( int slot_id );

#ifdef SV_TEST
void test_main(uint32_t *exit_code) {
#else
int main(int argc, char **argv) {
#endif
  int slot_id = 0;
  int rc = 0;

  printf("start init \n");
  cosim_printf("start init \n");
#ifndef SV_TEST
  rc = fpga_mgmt_init();
  fail_on(rc, out, "Unable to initialize the fpga_mgmt library");

  rc = fpga_pci_init();
  fail_on(rc, out, "Unable to initialize the fpga_pci library");
#endif

  rc = verify_image(slot_id);
  
#ifndef SV_TEST
  return rc;
 out:
  return 1;
#else
 out:
   *exit_code = 0;
#endif
}
 
int verify_image( int slot_id ) {
  int fd, rc;
  int i, j;
  static const size_t image_size = 64;

  int write_channel = 0;
  int read_channel = 1;

  read_buffer = NULL;
  write_buffer = NULL;
  fd = -1;

  char * image = ( char * ) malloc( image_size );
  write_buffer = (char *)malloc(buffer_size);
  read_buffer = (char *)malloc(buffer_size);
  if (write_buffer == NULL || read_buffer == NULL) {
    rc = ENOMEM;
    goto out;
  }

  cosim_printf("opening queue ... \n");
#ifndef SV_TEST
  fd = open_dma_queue(slot_id);
#endif

  cosim_printf("starting the write in %d blocks... ", image_size/buffer_size);
  for ( i = 0; i < image_size; i++ )
    image[i] = ( i - 64 + 256 ) % 256;
  fpga_read_cl_to_buffer(slot_id, read_channel, fd, buffer_size, (0x10000000 + read_channel*MEM_16G)  + i*buffer_size );
  for ( j = 0; j < buffer_size; j++ )
    cosim_printf( "%x --- %x\n", image[j], read_buffer[j] );
  // rand_string( image, image_size );
  for ( i = 0; i < image_size/buffer_size; i++ ) {
    memcpy( write_buffer, image + i*buffer_size, buffer_size );
    fpga_write_buffer_to_cl(slot_id, write_channel, fd, buffer_size, (0x10000000 + write_channel*MEM_16G) + i*buffer_size );
  }

  /* fsync() will make sure the write made it to the target buffer 
   * before read is done
   */
#ifndef SV_TEST
  rc = fsync(fd);
  fail_on((rc = (rc < 0)? errno:0), out, "call to fsync failed.");
#endif

  cosim_printf("starting the read ... ");
  for ( i = 0; i < image_size/buffer_size; i++ ) {
    fpga_read_cl_to_buffer(slot_id, read_channel, fd, buffer_size, (0x10000000 + read_channel*MEM_16G)  + i*buffer_size );
    if ( memcmp( image + i*buffer_size, read_buffer, buffer_size) != 0 ) {
      cosim_printf( "image differs on iter %i", i );
      for ( j = 0; j < buffer_size; j++ )
	cosim_printf( "%x --- %x\n", image[i*buffer_size + j], read_buffer[j] );
    } else
      cosim_printf( "image is same on iter %i", i );
  }

 out:
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
  return (rc != 0 ? 1 : 0);
}
