
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

#ifndef SV_TEST
static uint16_t pci_vendor_id = 0x1D0F; /* Amazon PCI Vendor ID */
static uint16_t pci_device_id = 0xF000;
#endif

int verify_image( int slot_id );

#ifdef SV_TEST
void test_main(uint32_t *exit_code) {
#else
int main(int argc, char **argv) {
#endif
  int slot_id = 0;
  int rc = 0;

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

#ifndef SV_TEST
static int
check_slot_config(int slot_id)
{
    int rc;
    struct fpga_mgmt_image_info info = {0};

    /* get local image description, contains status, vendor id, and device id */
    rc = fpga_mgmt_describe_local_image(slot_id, &info, 0);
    fail_on(rc, out, "Unable to get local image information. Are you running as root?");

    /* check to see if the slot is ready */
    if (info.status != FPGA_STATUS_LOADED) {
        rc = 1;
        fail_on(rc, out, "Slot %d is not ready", slot_id);
    }
    /* confirm that the AFI that we expect is in fact loaded */
    if (info.spec.map[FPGA_APP_PF].vendor_id != pci_vendor_id ||
        info.spec.map[FPGA_APP_PF].device_id != pci_device_id) {
        rc = 1;
        printf("The slot appears loaded, but the pci vendor or device ID doesn't "
               "match the expected values. You may need to rescan the fpga with \n"
               "fpga-describe-local-image -S %i -R\n"
               "Note that rescanning can change which device file in /dev/ a FPGA will map to.\n"
               "To remove and re-add your edma driver and reset the device file mappings, run\n"
               "`sudo rmmod edma-drv && sudo insmod <aws-fpga>/sdk/linux_kernel_drivers/edma/edma-drv.ko`\n",
               slot_id);
        fail_on(rc, out, "The PCI vendor id and device of the loaded image are "
                         "not the expected values.");
    }

out:
    return rc;
}
#endif
 
int verify_image( int slot_id ) {
  int fd, rc;
  char device_file_name[256];
  char *write_buffer, *read_buffer;
  static const size_t image_size = 8192;

  int write_channel = 0;
  int read_channel = 1;

  read_buffer = NULL;
  write_buffer = NULL;
  fd = -1;

  write_buffer = (char *)malloc(image_size);
  read_buffer = (char *)malloc(image_size);
  if (write_buffer == NULL || read_buffer == NULL) {
    rc = ENOMEM;
    goto out;
  }

#ifndef SV_TEST
  fd = open_dma_queue(slot_id);
#else
  init_ddr();
#endif

  rand_string(write_buffer, buffer_size);
  
  fpga_write_buffer_to_cl(slot_id, write_channel, fd, buffer_size, (0x10000000 + write_channel*MEM_16G));

  /* fsync() will make sure the write made it to the target buffer 
   * before read is done
   */
#ifndef SV_TEST
  rc = fsync(fd);
  fail_on((rc = (rc < 0)? errno:0), out, "call to fsync failed.");
#endif

  fpga_read_cl_to_buffer(slot_id, read_channel, fd, buffer_size, (0x10000000 + read_channel*MEM_16G));

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
