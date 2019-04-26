/* SPDX-License-Identifier: BSD-3-Clause
 * Copyright(c) 2010-2017 Intel Corporation
 */

#include <stdint.h>
#include <inttypes.h>
#include <unistd.h>
#include <signal.h>
#include <getopt.h>

#include <rte_eal.h>
#include <rte_ethdev.h>
#include <rte_cycles.h>
#include <rte_malloc.h>
#include <rte_debug.h>
#include <rte_prefetch.h>
#include <rte_distributor.h>
#include <rte_pause.h>
#include "airplane.h"

#define RX_RING_SIZE 64
#define TX_RING_SIZE 64
#define NUM_MBUFS ((8*1024)-1)
#define MBUF_CACHE_SIZE 0
#define BURST_SIZE 1
#define SCHED_RX_RING_SZ 8192
#define BURST_SIZE_TX 1

#define RTE_LOGTYPE_DISTRAPP RTE_LOGTYPE_USER1

#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_RESET   "\x1b[0m"
#define IMG_SIZE 8192
#define PACKET_SIZE RTE_PKTMBUF_HEADROOM + IMG_SIZE

/* mask of enabled ports */
static uint32_t enabled_port_mask;
static uint32_t latency_mode = 0;
volatile uint8_t quit_signal_tx;
volatile uint8_t quit_signal_rx;
volatile uint64_t prev_t;
volatile uint64_t freq;

static volatile struct app_stats {
  struct {
    uint64_t in_pkts;
    uint64_t ret_pkts;
    uint64_t sent_pkts;
    uint64_t enqdrop_pkts;
  } rx __rte_cache_aligned;
  int pad2 __rte_cache_aligned;

  struct {
    uint64_t dequeue_pkts;
    uint64_t tx_pkts;
    uint64_t enqdrop_pkts;
    uint64_t pkt_sent;
  } tx __rte_cache_aligned;
  int pad3 __rte_cache_aligned;

  struct {
    double sum;
    uint64_t count;
  } latency __rte_cache_aligned;

  uint64_t port_tx_pkts[64] __rte_cache_aligned;
} app_stats;

struct app_stats prev_app_stats;

static const struct rte_eth_conf port_conf_default = {
  .rxmode = {
    .mq_mode = ETH_MQ_RX_RSS,
    .max_rx_pkt_len = ETHER_MAX_LEN,
    .ignore_offload_bitfield = 1,
  },
  .txmode = {
    .mq_mode = ETH_MQ_TX_NONE,
  },
};

struct output_buffer {
  unsigned count;
  struct rte_mbuf *mbufs[BURST_SIZE];
};

static void print_stats(void);

static inline int
port_init(uint16_t port, struct rte_mempool *mbuf_pool)
{
  struct rte_eth_conf port_conf = port_conf_default;
  const uint16_t rxRings = 1, txRings = 1;
  int retval;
  uint16_t nb_rxd = RX_RING_SIZE;
  uint16_t nb_txd = TX_RING_SIZE;
  struct rte_eth_dev_info dev_info;
  struct rte_eth_txconf txconf;

  if (!rte_eth_dev_is_valid_port(port))
    return -1;

  rte_eth_dev_info_get(port, &dev_info);
  if (dev_info.tx_offload_capa & DEV_TX_OFFLOAD_MBUF_FAST_FREE)
    port_conf.txmode.offloads |=
      DEV_TX_OFFLOAD_MBUF_FAST_FREE;

  retval = rte_eth_dev_configure(port, rxRings, txRings, &port_conf);
  if (retval != 0)
    return retval;

  retval = rte_eth_dev_adjust_nb_rx_tx_desc(port, &nb_rxd, &nb_txd);
  if (retval != 0)
    return retval;

  retval = rte_eth_rx_queue_setup(port, 0, nb_rxd,
				  rte_eth_dev_socket_id(port),
				  NULL, mbuf_pool);
  if (retval < 0)
    return retval;

  txconf = dev_info.default_txconf;
  txconf.txq_flags = ETH_TXQ_FLAGS_IGNORE;
  txconf.offloads = port_conf.txmode.offloads;

  retval = rte_eth_tx_queue_setup(port, 0, nb_txd,
				  rte_eth_dev_socket_id(port),
				  &txconf);
  if (retval < 0)
    return retval;

  retval = rte_eth_dev_start(port);
  if (retval < 0)
    return retval;

  struct rte_eth_link link;
  rte_eth_link_get_nowait(port, &link);
  while (!link.link_status) {
    printf("Waiting for Link up on port %"PRIu16"\n", port);
    sleep(1);
    rte_eth_link_get_nowait(port, &link);
  }

  if (!link.link_status) {
    printf("Link down on port %"PRIu16"\n", port);
    return 0;
  }

  struct ether_addr addr;
  rte_eth_macaddr_get(port, &addr);
  printf("Port %u MAC: %02"PRIx8" %02"PRIx8" %02"PRIx8
	 " %02"PRIx8" %02"PRIx8" %02"PRIx8"\n",
	 port,
	 addr.addr_bytes[0], addr.addr_bytes[1],
	 addr.addr_bytes[2], addr.addr_bytes[3],
	 addr.addr_bytes[4], addr.addr_bytes[5]);

  rte_eth_promiscuous_enable(port);

  return 0;
}

static inline void
flush_one_port(struct output_buffer *outbuf, uint8_t outp)
{
  unsigned int nb_tx = rte_eth_tx_burst(outp, 0,
					outbuf->mbufs, outbuf->count);
  app_stats.tx.tx_pkts += outbuf->count;
  if ( unlikely(latency_mode) )
    app_stats.tx.pkt_sent = rte_rdtsc();
  if (unlikely(nb_tx < outbuf->count)) {
    app_stats.tx.enqdrop_pkts +=  outbuf->count - nb_tx;
    do {
      rte_pktmbuf_free(outbuf->mbufs[nb_tx]);
    } while (++nb_tx < outbuf->count);
  }
  outbuf->count = 0;
}

static int
lcore_rx(void)
{
  struct rte_mbuf *bufs[BURST_SIZE * 8];
  uint16_t i;
  uint16_t f_idx = 0;

  app_stats.latency.sum = 0;
  app_stats.latency.count = 0;
  printf("\nCore %u acting as rx core.\n", rte_lcore_id());
  while (!quit_signal_rx) {
    const uint16_t nb_rx = rte_eth_rx_burst(0, 0, bufs, BURST_SIZE);
    if (nb_rx) {
      if ( unlikely(latency_mode) ) {
	uint64_t rx_time = rte_rdtsc();
	double diff = ( double ) ( rx_time - app_stats.tx.pkt_sent );
	app_stats.latency.sum += diff / freq;
	app_stats.latency.count += 1;
      }
      app_stats.rx.in_pkts += nb_rx;
      const uint16_t nb_ret = nb_rx;
      for ( i = 0; i < nb_ret; i++ ) {
	if ( unlikely(latency_mode) ) {
	  char fname[20];
	  // should return 16'h000c, 16'hffc7, 16'hfeab, 16'hfe39, 16'hfec7, 16'hfe4b, 16'hfe0b, 16'hfe85, 16'hff62, 16'h03d2
	  // for airplane4 image
	  sprintf( fname, "pckt_ret_%i.dmp", f_idx );
	  FILE * f = fopen( fname, "w" );
	  rte_pktmbuf_dump( f, bufs[i], IMG_SIZE );
	  fclose( f );
	  f_idx = ( f_idx + 1 ) % 32;
	}
	rte_pktmbuf_free( bufs[i] );
      }
      // check that the label of the image matches the class
      app_stats.rx.ret_pkts += nb_ret;
    }
  }
  printf("\nCore %u exiting rx task.\n", rte_lcore_id());
  return 0;
}


static int
lcore_tx(void)
{
  static struct output_buffer tx_buffer;
  tx_buffer.count = 0;
  const int socket_id = rte_socket_id();
  uint16_t port;
  uint16_t num_imgs = 32;
  uint16_t i, j;
  prev_t = rte_rdtsc() - 10000;

  RTE_ETH_FOREACH_DEV(port) {
    /* skip ports that are not enabled */
    if ((enabled_port_mask & (1 << port)) == 0)
      continue;

    if (rte_eth_dev_socket_id(port) > 0 &&
	rte_eth_dev_socket_id(port) != socket_id)
      printf("WARNING, port %u is on remote NUMA node to "
	     "TX thread.\n\tPerformance will not "
	     "be optimal.\n", port);
  }

  printf( "\nEnabled port mask is %x\n", enabled_port_mask );

  // make a mem_pool of membufs
  struct rte_mempool* mbuf_pool = rte_pktmbuf_pool_create("TX_MBUF_POOL",
				      1024*num_imgs - 1, MBUF_CACHE_SIZE, 0,
                                      PACKET_SIZE, rte_socket_id());
  if (mbuf_pool == NULL)
    rte_exit(EXIT_FAILURE, "Cannot create mbuf pool in tx\n");
  // rte_pktmbuf_alloc, allocate the mbuf
  struct rte_mbuf * bufs[num_imgs];
  for ( i = 0; i < num_imgs; i++ )
    bufs[i] = NULL;
  int ret = rte_pktmbuf_alloc_bulk( mbuf_pool, bufs, num_imgs );
  if ( unlikely(ret) )
    rte_exit(EXIT_FAILURE, "Cannot allocate packets\n" );
  void * opaque_arg = NULL;
  struct output_buffer *outbuf = &tx_buffer;
  uint16_t nb_rx = 1; // num_imgs;

  // set type: RTE_PTYPE_UNKNOWN?
  for ( i = 0; i < num_imgs; i++ ) {
    rte_pktmbuf_init( mbuf_pool, opaque_arg, bufs[i], i );
    char * img = rte_pktmbuf_append( bufs[i], IMG_SIZE );
    if ( !img )
      rte_exit(EXIT_FAILURE, "Cannot append buffer\n" );
    for ( j = 0; j < IMG_SIZE; j++ ) {
      int shift = j % 8;
      int pxl_idx = 1023 - ( j/8 );
      img[j] = (char) ( ( airplane4_image[pxl_idx] >> ( 8*shift ) ) & 255 );
    }
    char fname[20];
    sprintf( fname, "pckt_%i.dmp", i );
    FILE * f = fopen( fname, "w" );
    rte_pktmbuf_dump( f, bufs[i], IMG_SIZE );
    fclose( f );
  }
  printf( "\nGenerated images\n" );
  // TODO: put all test images in memory in the mempool

  printf("\nCore %u doing packet TX.\n", rte_lcore_id());
  uint64_t t;
  uint64_t t_w;
  t = rte_rdtsc() + freq;
  while (!quit_signal_tx) {
    if (t < rte_rdtsc()) {
      print_stats();
      t = rte_rdtsc() + freq;
    }

    rte_prefetch_non_temporal((void *)bufs[0]);
    rte_prefetch_non_temporal((void *)bufs[1]);
    rte_prefetch_non_temporal((void *)bufs[2]);
    for (i = 0; i < nb_rx; i++) {
      rte_prefetch_non_temporal((void *)bufs[( i + 3 ) % nb_rx]);
      outbuf->mbufs[outbuf->count++] = bufs[i];
      if (outbuf->count == BURST_SIZE_TX) {
	flush_one_port(outbuf, 0);
	// slow down the transmission a bit
	if ( unlikely( latency_mode ) ) // use speed so packet is finished before the next one is sent
	  t_w = rte_rdtsc()+50000000; 
	else // use max speed so no dropped packets
	  t_w = rte_rdtsc()+18650;
	while (rte_rdtsc() < t_w)
	  rte_pause();
      }
    }
  }
  printf("\nCore %u exiting tx task.\n", rte_lcore_id());
  return 0;
}

static void
int_handler(int sig_num)
{
  printf("Exiting on signal %d\n", sig_num);
  quit_signal_tx = 1;
  quit_signal_rx = 1;
}

static void
print_stats(void)
{
  struct rte_eth_stats eth_stats;
  unsigned int i;
  double t_secs = ( rte_rdtsc() - prev_t ) / (double)freq;
  prev_t = rte_rdtsc();

  RTE_ETH_FOREACH_DEV(i) {
    rte_eth_stats_get(i, &eth_stats);
    app_stats.port_tx_pkts[i] = eth_stats.opackets;
  }

  printf("Rx thread:\n");
  printf(" - In:          %5.2f\n",
	 (app_stats.rx.in_pkts -
	  prev_app_stats.rx.in_pkts)/t_secs);
  printf(" - Returned:    %5.2f\n",
	 (app_stats.rx.ret_pkts -
	  prev_app_stats.rx.ret_pkts)/t_secs);
  printf(" - Sent:        %5.2f\n",
	 (app_stats.rx.sent_pkts -
	  prev_app_stats.rx.sent_pkts)/t_secs);
  printf(" - Dropped      %s%5.2f%s\n", ANSI_COLOR_RED,
	 (app_stats.rx.enqdrop_pkts -
	  prev_app_stats.rx.enqdrop_pkts)/t_secs,
	 ANSI_COLOR_RESET);

  printf("TX thread:\n");
  printf(" - Dequeued:    %5.2f\n",
	 (app_stats.tx.dequeue_pkts -
	  prev_app_stats.tx.dequeue_pkts)/t_secs);
  RTE_ETH_FOREACH_DEV(i) {
    printf("Port %u Pktsout: %5.2f\n",
	   i, (app_stats.port_tx_pkts[i] -
	       prev_app_stats.port_tx_pkts[i])/t_secs);
    prev_app_stats.port_tx_pkts[i] = app_stats.port_tx_pkts[i];
  }
  printf(" - Transmitted: %5.2f\n",
	 (app_stats.tx.tx_pkts -
	  prev_app_stats.tx.tx_pkts)/t_secs);
  printf(" - Dropped:     %s%5.2f%s\n", ANSI_COLOR_RED,
	 (app_stats.tx.enqdrop_pkts -
	  prev_app_stats.tx.enqdrop_pkts)/t_secs,
	 ANSI_COLOR_RESET);

  if ( latency_mode )
    printf( "Average latency = %lf\n", app_stats.latency.sum/app_stats.latency.count );

  prev_app_stats.rx.in_pkts = app_stats.rx.in_pkts;
  prev_app_stats.rx.ret_pkts = app_stats.rx.ret_pkts;
  prev_app_stats.rx.sent_pkts = app_stats.rx.sent_pkts;
  prev_app_stats.rx.enqdrop_pkts = app_stats.rx.enqdrop_pkts;
  prev_app_stats.tx.dequeue_pkts = app_stats.tx.dequeue_pkts;
  prev_app_stats.tx.tx_pkts = app_stats.tx.tx_pkts;
  prev_app_stats.tx.enqdrop_pkts = app_stats.tx.enqdrop_pkts;
}

/* display usage */
static void
print_usage(const char *prgname)
{
  printf("%s [EAL options] -- -p PORTMASK -m MODE\n"
	 "  -p PORTMASK: hexadecimal bitmask of ports to configure\n"
	 "  -m : mode use 'l' for latency mode\n",
	 prgname);
}

static int
parse_portmask(const char *portmask)
{
  char *end = NULL;
  unsigned long pm;

  /* parse hexadecimal string */
  pm = strtoul(portmask, &end, 16);
  if ((portmask[0] == '\0') || (end == NULL) || (*end != '\0'))
    return -1;
  if (pm == 0)
    return -1;
  return pm;
}

/* Parse the argument given in the command line of the application */
static int
parse_args(int argc, char **argv)
{
  int opt;
  char **argvopt;
  int option_index;
  char *prgname = argv[0];
  static struct option lgopts[] = {
    {NULL, 0, 0, 0}
  };

  argvopt = argv;

  while ((opt = getopt_long(argc, argvopt, "p:m:s:",
			    lgopts, &option_index)) != EOF) {

    switch (opt) {
      /* portmask */
    case 'p':
      enabled_port_mask = parse_portmask(optarg);
      if (enabled_port_mask == 0) {
	printf("invalid portmask\n");
	print_usage(prgname);
	return -1;
      }
      break;

    case 'm':
      if ( optarg[0] == 'l' )
	latency_mode = 1;
      break;
      
    default:
      print_usage(prgname);
      return -1;
    }
  }

  if (optind <= 1) {
    print_usage(prgname);
    return -1;
  }

  argv[optind-1] = prgname;

  optind = 1;
  return 0;
}

/* Main function, does initialization and calls the per-lcore functions */
int
main(int argc, char *argv[])
{
  struct rte_mempool *mbuf_pool;
  unsigned lcore_id, worker_id = 1;
  unsigned nb_ports;
  uint16_t portid;
  uint16_t nb_ports_available;

  /* catch ctrl-c so we can print on exit */
  signal(SIGINT, int_handler);

  /* init EAL */
  int ret = rte_eal_init(argc, argv);
  if (ret < 0)
    rte_exit(EXIT_FAILURE, "Error with EAL initialization\n");
  argc -= ret;
  argv += ret;
  freq = rte_get_timer_hz();

  /* parse application arguments (after the EAL ones) */
  ret = parse_args(argc, argv);
  if (ret < 0)
    rte_exit(EXIT_FAILURE, "Invalid parameters\n");

  if (rte_lcore_count() != 3 )
    rte_exit(EXIT_FAILURE, "Error, This application needs "
	     "3 logical cores to run:\n"
	     "1 lcore for packet RX\n"
	     "1 lcore for packet TX and for stats\n"
	     "1 lcore for management\n");

  nb_ports = rte_eth_dev_count_avail();
  if (nb_ports == 0)
    rte_exit(EXIT_FAILURE, "Error: no ethernet ports detected\n");
  if (nb_ports != 1 && (nb_ports & 1))
    rte_exit(EXIT_FAILURE, "Error: number of ports must be even, except "
	     "when using a single port\n");

  mbuf_pool = rte_pktmbuf_pool_create("MBUF_POOL",
				      NUM_MBUFS * nb_ports, MBUF_CACHE_SIZE, 0,
				      PACKET_SIZE, rte_socket_id());
  if (mbuf_pool == NULL)
    rte_exit(EXIT_FAILURE, "Cannot create mbuf pool\n");
  nb_ports_available = nb_ports;

  /* initialize all ports */
  RTE_ETH_FOREACH_DEV(portid) {
    /* skip ports that are not enabled */
    if ((enabled_port_mask & (1 << portid)) == 0) {
      printf("\nSkipping disabled port %d\n", portid);
      nb_ports_available--;
      continue;
    }
    /* init port */
    printf("Initializing port %u... done\n", portid);

    if (port_init(portid, mbuf_pool) != 0)
      rte_exit(EXIT_FAILURE, "Cannot initialize port %u\n",
	       portid);
  }
  if (!nb_ports_available) {
    rte_exit(EXIT_FAILURE,
	     "All available ports are disabled. Please set portmask.\n");
  }
  RTE_LCORE_FOREACH_SLAVE(lcore_id) {
    if (worker_id == 1) {
      printf("Starting rx on lcore_id %d\n",
	     lcore_id);
      rte_eal_remote_launch(
			    (lcore_function_t *)lcore_rx,
			    NULL, lcore_id);
    } else if (worker_id == 2) {
      printf("Starting tx  on worker_id %d, lcore_id %d\n",
	     worker_id, lcore_id);
      rte_eal_remote_launch((lcore_function_t *)lcore_tx, NULL, lcore_id);
    }
    worker_id++;
  }
  RTE_LCORE_FOREACH_SLAVE(lcore_id) {
    if (rte_eal_wait_lcore(lcore_id) < 0)
      return -1;
  }
  return 0;
}
