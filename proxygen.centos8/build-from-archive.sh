#!/usr/bin/env bash
# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This is a modified version to install from *.tar.gz instead of pulling from git.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

## Run this script to build proxygen and run the tests. If you want to
## install proxygen to use in another C++ project on this machine, run
## the sibling file `reinstall.sh`.

# Obtain the base directory this script resides in.
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Configuration
BUILD_TYPE=MinSizeRel

# Useful constants
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_OFF="\033[0m"

function detect_platform() {
  unameOut="$(uname -s)"
  case "${unameOut}" in
      Linux*)     PLATFORM=Linux;;
      Darwin*)    PLATFORM=Mac;;
      *)          PLATFORM="UNKNOWN:${unameOut}"
  esac
  echo -e "${COLOR_GREEN}Detected platform: $PLATFORM ${COLOR_OFF}"
}

function install_dependencies_linux() {
  sudo apt-get install -yq \
    git \
    cmake \
    m4 \
    g++ \
    flex \
    bison \
    libgflags-dev \
    libgoogle-glog-dev \
    libkrb5-dev \
    libsasl2-dev \
    libnuma-dev \
    pkg-config \
    libssl-dev \
    libcap-dev \
    gperf \
    libevent-dev \
    libtool \
    libboost-all-dev \
    libjemalloc-dev \
    libsnappy-dev \
    wget \
    unzip \
    libiberty-dev \
    liblz4-dev \
    liblzma-dev \
    make \
    zlib1g-dev \
    binutils-dev \
    libsodium-dev \
    libdouble-conversion-dev
}

function install_dependencies_mac() {
  # install the default dependencies from homebrew
  brew install -f            \
    cmake                    \
    m4                       \
    boost                    \
    double-conversion        \
    gflags                   \
    glog                     \
    gperf                    \
    libevent                 \
    lz4                      \
    snappy                   \
    xz                       \
    openssl                  \
    libsodium

  brew link                 \
    cmake                   \
    boost                   \
    double-conversion       \
    gflags                  \
    glog                    \
    gperf                   \
    libevent                \
    lz4                     \
    snappy                  \
    openssl                 \
    xz                      \
    libsodium
}

function install_dependencies() {
  echo -e "${COLOR_GREEN}[ INFO ] install dependencies ${COLOR_OFF}"
  if [ "$PLATFORM" = "Linux" ]; then
    install_dependencies_linux
  elif [ "$PLATFORM" = "Mac" ]; then
    install_dependencies_mac
  else
    echo -e "${COLOR_RED}[ ERROR ] Unknown platform: $PLATFORM ${COLOR_OFF}"
    exit 1
  fi
}

function synch_dependency_to_commit() {
  # Utility function to synch a dependency to a specific commit. Takes two arguments:
  #   - $1: folder of the dependency's git repository
  #   - $2: path to the text file containing the desired commit hash
  if [ "$FETCH_DEPENDENCIES" = false ] ; then
    return
  fi
  DEP_REV=$(sed 's/Subproject commit //' "$2")
  pushd "$1"
  git fetch
  # Disable git warning about detached head when checking out a specific commit.
  git -c advice.detachedHead=false checkout "$DEP_REV"
  popd
}

function setup_folly() {
  FOLLY_DIR=$DEPS_DIR/folly
  FOLLY_BUILD_DIR=$DEPS_DIR/folly/build/

  mkdir -p "$FOLLY_DIR"
  cd "$FOLLY_DIR"
  tar xzvf ../../../../../folly-*.tar.gz

  if [ "$PLATFORM" = "Mac" ]; then
    # Homebrew installs OpenSSL in a non-default location on MacOS >= Mojave
    # 10.14 because MacOS has its own SSL implementation.  If we find the
    # typical Homebrew OpenSSL dir, load OPENSSL_ROOT_DIR so that cmake
    # will find the Homebrew version.
    dir=/usr/local/opt/openssl
    if [ -d $dir ]; then
        export OPENSSL_ROOT_DIR=$dir
    fi
  fi
  echo -e "${COLOR_GREEN}Building Folly ${COLOR_OFF}"
  mkdir -p "$FOLLY_BUILD_DIR"
  cd "$FOLLY_BUILD_DIR" || exit
  MAYBE_DISABLE_JEMALLOC=""
  if [ "$NO_JEMALLOC" == true ] ; then
    MAYBE_DISABLE_JEMALLOC="-DFOLLY_USE_JEMALLOC=0"
  fi

  MAYBE_USE_STATIC_DEPS=""
  MAYBE_USE_STATIC_BOOST=""
  MAYBE_BUILD_SHARED_LIBS=""
  if [ "$BUILD_FOR_FUZZING" == true ] ; then
    MAYBE_USE_STATIC_DEPS="-DUSE_STATIC_DEPS_ON_UNIX=ON"
    MAYBE_USE_STATIC_BOOST="-DBOOST_LINK_STATIC=ON"
    MAYBE_BUILD_SHARED_LIBS="-DBUILD_SHARED_LIBS=OFF"
  fi

  cmake                                           \
    -DCMAKE_PREFIX_PATH="$DEPS_DIR"               \
    -DCMAKE_INSTALL_PREFIX="$DEPS_DIR"            \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE"             \
    -DBUILD_TESTS=OFF                             \
    "$MAYBE_USE_STATIC_DEPS"                      \
    "$MAYBE_USE_STATIC_BOOST"                     \
    "$MAYBE_BUILD_SHARED_LIBS"                    \
    "$MAYBE_OVERRIDE_CXX_FLAGS"                   \
    $MAYBE_DISABLE_JEMALLOC                       \
    ..
  make -j "$JOBS"
  make install
  echo -e "${COLOR_GREEN}Folly is installed ${COLOR_OFF}"
  cd "$BWD" || exit
}

function setup_fizz() {
  FIZZ_DIR=$DEPS_DIR/fizz
  FIZZ_BUILD_DIR=$DEPS_DIR/fizz/build/

  mkdir -p "$FIZZ_DIR"
  cd "$FIZZ_DIR"
  tar xzvf ../../../../../fizz-*.tar.gz

  echo -e "${COLOR_GREEN}Building Fizz ${COLOR_OFF}"
  mkdir -p "$FIZZ_BUILD_DIR"
  cd "$FIZZ_BUILD_DIR" || exit

  MAYBE_USE_STATIC_DEPS=""
  MAYBE_USE_SODIUM_STATIC_LIBS=""
  MAYBE_BUILD_SHARED_LIBS=""
  if [ "$BUILD_FOR_FUZZING" == true ] ; then
    MAYBE_USE_STATIC_DEPS="-DUSE_STATIC_DEPS_ON_UNIX=ON"
    MAYBE_USE_SODIUM_STATIC_LIBS="-Dsodium_USE_STATIC_LIBS=ON"
    MAYBE_BUILD_SHARED_LIBS="-DBUILD_SHARED_LIBS=OFF"
  fi

  cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE"       \
    -DCMAKE_PREFIX_PATH="$DEPS_DIR"             \
    -DCMAKE_INSTALL_PREFIX="$DEPS_DIR"          \
    -DBUILD_TESTS=OFF                           \
    "$MAYBE_USE_STATIC_DEPS"                    \
    "$MAYBE_BUILD_SHARED_LIBS"                  \
    "$MAYBE_OVERRIDE_CXX_FLAGS"                 \
    "$MAYBE_USE_SODIUM_STATIC_LIBS"             \
    "$FIZZ_DIR/fizz"
  make -j "$JOBS"
  make install
  echo -e "${COLOR_GREEN}Fizz is installed ${COLOR_OFF}"
  cd "$BWD" || exit
}

function setup_wangle() {
  WANGLE_DIR=$DEPS_DIR/wangle
  WANGLE_BUILD_DIR=$DEPS_DIR/wangle/build/

  mkdir -p "$WANGLE_DIR"
  cd "$WANGLE_DIR"
  tar xzvf ../../../../../wangle-*.tar.gz

  echo -e "${COLOR_GREEN}Building Wangle ${COLOR_OFF}"
  mkdir -p "$WANGLE_BUILD_DIR"
  cd "$WANGLE_BUILD_DIR" || exit

  MAYBE_USE_STATIC_DEPS=""
  MAYBE_BUILD_SHARED_LIBS=""
  if [ "$BUILD_FOR_FUZZING" == true ] ; then
    MAYBE_USE_STATIC_DEPS="-DUSE_STATIC_DEPS_ON_UNIX=ON"
    MAYBE_BUILD_SHARED_LIBS="-DBUILD_SHARED_LIBS=OFF"
  fi

  cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE"       \
    -DCMAKE_PREFIX_PATH="$DEPS_DIR"             \
    -DCMAKE_INSTALL_PREFIX="$DEPS_DIR"          \
    -DBUILD_TESTS=OFF                           \
    "$MAYBE_USE_STATIC_DEPS"                    \
    "$MAYBE_BUILD_SHARED_LIBS"                  \
    "$MAYBE_OVERRIDE_CXX_FLAGS"                 \
    "$WANGLE_DIR/wangle"
  make -j "$JOBS"
  make install
  echo -e "${COLOR_GREEN}Wangle is installed ${COLOR_OFF}"
  cd "$BWD" || exit
}

function setup_mvfst() {
  MVFST_DIR=$DEPS_DIR/mvfst
  MVFST_BUILD_DIR=$DEPS_DIR/mvfst/build/
  if [ ! -d "$MVFST_DIR" ] ; then
    echo -e "${COLOR_GREEN}[ INFO ] Cloning mvfst repo ${COLOR_OFF}"
    git clone https://github.com/facebookincubator/mvfst "$MVFST_DIR"
  fi
  synch_dependency_to_commit "$MVFST_DIR" "$BASE_DIR"/../build/deps/github_hashes/facebookincubator/mvfst-rev.txt
  echo -e "${COLOR_GREEN}Building Mvfst ${COLOR_OFF}"
  mkdir -p "$MVFST_BUILD_DIR"
  cd "$MVFST_BUILD_DIR" || exit

  MAYBE_USE_STATIC_DEPS=""
  MAYBE_BUILD_SHARED_LIBS=""
  if [ "$BUILD_FOR_FUZZING" == true ] ; then
    MAYBE_USE_STATIC_DEPS="-DUSE_STATIC_DEPS_ON_UNIX=ON"
    MAYBE_BUILD_SHARED_LIBS="-DBUILD_SHARED_LIBS=OFF"
  fi


  cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE"       \
    -DCMAKE_PREFIX_PATH="$DEPS_DIR"             \
    -DCMAKE_INSTALL_PREFIX="$DEPS_DIR"          \
    -DBUILD_TESTS=OFF                           \
    "$MAYBE_USE_STATIC_DEPS"                    \
    "$MAYBE_BUILD_SHARED_LIBS"                  \
    "$MAYBE_OVERRIDE_CXX_FLAGS"                 \
    "$MVFST_DIR"
  make -j "$JOBS"
  make install
  echo -e "${COLOR_GREEN}Mvfst is installed ${COLOR_OFF}"
  cd "$BWD" || exit
}

# Parse args
JOBS=8
WITH_QUIC=false
INSTALL_DEPENDENCIES=true
FETCH_DEPENDENCIES=true
PREFIX=""
COMPILER_FLAGS=""
USAGE="./build.sh [-j num_jobs] [-q|--with-quic] [-m|--no-jemalloc] [--no-install-dependencies] [-p|--prefix] [-x|--compiler-flags] [--no-fetch-dependencies]"
while [ "$1" != "" ]; do
  case $1 in
    -j | --jobs ) shift
                  JOBS=$1
                  ;;
    -q | --with-quic )
                  WITH_QUIC=true
                  ;;
    -m | --no-jemalloc )
                  NO_JEMALLOC=true
                  ;;
    --no-install-dependencies )
                  INSTALL_DEPENDENCIES=false
          ;;
    --no-fetch-dependencies )
                  FETCH_DEPENDENCIES=false
          ;;
    --build-for-fuzzing )
                  BUILD_FOR_FUZZING=true
      ;;
    -t | --no-tests )
                  NO_BUILD_TESTS=true
      ;;
    -p | --prefix )
                  shift
                  PREFIX=$1
      ;;
    -x | --compiler-flags )
                  shift
                  COMPILER_FLAGS=$1
      ;;
    * )           echo $USAGE
                  exit 1
esac
shift
done

detect_platform

if [ "$INSTALL_DEPENDENCIES" == true ] ; then
  install_dependencies
fi

MAYBE_OVERRIDE_CXX_FLAGS=""
if [ -n "$COMPILER_FLAGS" ] ; then
  MAYBE_OVERRIDE_CXX_FLAGS="-DCMAKE_CXX_FLAGS=$COMPILER_FLAGS"
fi

BUILD_DIR=_build
mkdir -p $BUILD_DIR

set -e nounset
trap 'cd $BASE_DIR' EXIT
cd $BUILD_DIR || exit
BWD=$(pwd)
DEPS_DIR=$BWD/deps
mkdir -p "$DEPS_DIR"

# Must execute from the directory containing this script
cd "$(dirname "$0")"

setup_folly
setup_fizz
setup_wangle
MAYBE_BUILD_QUIC=""
if [ "$WITH_QUIC" == true ] ; then
  setup_mvfst
  MAYBE_BUILD_QUIC="-DBUILD_QUIC=On"
fi

MAYBE_BUILD_FUZZERS=""
MAYBE_USE_STATIC_DEPS=""
MAYBE_LIB_FUZZING_ENGINE=""
MAYBE_BUILD_SHARED_LIBS=""
MAYBE_BUILD_TESTS="-DBUILD_TESTS=ON"
if [ "$NO_BUILD_TESTS" == true ] ; then
  MAYBE_BUILD_TESTS="-DBUILD_TESTS=OFF"
fi
if [ "$BUILD_FOR_FUZZING" == true ] ; then
  MAYBE_BUILD_FUZZERS="-DBUILD_FUZZERS=ON"
  MAYBE_USE_STATIC_DEPS="-DUSE_STATIC_DEPS_ON_UNIX=ON"
  MAYBE_LIB_FUZZING_ENGINE="-DLIB_FUZZING_ENGINE='$LIB_FUZZING_ENGINE'"
  MAYBE_BUILD_SHARED_LIBS="-DBUILD_SHARED_LIBS=OFF"
fi

if [ -z "$PREFIX" ]; then
  PREFIX=$BWD
fi

# Build proxygen with cmake
cd "$BWD" || exit
cmake                                     \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE"       \
  -DCMAKE_PREFIX_PATH="$DEPS_DIR"         \
  -DCMAKE_INSTALL_PREFIX="$PREFIX"        \
  "$MAYBE_BUILD_QUIC"                     \
  "$MAYBE_BUILD_TESTS"                    \
  "$MAYBE_BUILD_FUZZERS"                  \
  "$MAYBE_BUILD_SHARED_LIBS"              \
  "$MAYBE_OVERRIDE_CXX_FLAGS"             \
  "$MAYBE_USE_STATIC_DEPS"                \
  "$MAYBE_LIB_FUZZING_ENGINE"             \
  ../..

make -j "$JOBS"
echo -e "${COLOR_GREEN}Proxygen build is complete. To run unit test: \
  cd _build/ && make test ${COLOR_OFF}"
