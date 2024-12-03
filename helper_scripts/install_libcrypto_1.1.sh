#!/bin/bash

cd ~

# Step 1: Download OpenSSL source package
wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz

# Step 2: Extract the source package
tar -xvf openssl-1.1.1w.tar.gz

# Step 3: Change to the OpenSSL source directory
cd openssl-1.1.1w

# Step 4: Configure OpenSSL
./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl

# Step 5: Build OpenSSL
make

# Step 6: Install OpenSSL
sudo make install

# Step 7: Add OpenSSL library path to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/openssl/lib:$LD_LIBRARY_PATH

# Step 8: Update library cache
sudo ldconfig -v | grep libcrypto

# Step 9:
sudo apt install libcurl4-openssl-dev

# Step 10:
sudo apt install libssl-dev


