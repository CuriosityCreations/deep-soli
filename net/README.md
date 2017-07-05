#!/usr/bin/env bash

# Install base
sudo apt-get update
sudo apt-get install -y \
    git \
    curl \
    wget \
    g++ \
    automake \
    autoconf \
    autoconf-archive \
    libtool \
    libboost-all-dev \
    libevent-dev \
    libdouble-conversion-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    liblz4-dev \
    liblzma-dev \
    libsnappy-dev \
    make \
    zlib1g-dev \
    binutils-dev \
    libjemalloc-dev \
    $extra_packages \
    flex \
    bison \
    libkrb5-dev \
    libsasl2-dev \
    libnuma-dev \
    pkg-config \
    libssl-dev \
    libedit-dev \
    libmatio-dev \
    libpython-dev \
    libpython3-dev \
    python-numpy

sudo apt-get install -y build-essential
sudo apt-get install -y python-pip
sudo apt-get install -y zsh
sudo sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
sudo chown -R ubuntu:ubuntu ~/.zsh*
sudo chown -R ubuntu:ubuntu ~/.oh-my-zsh
sudo pip install awscli

# Install gcc 4.9 for c++14 support
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install g++-4.9
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 10
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 20

sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 20

sudo update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30
sudo update-alternatives --set cc /usr/bin/gcc

sudo update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30
sudo update-alternatives --set c++ /usr/bin/g++


# configure locales
export LC_ALL="en_US.UTF-8"
sudo locale-gen en_US en_US.UTF-8
sudo dpkg-reconfigure locales

# Install torch
git clone https://github.com/torch/distro.git ~/torch --recursive
cd ~/torch
sudo bash install-deps
./install.sh
echo '. /home/ubuntu/src/torch/install/bin/torch-activate' >> ~/.zshrc
echo '. /home/ubuntu/torch/install/bin/torch-activate' >> ~/.zshrc
echo 'alias c=clear' >> ~/.zshrc
echo 'l="ls -lh"' >> ~/.zshrc
source ~/.zshrc
cd ..
sudo chown -R ubuntu:ubuntu ./torch

# Install torch libs
luarocks install hdf5
luarocks install nn
luarocks install nngraph
luarocks install cutorch
luarocks install cunn
luarocks install cudnn
luarocks install luautf8
luarocks install class
luarocks install pprint

# Setup facebook's deep learning stack
git clone --depth 1 https://github.com/facebook/folly
cd folly/folly
autoreconf -ivf
./configure
make
sudo make install
sudo ldconfig
cd ../..

sudo add-apt-repository -y ppa:george-edison55/cmake-3.x
sudo apt-get update
sudo apt-get install -y cmake

git clone https://github.com/no1msd/mstch
cd mstch
mkdir build
cd build
cmake ..
make
sudo make install
cd ../..

git clone https://github.com/facebook/wangle
cd wangle/wangle
cmake .
make
sudo make install
cd ../..

git clone https://github.com/facebook/zstd.git
cd zstd
make
sudo make install
cd ..

git clone --depth 1 https://github.com/facebook/fbthrift
cd fbthrift/thrift
autoreconf -ivf
./configure
sudo make
sudo make install
cd ../..

git clone https://github.com/facebook/thpp
cd thpp/thpp
echo '
diff --git a/thpp/CMakeLists.txt b/thpp/CMakeLists.txt
index 4ae3683..77083cf 100644
--- a/thpp/CMakeLists.txt
+++ b/thpp/CMakeLists.txt
@@ -106,18 +106,6 @@ IF(THRIFT_FOUND)
 ENDIF()


-IF(NOT NO_TESTS)
-  ENABLE_TESTING()
-  FIND_PACKAGE(Glog REQUIRED)
-  INCLUDE_DIRECTORIES(${GLOG_INCLUDE_DIR})
-  TARGET_LINK_LIBRARIES(thpp ${GLOG_LIBRARIES})
-  ADD_SUBDIRECTORY("googletest-release-1.7.0")
-  INCLUDE_DIRECTORIES(
-    "${CMAKE_CURRENT_SOURCE_DIR}/googletest-release-1.7.0/include"
-  )
-  ADD_SUBDIRECTORY("test")
-ENDIF()
-

 # SET(CMAKE_INSTALL_PREFIX ${SAVED_CMAKE_INSTALL_PREFIX})

diff --git a/thpp/build.sh b/thpp/build.sh
index 79af5d9..4e949c4 100755
--- a/thpp/build.sh
+++ b/thpp/build.sh
@@ -49,7 +49,6 @@ cmake $FB ..
 make

 # Run tests
-ctest

 # Install
 make install
' > thpp.patch
git apply ./thpp.patch
find ./ -type f -exec sed -i -e 's/\-std=gnu++11/\-std=gnu++14/g' {} \;
./build.sh
cd ../..

git clone https://github.com/facebook/fblualib
cd fblualib/fblualib
# ./build.sh
cmake -D THPP_LIBRARY:STRING=/home/ubuntu/torch/install/lib/libthpp.so -DTHPP_INCLUDE_DIR:STRING=/home/ubuntu/torch/install/include/ .
make
sudo make install

rocks="util luaunit complex \
  ffivector editline trepl debugger mattorch python thrift torch"
version='0.1-1'
for rock in $rocks; do
  cd ./$rock
  echo $rock
  # Unfortunately, luarocks doesn't like separating the "build" and
  # "install" phases, so we have to run as root.
  luarocks make ./rockspec/*.rockspec
  cd ..
done
cd ../..

git clone https://github.com/facebook/fbnn.git && cd fbnn
luarocks make rocks/fbnn-scm-1.rockspec
cd ..

git clone https://github.com/facebookarchive/NAMAS.git
export ABS=$PWD
cd NAMAS
th summary/train.lua -help
