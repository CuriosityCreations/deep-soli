# How to make

- Install hdf5

      sudo apt-get install libhdf5-serial-dev

- Modify Makefile Line 4

      CFLAGS=-c -Wall -std=c++11 -O3 -I/usr/include/hdf5/serial
