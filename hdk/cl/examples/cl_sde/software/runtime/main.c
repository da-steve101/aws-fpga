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
#define BURST_SIZE_TX 1

#define RTE_LOGTYPE_DISTRAPP RTE_LOGTYPE_USER1

#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_RESET   "\x1b[0m"
#define IMG_SIZE 8192
#define LATENCY_BUFR 1024
#define NUM_IMGS 10000
#define CLASSIFICATION_SIZE 64
#define IMG_PACKET_SIZE RTE_PKTMBUF_HEADROOM + IMG_SIZE
#define CLASSIFICATION_PACKET_SIZE RTE_PKTMBUF_HEADROOM + CLASSIFICATION_SIZE


static uint32_t enabled_port_mask = 1;
static uint32_t debug_mode = 0;
static uint32_t num_loops = 0;
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
    uint64_t pkt_sent[LATENCY_BUFR];
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
  unsigned int nb_tx = rte_eth_tx_burst(outp, 0, outbuf->mbufs, outbuf->count);
  app_stats.tx.tx_pkts += outbuf->count;
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
  uint16_t max_idx;
  int16_t max_val, *tmp_val, j;
  const char * cifar_classes[11] = {"airplane", "automobile", "bird", "cat", "deer", "dog", "frog", "horse", "ship", "truck", "ERROR" };

  FILE * f_pred = NULL;
  f_pred = fopen( "preds", "w" );
  int max_to_write = NUM_IMGS;
  app_stats.latency.sum = 0;
  app_stats.latency.count = 0;
  printf("\nCore %u acting as rx core.\n", rte_lcore_id());
  uint16_t pkt_idx = 0;
  while (!quit_signal_rx) {
    const uint16_t nb_rx = rte_eth_rx_burst(0, 0, bufs, BURST_SIZE);
    if (nb_rx) {
      uint64_t rx_time = rte_rdtsc();
      double diff = ( double ) ( rx_time - app_stats.tx.pkt_sent[pkt_idx] );
      pkt_idx = ( pkt_idx + 1 ) % LATENCY_BUFR;
      app_stats.latency.sum += diff / freq;
      app_stats.latency.count += 1;
      app_stats.rx.in_pkts += nb_rx;
      for ( i = 0; i < nb_rx; i++ ) {
	max_idx = 10;
	max_val = -32768;
	char * data_out = rte_pktmbuf_mtod( bufs[i], char * );
	for ( j = 0; j < 10; j++ ) {
	  tmp_val = ( int16_t * ) ( data_out + 2*j );
	  if ( *tmp_val > max_val ) {
	    max_idx = j;
	    max_val = *tmp_val;
	  }
	}
	if ( unlikely(debug_mode) ) {
	  char fname[20];
	  sprintf( fname, "pckt_ret_%i.dmp", f_idx );
	  FILE * f = fopen( fname, "w" );
	  fprintf( f, "image is %s with %i\n", cifar_classes[max_idx], max_val );
	  rte_pktmbuf_dump( f, bufs[i], IMG_SIZE );
	  fclose( f );
	  // so we dont run out of disk space super quickly
	  f_idx = ( f_idx + 1 ) % 2048;
	} else {
	  char bfr[3];
	  // only do the first 10000 in the test set
	  if ( max_to_write > 0 ) {
	    sprintf( bfr, "%i", max_idx ); // max_idx is between 0 and 9
	    fwrite( bfr, 1, 1, f_pred );
	    max_to_write--;
	  }
	}
	rte_pktmbuf_free( bufs[i] );
      }
      app_stats.rx.ret_pkts += nb_rx;
    }
  }
  fclose( f_pred );
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
  uint16_t num_imgs = NUM_IMGS;
  uint16_t i;
  prev_t = rte_rdtsc() - 10000;

  RTE_ETH_FOREACH_DEV(port) {
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
				      ( 1 << 14 ) - 1, MBUF_CACHE_SIZE, 0,
                                      IMG_PACKET_SIZE, rte_socket_id());
  if (mbuf_pool == NULL)
    rte_exit(EXIT_FAILURE, "Cannot create mbuf pool in tx\n");
  struct rte_mbuf * bufs[num_imgs];
  for ( i = 0; i < num_imgs; i++ )
    bufs[i] = NULL;
  int ret = rte_pktmbuf_alloc_bulk( mbuf_pool, bufs, num_imgs );
  if ( unlikely(ret) )
    rte_exit(EXIT_FAILURE, "Cannot allocate packets\n" );
  struct output_buffer *outbuf = &tx_buffer;
  uint16_t nb_rx = num_imgs;
  printf( "Loading test set images...\n" );
  FILE * f_test = fopen( "test_batches.hex", "r" );
  if ( !f_test )
    rte_exit(EXIT_FAILURE, "Cannot open test_batches.hex\n" );
  for ( i = 0; i < num_imgs; i++ ) {
    char * img = rte_pktmbuf_append( bufs[i], IMG_SIZE );
    if ( !img )
      rte_exit(EXIT_FAILURE, "Cannot append buffer\n" );
    fread( img, 1, IMG_SIZE, f_test );
  }
  fclose( f_test );
  printf( "Loaded test set images\n" );

  printf("\nCore %u doing packet TX.\n", rte_lcore_id());
  uint64_t t;
  uint64_t t_w = 0, t_w_old;
  t = rte_rdtsc() + freq;
  uint32_t k = 0;
  uint64_t lat_idx = 0;
  while ( k < num_loops || num_loops == 0 ) {
    if (t < rte_rdtsc()) {
      print_stats();
      t = rte_rdtsc() + freq;
    }
    rte_prefetch_non_temporal((void *)bufs[0]);
    rte_prefetch_non_temporal((void *)bufs[1]);
    rte_prefetch_non_temporal((void *)bufs[2]);
    if ( unlikely( num_loops > 0 && num_loops - k < num_imgs ) )
      nb_rx = num_loops - k;
    for (i = 0; i < nb_rx; i++) {
      rte_prefetch_non_temporal((void *)bufs[( i + 3 ) % nb_rx]);
      outbuf->mbufs[outbuf->count++] = bufs[i];
      if (outbuf->count == BURST_SIZE_TX) {
	t_w_old = t_w;
	t_w = rte_rdtsc();
	flush_one_port(outbuf, 0);
	app_stats.tx.pkt_sent[lat_idx] = t_w;
	lat_idx = (lat_idx + 1 ) % LATENCY_BUFR;
	// slow down the transmission a bit
	if ( unlikely( debug_mode ) )
	  t_w_old += 50000000;
	else // use max speed with no dropped packets
	  t_w_old += 37390;
	while (rte_rdtsc() < t_w_old)
	  rte_pause();
      }
    }
    k += nb_rx;
    if ( quit_signal_tx )
      break;
  }
  usleep(1000);
  quit_signal_rx = 1;
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

  printf( "Average latency = %lf\n", app_stats.latency.sum/app_stats.latency.count );

  prev_app_stats.rx.in_pkts = app_stats.rx.in_pkts;
  prev_app_stats.rx.ret_pkts = app_stats.rx.ret_pkts;
  prev_app_stats.rx.sent_pkts = app_stats.rx.sent_pkts;
  prev_app_stats.rx.enqdrop_pkts = app_stats.rx.enqdrop_pkts;
  prev_app_stats.tx.dequeue_pkts = app_stats.tx.dequeue_pkts;
  prev_app_stats.tx.tx_pkts = app_stats.tx.tx_pkts;
  prev_app_stats.tx.enqdrop_pkts = app_stats.tx.enqdrop_pkts;
}

// display usage
static void
print_usage(const char *prgname)
{
  printf("This program uses an FPGA to classify examples from the CIFAR10 dataset at 122K FPS and 20us latency"
	 "%s [EAL options] -- -p PORTMASK -m MODE -i NO_IMG\n"
	 "  -p PORTMASK: hexadecimal bitmask of ports to configure ( default is 1 )\n"
	 "  -m MODE: mode use 'd' for debug mode, default is normal operation\n"
	 "  -i NO_IMG: number of images to run before stopping, use 0 for continuous ( default )\n",
	 prgname);
}

static int
parse_portmask(const char *portmask)
{
  char *end = NULL;
  unsigned long pm;
  // parse hexadecimal string
  pm = strtoul(portmask, &end, 16);
  if ((portmask[0] == '\0') || (end == NULL) || (*end != '\0'))
    return -1;
  if (pm == 0)
    return -1;
  return pm;
}

// Parse the argument given in the command line of the application
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
  while ((opt = getopt_long(argc, argvopt, "p:m:i:",
			    lgopts, &option_index)) != EOF) {
    switch (opt) {
    case 'p':
      enabled_port_mask = parse_portmask(optarg);
      if (enabled_port_mask != 1) {
	printf("invalid portmask\n");
	print_usage(prgname);
	return -1;
      }
      break;

    case 'i':
      num_loops = parse_portmask(optarg);
      break;

    case 'm':
      if ( optarg[0] == 'd' )
	debug_mode = 1;
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

int
main(int argc, char *argv[])
{
  struct rte_mempool *mbuf_pool;
  unsigned lcore_id, worker_id = 1;
  unsigned nb_ports;
  uint16_t portid;
  uint16_t nb_ports_available;

  signal(SIGINT, int_handler);

  // Begin initialization and parameter parsing
  int ret = rte_eal_init(argc, argv);
  if (ret < 0)
    rte_exit(EXIT_FAILURE, "Error with EAL initialization\n");
  argc -= ret;
  argv += ret;
  freq = rte_get_timer_hz();

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
  if (nb_ports != 1)
    rte_exit(EXIT_FAILURE, "Error: only for a single port\n");

  mbuf_pool = rte_pktmbuf_pool_create("RX_MBUF_POOL",
				      NUM_MBUFS * nb_ports, MBUF_CACHE_SIZE, 0,
				      CLASSIFICATION_PACKET_SIZE, rte_socket_id());
  if (mbuf_pool == NULL)
    rte_exit(EXIT_FAILURE, "Cannot create mbuf pool\n");
  nb_ports_available = nb_ports;

  RTE_ETH_FOREACH_DEV(portid) {
    if ((enabled_port_mask & (1 << portid)) == 0) {
      printf("\nSkipping disabled port %d\n", portid);
      nb_ports_available--;
      continue;
    }
    printf("Initializing port %u... done\n", portid);
    if (port_init(portid, mbuf_pool) != 0)
      rte_exit(EXIT_FAILURE, "Cannot initialize port %u\n",
	       portid);
  }
  if (!nb_ports_available) {
    rte_exit(EXIT_FAILURE,
	     "All available ports are disabled. Please set portmask.\n");
  }

  // Launch the slave processes
  RTE_LCORE_FOREACH_SLAVE(lcore_id) {
    if (worker_id == 1) {
      printf("Starting rx on lcore_id %d\n", lcore_id);
      rte_eal_remote_launch((lcore_function_t *)lcore_rx, NULL, lcore_id);
    } else if (worker_id == 2) {
      printf("Starting tx on lcore_id %d\n", lcore_id);
      rte_eal_remote_launch((lcore_function_t *)lcore_tx, NULL, lcore_id);
    }
    worker_id++;
  }
  RTE_LCORE_FOREACH_SLAVE(lcore_id) {
    if (rte_eal_wait_lcore(lcore_id) < 0)
      return -1;
  }
  printf( "Comparing files 'labels' and 'preds'\n" );
  FILE * labels = fopen( "labels", "r" );
  if ( !labels )
    rte_exit(EXIT_FAILURE, "Cannot open labels\n" );
  FILE * preds = fopen( "preds", "r" );
  if ( !preds )
    rte_exit(EXIT_FAILURE, "Cannot open preds\n" );
  int i;
  float correct_cnt = 0;
  char l, p;
  for ( i = 0; i < NUM_IMGS; i++ ) {
    fread( &p, 1, 1, preds );
    fread( &l, 1, 1, labels );
    if ( l == p )
      correct_cnt += 1;
  }
  printf( "accuracy on the first %i images is %f%%\n", NUM_IMGS, ( correct_cnt/NUM_IMGS ) * 100 );
  return 0;
}
