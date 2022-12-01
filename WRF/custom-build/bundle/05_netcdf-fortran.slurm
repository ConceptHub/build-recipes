#!/bin/bash
#
#SBATCH --partition=cn            # Partition
#SBATCH --job-name=compile_netcdf-fortran  # Job Name
#SBATCH --time=00:10:00           # WallTime

#SBATCH --nodes           1       # No need to allocate more than 1 node
#SBATCH --ntasks-per-node 12      # CMake will need maximum of 12 parallel
                                  # processes
#SBATCH --cpus-per-task   1       # No multithreading is requested

#SBATCH -o netcdf-fortran.%j.out            # STDOUT
#SBATCH -e netcdf-fortran.%j.err            # STDERR

NAME="netcdf-fortran"
MAJOR_VERSION="4"
MINOR_VERSION="6.0"
BUILD_DIR=/discofs/`whoami`/wrf-4.4

VERSION=${MAJOR_VERSION}.${MINOR_VERSION}

cd ${BUILD_DIR}

export LANG=C
export LC_ALL=C

cd ${BUILD_DIR}
rm -fr ${NAME}-${VERSION}
tar xvf ${NAME}-${VERSION}.tar.gz || exit
cd ${NAME}-${VERSION}

# NVIDIA HPC SDK / Open MPI
COMPILER="nvidia"
MPI="openmpi"

CFLAGS="-I${BUILD_DIR}/bundle/wrf-4.4/include ${CFLAGS}"
FCFLAGS="-I${BUILD_DIR}/bundle/wrf-4.4/include/ ${FCFLAGS}"

internal_COMPILER_C_FLAGS="-tp=zen2 -Mcache_align -fast -Mvect -mavx2 -fPIC ${CFLAGS}"
internal_COMPILER_Fortran_FLAGS="-tp=zen2 -Mcache_align -fast -Mvect -mavx2 -fPIC ${FCFLAGS}"

export LDFLAGS="-L${BUILD_DIR}/bundle/wrf-4.4/lib -L${BUILD_DIR}/bundle/wrf-4.4/lib64 ${LDFLAGS}"

module purge
module load cmake/latest
module load ${MPI}/4/${COMPILER}/latest

cmake -B build-${COMPILER} \
      -DCMAKE_C_COMPILER=mpicc \
      -DCMAKE_Fortran_COMPILER=mpifort \
      -DCMAKE_VERBOSE_MAKEFILE=OFF \
      -DBUILD_TESTING=OFF \
      -DCMAKE_C_FLAGS="${internal_COMPILER_C_FLAGS}" \
      -DCMAKE_Fortran_FLAGS="${internal_COMPILER_Fortran_FLAGS}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_EXE_LINKER_FLAGS="-L${BUILD_DIR}/bundle/wrf-4.4/lib -L${BUILD_DIR}/bundle/wrf-4.4/lib64 ${LDFLAGS}" \
      -DCMAKE_INSTALL_PREFIX=${BUILD_DIR}/bundle/wrf-4.4/

cmake --build build-${COMPILER} -j 12
cmake --install build-${COMPILER}

cd ${BUILD_DIR}
rm -fr ${NAME}-${VERSION}

