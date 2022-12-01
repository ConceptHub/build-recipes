#!/bin/bash
#
#SBATCH --partition=cn            # Partition
#SBATCH --job-name=compile_libaec # Job Name
#SBATCH --time=00:10:00           # WallTime

#SBATCH --nodes           1       # No need to allocate more than 1 node
#SBATCH --ntasks-per-node 12      # CMake will need maximum of 12 parallel
                                  # processes
#SBATCH --cpus-per-task   1       # No multithreading is requested

#SBATCH -o libaec.%j.out           # STDOUT
#SBATCH -e libaec.%j.err           # STDERR

NAME="libaec"
INSTALL_NAME="libaec"
MAJOR_VERSION="1"
MINOR_VERSION="0.6"
BUILD_DIR=/discofs/`whoami`/wrf-4.4

VERSION=${MAJOR_VERSION}.${MINOR_VERSION}

export LANG=C
export LC_ALL=C

cd ${BUILD_DIR}

rm -fr ${NAME}-${VERSION}
mkdir -p ${NAME}-${VERSION}
tar xvf ${NAME}-${VERSION}.tar.gz
#tar xvf ${NAME}-v${VERSION}.tar.bz2 --strip-components=1 -C ${NAME}-${VERSION}
cd ${NAME}-${VERSION}

# NVIDIA HPC SDK
COMPILER="nvidia"

internal_COMPILER_C_FLAGS="-tp=zen2 -Mcache_align -fast -Mvect -mavx2 -fPIC ${CFLAGS}"

module purge
module load cmake/latest
module load nvidia
module load nvhpc-nompi/latest

cmake -B build-${COMPILER} -DCMAKE_C_COMPILER=nvc -DCMAKE_C_FLAGS="${internal_COMPILER_C_FLAGS}" -DCMAKE_INSTALL_PREFIX=${BUILD_DIR}/bundle/wrf-4.4
cmake --build build-${COMPILER} -j 12
cmake --install build-${COMPILER}

cd ${BUILD_DIR}
rm -fr ${BUILD_DIR}/${NAME}-${VERSION}

