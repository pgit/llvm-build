# -------------------------------------------------------------------------------------------------
#
# TEST: build LLVM on CentOS 7 (to force GLIBC 2.17 compatibility)
#
# -------------------------------------------------------------------------------------------------

FROM fedora:34 as centos-updated

RUN dnf update -y && dnf clean all

# -------------------------------------------------------------------------------------------------

FROM centos-updated AS builder

RUN dnf update -y && \
    dnf install -y sudo unzip git && \
    dnf groupinstall -y "C Development Tools and Libraries" && \
    dnf install -y boost-devel double-conversion-devel gflags-devel glog-devel krb5-devel cyrus-sasl-devel zlib-devel libsodium-devel libevent-devel snappy-devel openssl-devel gperf lzma-sdk-devel && \
    dnf install -y libdwarf-devel libunwind-devel liburing-devel libaio-devel && \
    dnf install -y python3 && \
    dnf clean all
    
# Download, verify and install cmake version that can compile clang into /usr/local.
# (Version in debian8 repos is is too old)
COPY cmake-3.20.1-linux-x86_64.tar.gz cmake-3.20.1-linux-x86_64.tar.gz
RUN tar xzf cmake-3.20.1-linux-x86_64.tar.gz -C /usr/local --strip-components=1

RUN git clone https://github.com/facebook/proxygen.git

#RUN cd proxygen/proxygen && \
#    ./build.sh && \
#    ./install.sh

#
# docker build -t clang-centos8:builder -f centos8/Dockerfile --target builder centos8
# docker run --rm -it -v "$PWD":/out clang-centos8:builder tar -C /tmp/clang-install --transform 's|^|clangd-custom/|' -czf /out/clangd-12-centos8.tar.gz bin/clangd bin/clangd-indexer lib/clang
#
# -------------------------------------------------------------------------------------------------

# Stage 2. Produce a minimal release image with build results.
FROM centos-updated
# Copy build results of stage 1 to /usr/local.
COPY --from=builder /tmp/clang-install/ /usr/local/
