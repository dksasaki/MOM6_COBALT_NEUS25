#!/bin/bash

#===============================================================================
# HPC SOFTWARE STACK BUILD SCRIPT DOCUMENTATION
#===============================================================================
#
# OVERVIEW
# --------
# This script builds a complete user-space High Performance Computing software 
# stack using Intel 2025.0.4 compilers. It creates a scientific computing 
# environment without requiring root access, optimized for InfiniBand networks 
# and parallel computing.
#
# PURPOSE
# -------
# Build a complete HPC software stack for scientific applications that require:
#   • High-performance MPI communication over InfiniBand
#   • Parallel I/O capabilities for large datasets
#   • Intel compiler optimizations for performance
#   • User-space installation (no root access required)
#
#===============================================================================
# SOFTWARE COMPONENTS
#===============================================================================
#
# BUILD ORDER: RDMA-Core → UCX → OpenMPI → zlib → HDF5 → NetCDF-C → NetCDF-Fortran
#
# 1. RDMA-CORE
#    Purpose: Provides user-space InfiniBand libraries (libibverbs, librdmacm)
#    Why needed: System administrators typically don't install RDMA development 
#                packages. These libraries are essential for high-performance 
#                InfiniBand communication in HPC environments.
#    Dependencies: None
#
# 2. UCX (UNIFIED COMMUNICATION X)
#    Purpose: High-performance communication layer optimized for InfiniBand networks
#    Dependencies: RDMA-Core
#
# 3. OPENMPI 5.0.5
#    Purpose: MPI implementation with UCX backend for optimal InfiniBand performance
#    Dependencies: UCX, RDMA-Core
#    Note: C++ bindings disabled (incompatible with OpenMPI 5.0+)
#
# 4. ZLIB
#    Purpose: Compression library required by scientific I/O libraries
#    Dependencies: None
#
# 5. HDF5 1.14.3
#    Purpose: Parallel scientific data I/O library
#    Dependencies: OpenMPI, zlib
#    Note: Parallel mode only (C++ bindings disabled for MPI compatibility)
#
# 6. NETCDF-C 4.9.2
#    Purpose: Network Common Data Format for scientific data storage
#    Dependencies: HDF5, zlib, OpenMPI
#
# 7. NETCDF-FORTRAN 4.6.1
#    Purpose: Fortran bindings for NetCDF
#    Dependencies: NetCDF-C
#
#===============================================================================
# INTEL 2025.0.4 COMPILER SETUP
#===============================================================================
#
# COMPILER CHANGES
# ----------------
#   • C:       icx     (replaces icc)
#   • C++:     icpx    (replaces icpc) 
#   • Fortran: ifx     (replaces ifort)
#
# CRITICAL COMPILER FLAGS
# ------------------------
#   • -fno-finite-math-only:      Prevents aggressive math optimizations that break HDF5
#   • -fp-model precise:          Ensures numerical stability for scientific computing
#   • -diag-disable=10441:        Suppresses Intel-specific warnings
#   • -Wno-unused-but-set-variable: Suppresses LLVM warnings in legacy code
#   • -xSSE4.2 -axCORE-AVX2,CORE-AVX512:     Architecture-specific optimizations (multiple)
#
#===============================================================================
# KNOWN ISSUES AND SOLUTIONS
#===============================================================================
#
# HDF5 INSTALLATION ISSUE
# ------------------------
# Problem:  make install fails with Intel 2025.0.4 compilers
# Solution: Automatic fallback to manual file copying with path correction
#
# NETCDF-FORTRAN ZSTD WARNING
# ----------------------------
# Problem:  Warning about missing HDF5_PLUGIN_PATH for zstd compression
# Solution: Automatic plugin path detection and setup (cosmetic fix)
#
# INTEL RUNTIME LIBRARIES
# ------------------------
# Problem:  Compiled binaries require Intel runtime libraries (libsvml.so)
# Solution: Automatic INTEL_ROOT detection and library path setup
#
#===============================================================================
# HARDWARE OPTIMIZATION
#===============================================================================
#
# CONNECTX-5 INFINIBAND SETTINGS
# -------------------------------
#   • UCX transport selection:    rc_mlx5,ud_mlx5,self,sm
#   • Device specification:       mlx5_0:1
#   • Registration cache optimization
#   • OpenMPI UCX backend configuration
#
#===============================================================================
# USAGE
#===============================================================================
#
# PREREQUISITES
# -------------
#   • Intel OneAPI 2025.0.4 modules loaded
#   • ConnectX-5 InfiniBand hardware
#   • Git access for RDMA-Core download
#   • Internet access for package downloads
#
# ENVIRONMENT SETUP
# -----------------
# After installation, users must configure their environment with:
#   • Library paths (LD_LIBRARY_PATH)
#   • Compiler wrapper paths (MPICC, MPIFC)
#   • UCX runtime settings for InfiniBand
#   • OpenMPI configuration for optimal performance
#
# VERIFICATION
# ------------
# The script provides testing commands for each component:
#   • UCX transport verification
#   • MPI functionality testing
#   • HDF5 parallel capabilities
#   • NetCDF library integration
#
#===============================================================================
# TARGET APPLICATIONS
#===============================================================================
#
# This stack is designed for scientific applications requiring:
#   • Large-scale parallel computing
#   • High-bandwidth data I/O
#   • InfiniBand network utilization
#   • Intel compiler optimizations
#   • HDF5/NetCDF data formats
#
# The resulting environment supports typical HPC workloads including climate 
# modeling, computational fluid dynamics, and other data-intensive scientific 
# computing applications.
#
#===============================================================================

set -e  # Exit on any error

# Load Intel modules
module load intel/compilers-rt-2025.0.4
module load intel/tbb-2022.0
module load intel/umf-0.9.1
module load intel/compilers-2025.0.4

# Check if SOFTWARE_DIR is provided as command line argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <SOFTWARE_DIR>"
    echo "Example: $0 /home/d.sasaki/install/mom6_202411d/dependencies"
    exit 1
fi

SOFTWARE_DIR="$1"

# Intel 2025.0.4 compiler setup
export FC=ifx
export CC=icx  
export CXX=icpx
export F77=ifx
export F90=ifx
export CPP='icx -E'
export CXXCPP='icpx -E'

# Base environment setup
export PATH=$SOFTWARE_DIR/bin:$PATH
export LD_LIBRARY_PATH=$SOFTWARE_DIR/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$SOFTWARE_DIR/lib:$LIBRARY_PATH
export CPATH=$SOFTWARE_DIR/include:$CPATH
export PKG_CONFIG_PATH=$SOFTWARE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
export CPPFLAGS="-I${SOFTWARE_DIR}/include" 
export LDFLAGS="-L${SOFTWARE_DIR}/lib -Wl,-rpath,${SOFTWARE_DIR}/lib" 

# Intel 2025.0.4 optimized compiler flags with warning suppressions
export CFLAGS="-fPIC -O3 -xSSE4.2 -axCORE-AVX2,CORE-AVX512 -fno-finite-math-only -diag-disable=10441 -Wno-unused-but-set-variable -Wno-recommended-option"
export CXXFLAGS="-fPIC -O3 -xSSE4.2 -axCORE-AVX2,CORE-AVX512 -fno-finite-math-only -diag-disable=10441 -Wno-unused-but-set-variable -Wno-recommended-option"
export FFLAGS="-fPIC -O3 -xSSE4.2 -axCORE-AVX2,CORE-AVX512"
export FCFLAGS="-fPIC -O3 -xSSE4.2 -axCORE-AVX2,CORE-AVX512"

# Check if directory exists and warn about conflicts
if [ -d "$SOFTWARE_DIR" ] && [ "$(ls -A $SOFTWARE_DIR 2>/dev/null)" ]; then
    echo "Warning: $SOFTWARE_DIR is not empty."
    echo "This may cause conflicts with existing installations."
    read -p "Do you want to proceed anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
    echo "Proceeding with installation..."
fi

# Create directories
mkdir -p $SOFTWARE_DIR/{src,build,include,lib,bin}
cd $SOFTWARE_DIR/src

echo "=== Building RDMA-Core from Source ==="

# Clean up previous attempts
rm -rf rdma-core

# Clone rdma-core (stable branch)
git clone https://github.com/linux-rdma/rdma-core.git
cd rdma-core

# Check out a stable tag instead of master
git checkout stable-v57

# Create build directory
mkdir -p build
cd build

# Configure rdma-core for user installation with Intel 2025.0.4 compatibility
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$SOFTWARE_DIR \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=icx \
    -DCMAKE_CXX_COMPILER=icpx \
    -DCMAKE_C_FLAGS="$CFLAGS -Wno-error=unused-but-set-variable" \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-error=unused-but-set-variable" \
    -DENABLE_STATIC=ON \
    -DENABLE_RESOLVE_NEIGH=OFF \
    -DNO_MAN_PAGES=ON \
    -DCMAKE_INSTALL_SYSCONFDIR=$SOFTWARE_DIR/etc \
    -DCMAKE_INSTALL_SYSTEMD_SERVICEDIR=$SOFTWARE_DIR/lib/systemd/system

# Build and install
make -j$(nproc)
make install

echo "=== RDMA-Core Installation Verification ==="
echo "Headers installed:"
ls -la $SOFTWARE_DIR/include/rdma/rdma_cma.h
ls -la $SOFTWARE_DIR/include/infiniband/verbs.h
echo ""
echo "Libraries installed:"
ls -la $SOFTWARE_DIR/lib/librdmacm.so*
ls -la $SOFTWARE_DIR/lib/libibverbs.so*

echo "=== Building UCX with User-Space RDMA ==="
cd $SOFTWARE_DIR/src

# Clean up previous UCX builds
rm -rf ucx-1.16.0*

# Download UCX 1.16.0
if [ ! -f ucx-1.16.0.tar.gz ]; then
    wget https://github.com/openucx/ucx/releases/download/v1.16.0/ucx-1.16.0.tar.gz
fi
tar -xzf ucx-1.16.0.tar.gz
cd ucx-1.16.0

# Configure UCX with user-space RDMA libraries
./configure --prefix=$SOFTWARE_DIR \
    --with-verbs=$SOFTWARE_DIR \
    --with-rdmacm=$SOFTWARE_DIR \
    --with-mlx5-dv \
    --enable-mt \
    --enable-optimizations \
    --enable-shared \
    --disable-logging \
    --disable-debug \
    --disable-assertions \
    --disable-params-check \
    --with-rc \
    --with-ud \
    --with-dc \
    CC=icx CXX=icpx \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    IBVERBS_CPPFLAGS="-I${SOFTWARE_DIR}/include" \
    IBVERBS_LDFLAGS="-L${SOFTWARE_DIR}/lib" \
    RDMACM_CPPFLAGS="-I${SOFTWARE_DIR}/include" \
    RDMACM_LDFLAGS="-L${SOFTWARE_DIR}/lib"

# Check configure results
echo "=== UCX Configure Results ==="
if [ $? -eq 0 ]; then
    echo "✓ Configure succeeded!"
    
    # Verify RDMA components were found
    echo "Checking for RDMA support in config.log:"
    grep -i "checking.*ibv_get_device_list.*yes" config.log && echo "✓ InfiniBand Verbs detected" || echo "✗ InfiniBand Verbs not detected"
    grep -i "checking.*rdma_create_id.*yes" config.log && echo "✓ RDMA CM detected" || echo "✗ RDMA CM not detected"
    grep -i "mlx5.*found\|mlx5.*yes" config.log | head -2
    
    echo "=== Building UCX ==="
    make -j$(nproc)
    make install
    
    echo "=== UCX Installation Verification ==="
    echo "UCX version: $($SOFTWARE_DIR/bin/ucx_info -v)"
    echo ""
    echo "Available transports:"
    $SOFTWARE_DIR/bin/ucx_info -d | grep -E "Transport:" | head -10
    echo ""
    echo "Looking for InfiniBand transports:"
    IB_TRANSPORTS=$($SOFTWARE_DIR/bin/ucx_info -d | grep -E "rc_|ud_|mlx5")
    if [[ -n "$IB_TRANSPORTS" ]]; then
        echo "✓ InfiniBand transports found:"
        echo "$IB_TRANSPORTS"
    else
        echo "⚠ No specific InfiniBand transports found, but basic UCX functionality available"
    fi
else
    echo "✗ Configure failed"
    echo "Last 10 lines of config.log:"
    tail -10 config.log
    exit 1
fi

echo "=== Building OpenMPI 5.0.5 with UCX and Intel 2025.0.4 ==="
cd $SOFTWARE_DIR/src

# Clean up previous OpenMPI builds
rm -rf openmpi-5.0.5*

# Download OpenMPI 5.0.5
if [ ! -f openmpi-5.0.5.tar.gz ]; then
    wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.5.tar.gz
fi
tar -xzf openmpi-5.0.5.tar.gz
cd openmpi-5.0.5

echo "=== Configuring OpenMPI 5.0.5 ==="
# Configure OpenMPI with UCX backend and Intel 2025.0.4 compatibility
# Note: OpenMPI 5.0+ removed MPI C++ bindings - do not enable them
CC=icx CXX=icpx FC=ifx \
./configure --prefix=$SOFTWARE_DIR \
    --with-ucx=$SOFTWARE_DIR \
    --with-ucx-libdir=$SOFTWARE_DIR/lib \
    --with-verbs \
    --with-rdmacm \
    --enable-mpi-fortran=yes \
    --enable-shared \
    --enable-static \
    --with-pmix=internal \
    --with-libevent=internal \
    --with-hwloc=internal \
    --enable-mca-no-build=btl-uct \
    --disable-getpwuid \
    --disable-oshmem \
    --disable-mpi-cxx \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    FCFLAGS="$FCFLAGS" \
    FFLAGS="$FFLAGS" \
    LDFLAGS="$LDFLAGS"

# Check configure results
if [ $? -eq 0 ]; then
    echo "✓ OpenMPI configure succeeded!"
    
    # Verify UCX and RDMA support was found
    echo "=== Checking OpenMPI Configuration ==="
    echo "UCX support:"
    grep -i "ucx.*yes\|checking.*ucx.*found" config.log | head -3
    echo "InfiniBand Verbs support:"  
    grep -i "verbs.*yes\|checking.*verbs.*found" config.log | head -3
    echo "RDMA CM support:"
    grep -i "rdmacm.*yes\|checking.*rdmacm.*found" config.log | head -3
    
    echo "=== Building OpenMPI ==="
    make -j$(nproc)
    make install
    
    echo "=== OpenMPI Installation Verification ==="
    echo "OpenMPI version: $($SOFTWARE_DIR/bin/mpirun --version | head -1)"
    echo ""
    echo "MPI compilers installed:"
    ls -la $SOFTWARE_DIR/bin/mpi*
    echo ""
    echo "Checking for UCX support:"
    $SOFTWARE_DIR/bin/ompi_info --parsable --all | grep -E "mca:pml:ucx" && echo "✓ UCX PML found" || echo "⚠ UCX PML not found"
    echo ""
    echo "Testing basic MPI:"
    $SOFTWARE_DIR/bin/mpirun -np 1 hostname || echo "⚠ MPI test failed"
else
    echo "✗ OpenMPI configure failed"
    echo "Last 15 lines of config.log:"
    tail -15 config.log
    exit 1
fi

echo "=== Building zlib 1.3.1 ==="
cd $SOFTWARE_DIR/src

# Clean up previous zlib builds
rm -rf zlib-1.3.1*

# Download zlib 1.3.1
if [ ! -f zlib-1.3.1.tar.gz ]; then
    wget https://zlib.net/zlib-1.3.1.tar.gz
fi
tar -xzf zlib-1.3.1.tar.gz
cd zlib-1.3.1

echo "=== Configuring zlib 1.3.1 with Intel 2025.0.4 ==="
# Configure zlib with Intel compilers
CC=icx \
CFLAGS="$CFLAGS" \
./configure --prefix=$SOFTWARE_DIR \
    --shared \
    --static

# Check configure results
if [ $? -eq 0 ]; then
    echo "✓ zlib configure succeeded!"
    
    echo "=== Building zlib ==="
    make -j$(nproc)
    make install
    
    echo "=== zlib Installation Verification ==="
    echo "zlib library files:"
    ls -la $SOFTWARE_DIR/lib/libz.*
    echo ""
    echo "zlib headers:"
    ls -la $SOFTWARE_DIR/include/zlib.h
else
    echo "✗ zlib configure failed"
    exit 1
fi

echo "=== Building HDF5 1.14.3 with Parallel Support ==="
cd $SOFTWARE_DIR/src

# Clean up previous HDF5 builds
rm -rf hdf5-1.14.3*

# Download HDF5 1.14.3
if [ ! -f hdf5-1.14.3.tar.gz ]; then
    wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.3/src/hdf5-1.14.3.tar.gz
fi
tar -xzf hdf5-1.14.3.tar.gz
cd hdf5-1.14.3

# Set up environment for parallel HDF5 build  
export HDF5_CC=$SOFTWARE_DIR/bin/mpicc
export HDF5_FC=$SOFTWARE_DIR/bin/mpifort

# Intel 2025.0.4 specific flags for HDF5
export HDF5_CFLAGS="-fPIC -O3 -xSSE4.2 -axCORE-AVX2,CORE-AVX512 -fp-model precise -fno-finite-math-only -diag-disable=10441 -Wno-unused-but-set-variable -Wno-recommended-option"
export HDF5_FCFLAGS="-fPIC -O3 -xSSE4.2 -axCORE-AVX2,CORE-AVX512 -fp-model precise"

echo "=== Configuring HDF5 1.14.3 for Parallel I/O ==="
# Configure HDF5 with parallel support and Intel 2025.0.4 compatibility
# Note: --enable-cxx is incompatible with --enable-parallel in HDF5
CC=$HDF5_CC \
FC=$HDF5_FC \
CFLAGS="$HDF5_CFLAGS" \
FCFLAGS="$HDF5_FCFLAGS" \
CPPFLAGS="-I${SOFTWARE_DIR}/include" \
LDFLAGS="-L${SOFTWARE_DIR}/lib -Wl,-rpath,${SOFTWARE_DIR}/lib" \
./configure --prefix=$SOFTWARE_DIR \
    --enable-parallel \
    --enable-fortran \
    --enable-shared \
    --enable-static \
    --enable-hl \
    --enable-build-mode=production \
    --with-zlib=$SOFTWARE_DIR \
    --with-default-api-version=v114 \
    --disable-sharedlib-rpath \
    --disable-tests \
    --disable-tools

# Check configure results
if [ $? -eq 0 ]; then
    echo "✓ HDF5 configure succeeded!"
    
    # Verify parallel and zlib support was found
    echo "=== Checking HDF5 Configuration ==="
    echo "Parallel support:"
    grep -i "parallel.*yes\|mpi.*yes" config.log | head -3
    echo "Zlib support:"
    grep -i "zlib.*yes\|deflate.*yes" config.log | head -2
    
    echo "=== Building HDF5 (this may take several minutes) ==="
    # Use single core for HDF5 to avoid Intel compiler issues
    make -j1
    
    if [ $? -eq 0 ]; then
        echo "✓ Build succeeded, installing..."
        make install
        
        # Handle known Intel 2025.0.4 installation issue - manual copy if needed
        if [ ! -f "$SOFTWARE_DIR/bin/h5cc" ] && [ -f "bin/h5cc" ]; then
            echo "⚠ HDF5 make install failed, copying files manually..."
            cp -r bin/* $SOFTWARE_DIR/bin/ 2>/dev/null || true
            cp -r lib/* $SOFTWARE_DIR/lib/ 2>/dev/null || true
            cp -r include/* $SOFTWARE_DIR/include/ 2>/dev/null || true
            
            # Fix h5cc paths
            if [ -f "$SOFTWARE_DIR/bin/h5cc" ]; then
                sed -i "s|prefix=\".*\"|prefix=\"$SOFTWARE_DIR\"|g" $SOFTWARE_DIR/bin/h5cc
                sed -i "s|exec_prefix=\".*\"|exec_prefix=\"$SOFTWARE_DIR\"|g" $SOFTWARE_DIR/bin/h5cc
            fi
        fi
        
        echo "=== HDF5 Installation Verification ==="
        if [ -f "$SOFTWARE_DIR/bin/h5cc" ]; then
            echo "✓ HDF5 installation verified"
            echo "HDF5 version: $($SOFTWARE_DIR/bin/h5cc -showconfig | grep 'HDF5 Version:' || echo 'HDF5 installed')"
        else
            echo "✗ HDF5 installation failed - h5cc not found"
            exit 1
        fi
    else
        echo "✗ HDF5 build failed"
        exit 1
    fi
else
    echo "✗ HDF5 configure failed"
    echo "Last 15 lines of config.log:"
    tail -15 config.log
    exit 1
fi

echo "=== Building NetCDF-C 4.9.2 ==="
cd $SOFTWARE_DIR/src

# Clean up previous NetCDF-C builds
rm -rf netcdf-c-4.9.2*

# Download NetCDF-C 4.9.2
if [ ! -f netcdf-c-4.9.2.tar.gz ]; then
    wget https://downloads.unidata.ucar.edu/netcdf-c/4.9.2/netcdf-c-4.9.2.tar.gz
fi
tar -xzf netcdf-c-4.9.2.tar.gz
cd netcdf-c-4.9.2

# Set up environment for NetCDF-C build with HDF5 and zlib
export NETCDF_CC=$SOFTWARE_DIR/bin/mpicc
export NETCDF_CFLAGS="-fPIC -O3 -xSSE4.2 -axCORE-AVX2,CORE-AVX512 -fp-model precise -fno-finite-math-only -diag-disable=10441 -Wno-unused-but-set-variable -Wno-recommended-option"

echo "=== Configuring NetCDF-C 4.9.2 with HDF5 and MPI support ==="
# Configure NetCDF-C with parallel support, HDF5, and zlib
CC=$NETCDF_CC \
CFLAGS="$NETCDF_CFLAGS" \
CPPFLAGS="-I${SOFTWARE_DIR}/include" \
LDFLAGS="-L${SOFTWARE_DIR}/lib -Wl,-rpath,${SOFTWARE_DIR}/lib" \
./configure --prefix=$SOFTWARE_DIR \
    --enable-netcdf-4 \
    --enable-shared \
    --enable-static \
    --enable-parallel-tests \
    --disable-dap \
    --disable-byterange \
    --with-hdf5=$SOFTWARE_DIR \
    --with-zlib=$SOFTWARE_DIR

# Check configure results
if [ $? -eq 0 ]; then
    echo "✓ NetCDF-C configure succeeded!"
    
    # Verify HDF5 and zlib support was found
    echo "=== Checking NetCDF-C Configuration ==="
    echo "HDF5 support:"
    grep -i "hdf5.*yes\|netcdf.*4.*yes" config.log | head -3
    echo "Zlib support:"
    grep -i "zlib.*yes\|deflate.*yes" config.log | head -2
    
    echo "=== Building NetCDF-C ==="
    make -j$(nproc)
    make install
    
    # Verify installation
    if [ -f "$SOFTWARE_DIR/bin/nc-config" ]; then
        echo "✓ NetCDF-C installation verified"
        echo "NetCDF-C version: $($SOFTWARE_DIR/bin/nc-config --version)"
    else
        echo "✗ NetCDF-C installation failed - nc-config not found"
        exit 1
    fi
else
    echo "✗ NetCDF-C configure failed"
    echo "Last 15 lines of config.log:"
    tail -15 config.log
    exit 1
fi

echo "=== Building NetCDF-Fortran 4.6.1 ==="
cd $SOFTWARE_DIR/src

# Clean up previous NetCDF-Fortran builds
rm -rf netcdf-fortran-4.6.1*

# Download NetCDF-Fortran 4.6.1
if [ ! -f netcdf-fortran-4.6.1.tar.gz ]; then
    wget https://downloads.unidata.ucar.edu/netcdf-fortran/4.6.1/netcdf-fortran-4.6.1.tar.gz
fi
tar -xzf netcdf-fortran-4.6.1.tar.gz
cd netcdf-fortran-4.6.1

# Set up environment for NetCDF-Fortran build
export NETCDFF_CC=$SOFTWARE_DIR/bin/mpicc
export NETCDFF_FC=$SOFTWARE_DIR/bin/mpifort
export NETCDFF_CFLAGS="-fPIC -O3 -xSSE4.2 -axCORE-AVX2,CORE-AVX512 -fp-model precise -fno-finite-math-only -diag-disable=10441 -Wno-unused-but-set-variable -Wno-recommended-option"
export NETCDFF_FCFLAGS="-fPIC -O3 -xSSE4.2 -axCORE-AVX2,CORE-AVX512 -fp-model precise"

# Set NetCDF-C location for NetCDF-Fortran
export NCDIR=$SOFTWARE_DIR

# Optional: Set HDF5 plugin path to avoid zstd warning
PLUGIN_DIR=$($SOFTWARE_DIR/bin/nc-config --plugindir 2>/dev/null)
if [ -n "$PLUGIN_DIR" ] && [ -d "$PLUGIN_DIR" ]; then
    export HDF5_PLUGIN_PATH="$PLUGIN_DIR"
    echo "Setting HDF5_PLUGIN_PATH=$HDF5_PLUGIN_PATH for NetCDF-Fortran"
fi

echo "=== Configuring NetCDF-Fortran 4.6.1 ==="
# Configure NetCDF-Fortran with NetCDF-C dependency
CC=$NETCDFF_CC \
FC=$NETCDFF_FC \
CFLAGS="$NETCDFF_CFLAGS" \
FCFLAGS="$NETCDFF_FCFLAGS" \
CPPFLAGS="-I${SOFTWARE_DIR}/include" \
LDFLAGS="-L${SOFTWARE_DIR}/lib -Wl,-rpath,${SOFTWARE_DIR}/lib" \
./configure --prefix=$SOFTWARE_DIR \
    --enable-shared \
    --enable-static \
    --enable-parallel-tests

# Check configure results
if [ $? -eq 0 ]; then
    echo "✓ NetCDF-Fortran configure succeeded!"
    
    # Verify NetCDF-C was found
    echo "=== Checking NetCDF-Fortran Configuration ==="
    echo "NetCDF-C support:"
    grep -i "netcdf.*found\|netcdf.*yes" config.log | head -3
    
    echo "=== Building NetCDF-Fortran ==="
    make -j$(nproc)
    make install
    
    # Verify installation
    if [ -f "$SOFTWARE_DIR/bin/nf-config" ]; then
        echo "✓ NetCDF-Fortran installation verified"
        echo "NetCDF-Fortran version: $($SOFTWARE_DIR/bin/nf-config --version)"
    else
        echo "✗ NetCDF-Fortran installation failed - nf-config not found"
        exit 1
    fi
else
    echo "✗ NetCDF-Fortran configure failed"
    echo "Last 15 lines of config.log:"
    tail -15 config.log
    exit 1
fi

echo "=== Complete Environment Setup Instructions ==="
echo ""
echo "Add these to your environment setup script or .bashrc:"
echo "# Load Intel compilers"
echo "module load intel/compilers-rt-2025.0.4"
echo "module load intel/tbb-2022.0" 
echo "module load intel/umf-0.9.1"
echo "module load intel/compilers-2025.0.4"
echo ""
echo "# Set up user-space libraries"
echo "export PATH=$SOFTWARE_DIR/bin:\$PATH"
echo "export LD_LIBRARY_PATH=$SOFTWARE_DIR/lib:\$LD_LIBRARY_PATH"
echo "export PKG_CONFIG_PATH=$SOFTWARE_DIR/lib/pkgconfig:\$PKG_CONFIG_PATH"
echo "export CPATH=$SOFTWARE_DIR/include:\$CPATH"
echo ""
echo "# Intel runtime libraries (essential for Intel-compiled binaries)"
echo "export INTEL_ROOT=\$(dirname \$(dirname \$(which icx)))"
echo "export LD_LIBRARY_PATH=\$INTEL_ROOT/lib:\$LD_LIBRARY_PATH"
echo ""
echo "# MPI compiler wrappers"
echo "export MPICC=$SOFTWARE_DIR/bin/mpicc"
echo "export MPICXX=$SOFTWARE_DIR/bin/mpicxx"  
echo "export MPIFC=$SOFTWARE_DIR/bin/mpifort"
echo "export MPIF77=$SOFTWARE_DIR/bin/mpif77"
echo "export MPIF90=$SOFTWARE_DIR/bin/mpif90"
echo ""
echo "# Optimal UCX runtime settings for ConnectX-5"
echo "export UCX_NET_DEVICES=mlx5_0:1"
echo "export UCX_TLS=rc_mlx5,ud_mlx5,self,sm"
echo "export UCX_IB_REG_METHODS=rcache"
echo "export UCX_RNDV_THRESH=8192"
echo ""
echo "# OpenMPI runtime settings for optimal performance"
echo "export OMPI_MCA_pml=ucx"
echo "export OMPI_MCA_osc=ucx"
echo "export OMPI_MCA_btl=^vader,tcp,openib,uct"
echo ""
echo "# Alternative: Native IB verbs if UCX issues occur"
echo "# export OMPI_MCA_pml=ob1" 
echo "# export OMPI_MCA_btl=openib,vader,self"
echo ""
echo "=== Testing Commands ==="
echo "Test UCX:"
echo "$SOFTWARE_DIR/bin/ucx_info -d"
echo ""
echo "Test MPI:"
echo "$SOFTWARE_DIR/bin/mpirun --version"
echo "$SOFTWARE_DIR/bin/ompi_info | grep -i ucx"
echo ""
echo "Test HDF5:"
echo "$SOFTWARE_DIR/bin/h5cc -showconfig | grep -i parallel"
echo "ls $SOFTWARE_DIR/lib/libhdf5*"
echo ""
echo "Test NetCDF-C:"
echo "$SOFTWARE_DIR/bin/nc-config --version"
echo "$SOFTWARE_DIR/bin/nc-config --has-hdf5"
echo ""
echo "Test NetCDF-Fortran:"
echo "$SOFTWARE_DIR/bin/nf-config --version"
echo ""
echo "Create test programs:"
echo "# MPI Hello World"
echo "echo 'program hello; use mpi; call MPI_INIT(ierr); call MPI_FINALIZE(ierr); end program' > test_mpi.f90"
echo "$SOFTWARE_DIR/bin/mpifort test_mpi.f90 -o test_mpi"
echo "srun -n 2 ./test_mpi"
echo ""
echo "# NetCDF test"
echo "echo '#include <netcdf.h>' > test_netcdf.c"
echo "echo '#include <stdio.h>' >> test_netcdf.c"
echo "echo 'int main() { printf(\"NetCDF: %s\\n\", nc_inq_libvers()); return 0; }' >> test_netcdf.c"
echo "\$(\$SOFTWARE_DIR/bin/nc-config --cc) \$(\$SOFTWARE_DIR/bin/nc-config --cflags) test_netcdf.c \$(\$SOFTWARE_DIR/bin/nc-config --libs) -o test_netcdf"
echo "./test_netcdf"

echo "=== User-Space HPC Stack Build Completed Successfully ==="
