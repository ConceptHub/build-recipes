#!/bin/bash
#
#SBATCH --partition=cn            # Partition
#SBATCH --job-name=compile_hdf5   # Job Name
#SBATCH --time=00:10:00           # WallTime

#SBATCH --nodes           1       # No need to allocate more than 1 node
#SBATCH --ntasks-per-node 12      # CMake will need maximum of 12 parallel
                                  # processes
#SBATCH --cpus-per-task   1       # No multithreading is requested

#SBATCH -o hdf5.%j.out            # STDOUT
#SBATCH -e hdf5.%j.err            # STDERR

NAME="hdf"
EPOCH=5
MAJOR_VERSION="1"
MINOR_VERSION_0="13"
MINOR_VERSION_1="3"

BUILD_DIR=/discofs/`whoami`/wrf-4.4

ZLIB_MODULE_NAME="zlib"
ZLIB_MAJOR_VERSION="1"
ZLIB_MINOR_VERSION="2.13"

LIBAEC_MODULE_NAME="libaec"
LIBAEC_MAJOR_VERSION="1"
LIBAEC_MINOR_VERSION="0.6"

VERSION=${MAJOR_VERSION}.${MINOR_VERSION_0}.${MINOR_VERSION_1}
TAR_VERSION_STRING=${MAJOR_VERSION}_${MINOR_VERSION_0}_${MINOR_VERSION_1}
ZLIB_VERSION=${ZLIB_MAJOR_VERSION}.${ZLIB_MINOR_VERSION}
LIBAEC_VERSION=${LIBAEC_MAJOR_VERSION}.${LIBAEC_MINOR_VERSION}

cd ${BUILD_DIR}

rm -fr ${NAME}${EPOCH}-${NAME}${EPOCH}-${TAR_VERSION_STRING}
tar xvf ${NAME}${EPOCH}-${TAR_VERSION_STRING}.tar.gz
cd ${NAME}${EPOCH}-${NAME}${EPOCH}-${TAR_VERSION_STRING}

# NVIDIA HPC SDK / Open MPI
COMPILER="nvidia"
MPI="openmpi"

internal_COMPILER_C_FLAGS="-tp=zen2 -Mcache_align -fast -Mvect -mavx2 -fPIC ${CFLAGS}"
internal_COMPILER_CXX_FLAGS="-tp=zen2 -Mcache_align -fast -Mvect -mavx2 -fPIC ${CXXFLAGS}"
internal_COMPILER_Fortran_FLAGS="-tp=zen2 -Mcache_align -fast -Mvect -mavx2 -fPIC ${FCFLAGS}"

module purge
module load cmake/latest
module load ${MPI}/4/${COMPILER}/latest
module load curl/7/latest-${COMPILER}

cmake -B build-${COMPILER} \
      -DCMAKE_C_COMPILER=mpicc \
      -DCMAKE_CXX_COMPILER=mpicxx \
      -DCMAKE_Fortran_COMPILER=mpifort \
      -DCMAKE_VERBOSE_MAKEFILE=OFF \
      -DBUILD_TESTING=OFF \
      -DCMAKE_C_FLAGS="${internal_COMPILER_C_FLAGS}" \
      -DCMAKE_CXX_FLAGS="${internal_COMPILER_CXX_FLAGS}" \
      -DCMAKE_Fortran_FLAGS="${internal_COMPILER_Fortran_FLAGS}" \
      -DHDF5_ENABLE_PARALLEL=ON \
      -DLARGE_PARALLEL_IO=ON \
      -DHDF5_BUILD_FORTRAN=ON \
      -DHDF5_ENABLE_SZIP_SUPPORT=ON \
      -DHDF5_ENABLE_SZIP_ENCODING=ON \
      -DUSE_LIBAEC=ON \
      -Dlibaec_LIBRARY=${BUILD_DIR}/bundle/wrf-4.4/lib64/libsz.a \
      -Dlibaec_INCLUDE_DIR=${BUILD_DIR}/bundle/wrf-4.4/include \
      -DHDF5_ENABLE_Z_LIB_SUPPORT=ON \
      -DZLIB_INCLUDE_DIR=${BUILD_DIR}/bundle/wrf-4.4/include \
      -DZLIB_LIBRARY_RELEASE=${BUILD_DIR}/bundle/wrf-4.4/lib/libz.a \
      -DSZIP_LIBRARY=${BUILD_DIR}/bundle/wrf-4.4/lib64/libsz.a \
      -DSZIP_INCLUDE_DIR=${BUILD_DIR}/bundle/wrf-4.4/include \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${BUILD_DIR}/bundle/wrf-4.4/

cmake --build build-${COMPILER} -j 12
cmake --install build-${COMPILER}

cd ${BUILD_DIR}/bundle/wrf-4.4/lib
ln -s libhdf5_hl.so libhdf5_hl-shared.so
ln -s libhdf5.so libhdf5-shared.so

cd ${BUILD_DIR}
rm -fr ${NAME}${EPOCH}-${NAME}${EPOCH}-${TAR_VERSION_STRING}

