
#ifndef __DATASET__
#define __DATASET__

static const int cifar_no_imgs = 10000;

struct cifar_dataset {
  int no_imgs;
  unsigned long ** imgs;
  char * labels;
};

struct cifar_dataset * cifar_testset();
#endif // __DATASET__
