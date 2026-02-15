#!/bin/bash
# ============================================================
# Install wgrib2 v3.1.1 with dependencies in Colab/Ubuntu
# Author: Naiver
# ============================================================

# 1. Update and install dependencies
apt-get update
apt-get install -y cdo nco parallel gfortran gcc make wget tar

# 2. Download wgrib2 source archive
wget https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz.v3.1.1

# 3. Extract the archive
tar xvf wgrib2.tgz.v3.1.1
cd grib2/

# 4. Set compilation flags for gfortran
export CC=gcc
export FC=gfortran
export FFLAGS="-O2 -fallow-argument-mismatch -fdefault-real-8"
export CFLAGS="-O2"

# 5. Compile wgrib2
make

# 6. Add wgrib2 to PATH (adjust path if needed)
echo 'export PATH="/content/grib2/wgrib2:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 7. Verify installation
wgrib2 -version