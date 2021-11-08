# -------------------------------------------------------------------------------------------------
#
# build facebook/proxygen on CentOS 8.4
#
# -------------------------------------------------------------------------------------------------

FROM centos:8.4.2105 as centos-updated

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

RUN dnf install -y doxygen && dnf clean all
RUN dnf install -y fmt-devel gtest-devel gmock-devel && dnf clean all

# -------------------------------------------------------------------------------------------------

COPY fizz-v2021.11.01.00.tar.gz fizz-v2021.11.01.00.tar.gz
COPY folly-v2021.11.01.00.tar.gz folly-v2021.11.01.00.tar.gz
COPY wangle-v2021.11.01.00.tar.gz wangle-v2021.11.01.00.tar.gz
COPY proxygen-v2021.11.01.00.tar.gz proxygen-v2021.11.01.00.tar.gz

COPY build-from-archive.sh build-from-archive.sh
RUN tar xzvf proxygen-v2021.11.01.00.tar.gz && \
    cd proxygen && \
    ../build-from-archive.sh --prefix /tmp/proxygen-install

RUN cd proxygen && \
    cd _build && \
    make test && \
    cd .. && \
    ./install.sh
#
# docker build -t proxygen:builder -f proxygen.centos8/Dockerfile --target builder proxygen.centos8
#
# -------------------------------------------------------------------------------------------------

# Stage 2. Produce a minimal release image with build results.
FROM centos-updated
# Copy build results of stage 1 to /usr/local.
COPY --from=builder /tmp/proxygen-install/ /usr/local/

# Same as above, but without development packages
RUN dnf install -y epel-release && \
    dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled powertools && \
    dnf install -y boost libevent openssl && \
    dnf install -y double-conversion glog gperf && \
    dnf install -y libsodium libunwind libdwarf && \
    dnf install -y libarchive libzstd && \
    dnf install -y fmt gtest gmock
