# -------------------------------------------------------------------------------------------------
#
# TEST: build LLVM on CentOS 7 (to force GLIBC 2.17 compatibility)
#
# -------------------------------------------------------------------------------------------------

FROM centos:8 as centos-updated

RUN dnf update -y && dnf clean all

# -------------------------------------------------------------------------------------------------

FROM centos-updated AS builder

RUN dnf update -y && \
    dnf install -y sudo unzip git subversion zlib-devel libxml2-devel && \
    dnf group install -y "Development Tools" && \
    dnf clean all

RUN dnf install -y epel-release && \
    dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled powertools && \
    dnf install -y glibc-langpack-en && \
    dnf install -y python3 boost-devel libevent-devel openssl-devel && \
    dnf install -y double-conversion-devel glog-devel gperf && \
    dnf install -y libsodium-devel libunwind-devel libdwarf-static && \
    dnf install -y libarchive libzstd-devel cmake && \
    dnf clean all

# Download, verify and install cmake version that can compile clang into /usr/local.
# (Version in debian8 repos is is too old)
# COPY cmake-3.20.1-linux-x86_64.tar.gz cmake-3.20.1-linux-x86_64.tar.gz
# RUN tar xzf cmake-3.20.1-linux-x86_64.tar.gz -C /usr/local --strip-components=1

RUN git clone https://github.com/facebook/proxygen.git

RUN cd proxygen/proxygen && \
    ./build.sh && \    
    ./install.sh

RUN cd proxygen/proxygen && \
    cd _build && \
    make test

#
# docker build -t clang-centos8:builder -f centos8/Dockerfile --target builder centos8
# docker run --rm -it -v "$PWD":/out clang-centos8:builder tar -C /tmp/clang-install --transform 's|^|clangd-custom/|' -czf /out/clangd-12-centos8.tar.gz bin/clangd bin/clangd-indexer lib/clang
#
# -------------------------------------------------------------------------------------------------

# Stage 2. Produce a minimal release image with build results.
FROM centos-updated
# Copy build results of stage 1 to /usr/local.
COPY --from=builder /tmp/clang-install/ /usr/local/
