# -------------------------------------------------------------------------------------------------
#
# build LLVM on CentOS 8
#
# -------------------------------------------------------------------------------------------------

FROM rockylinux:8 as rocky-updated

RUN dnf update -y && dnf clean all

# -------------------------------------------------------------------------------------------------

FROM rocky-updated AS builder

RUN dnf update -y && \
    dnf install -y sudo unzip git subversion zlib-devel libxml2-devel && \
    dnf group install -y "Development Tools" && \
    dnf install -y python3 && \
    dnf clean all

# Install a newer ninja release. It seems the older version in the debian repos
# randomly crashes when compiling llvm.
COPY ninja-linux.zip ninja-linux.zip
RUN unzip ninja-linux.zip -d /usr/local/bin 

# Install cmake version that can compile clang into /usr/local.
# (Version in debian8 repos is is too old)
COPY cmake-3.20.1-linux-x86_64.tar.gz cmake-3.20.1-linux-x86_64.tar.gz
RUN tar xzf cmake-3.20.1-linux-x86_64.tar.gz -C /usr/local --strip-components=1

#
# Checkout the source code.
#
RUN mkdir -p /tmp/clang-build/src && \
    cd /tmp/clang-build/src && \
    git clone https://github.com/llvm/llvm-project.git --no-checkout --depth 1 --branch release/14.x . && \
    echo llvm >>.git/info/spare-checkout && \
    echo clang >>.git/info/spare-checkout && \
    echo clang-tools-extra >>.git/info/spare-checkout && \
    git checkout && \
    git rev-parse HEAD >git-revision && \
    rm -rf .git

# RUN mkdir -p /tmp/clang-build/src && \
#     cd /tmp/clang-build/src && \
#     svn checkout https://github.com/llvm/llvm-project/trunk/llvm && \
#     svn checkout https://github.com/llvm/llvm-project/trunk/clang && \
#     svn checkout https://github.com/llvm/llvm-project/trunk/clang-tools-extra

#
# Finally, build selected LLVM projects
#
# For Debug build, consider shared libs: https://github.com/clangd/clangd/issues/634
#
RUN mkdir -p /tmp/clang-install && \
    mkdir -p /tmp/clang-build/build && \
    cd /tmp/clang-build/build && \
    cmake -GNinja \
      -DLLVM_TARGETS_TO_BUILD=Native \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/tmp/clang-install \
      -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
      /tmp/clang-build/src/llvm && \
    ninja install

RUN cp -a /tmp/clang-build/build/bin/clangd-indexer /tmp/clang-install/bin

#
# docker build -t clang-centos8:builder -f centos8/Dockerfile --target builder centos8
# docker run --rm -it -v "$PWD":/out clang-centos8:builder tar -C /tmp/clang-install --transform 's|^|clangd-custom/|' -czf /out/clangd-12-centos8.tar.gz bin/clangd bin/clangd-indexer bin/llvm-symbolizer lib/clang
#
# -------------------------------------------------------------------------------------------------

# Stage 2. Produce a minimal release image with build results.
FROM centos-updated
# Copy build results of stage 1 to /usr/local.
COPY --from=builder /tmp/clang-install/ /usr/local/
