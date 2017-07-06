# How to make

- Install hdf5

      sudo apt-get install libhdf5-serial-dev

- Modify Makefile Line 4

      CFLAGS=-c -Wall -std=c++11 -O3 -I/usr/include/hdf5/serial
      
- Libhdf link
      
      sudo ln -sf libhdf5_serial.so libhdf5.so
      sudo ln -sf libhdf5_serial_hl.so libhdf5_hl.so
