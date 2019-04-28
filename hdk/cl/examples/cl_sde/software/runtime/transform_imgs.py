#! /usr/bin/python3

'''
This file takes the cifar10 binary format images and converts them
for use with this fpga example
'''

import numpy as np

def parse_img( img_bin ):
  label = img_bin[0]
  r = np.array( list( img_bin[1:1025] ) )
  g = np.array( list( img_bin[1025:2049] ) )
  b = np.array( list( img_bin[2049:] ) )
  r = np.reshape( r, [ 1024, 1 ] )
  g = np.reshape( g, [ 1024, 1 ] )
  b = np.reshape( b, [ 1024, 1 ] )
  img = np.concatenate( [ r, g, b ], axis = 1 )
  img = img.astype( float )
  nu = np.mean( img )
  stddev = np.std( img )
  adj_stddev = max( stddev, np.sqrt( 1 / ( 1024 * 3 ) ) )
  img = (img - nu)/adj_stddev
  img = np.round( img * ( 1 << 4 ) )
  img = img.astype( int )
  img = img + ( img < 0 )*( 1 << 16 )
  img_h = img[:,0] + ( img[:,1] * ( 1 << 16 ) ) + ( img[:,2] * ( 1 << 32 ) )
  return label, img_h

if __name__ == "__main__":
  f = open( "test_batch.bin", "rb" )
  data = f.read()
  f_img = open( "test_batches.hex", "wb" )
  f_lab = open( "labels", "w" )
  for i in range( 10000 ):
    label, img = parse_img( data[i*3073:(i+1)*3073] )
    t = f_lab.write( str(label) )
    for x in img:
      t = f_img.write( x )
  f_lab.close()
  f_img.close()
