# -------------------------------------------------------------------------------------------------
#
# build LLVM clangd on CentOS 7 (to force GLIBC 2.17 compatibility)
#
# -------------------------------------------------------------------------------------------------

FROM centos:7 as centos-updated

RUN yum update -y && yum clean all

# -------------------------------------------------------------------------------------------------

FROM centos-updated AS builder

RUN yum update -y && \
    yum install -y sudo git wget unzip subversion zlib-devel libxml2-devel && \
    yum install -y centos-release-scl && \
    yum install -y devtoolset-7-gcc* && \
    yum install -y rh-python36 && \
    yum clean all

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
    git clone https://github.com/llvm/llvm-project.git --no-checkout --depth 1 --branch release/12.x . && \
    echo llvm >>.git/info/spare-checkout && \
    echo clang >>.git/info/spare-checkout && \
    echo clang-tools-extra >>.git/info/spare-checkout && \
    git checkout && \
    rm -rf .git

#
# Finally, build selected LLVM projects
#
RUN source scl_source enable devtoolset-7 && \
    source scl_source enable rh-python36 && \
    export CXX="/opt/rh/devtoolset-7/root/usr/bin/g++" && \
    export CC="/opt/rh/devtoolset-7/root/usr/bin/gcc" && \
    mkdir -p /tmp/clang-install && \
    mkdir -p /tmp/clang-build/build && \
    cd /tmp/clang-build/build && \
    cmake -GNinja \
      -DLLVM_TARGETS_TO_BUILD=Native \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/tmp/clang-install \
      -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
      /tmp/clang-build/src/llvm && \
    ninja install

#
# Patch clangd so that it looks for a file called ".compile_commands.json" (with a '.' in front) as well.
#
RUN cd /tmp/clang-build/src && \
    sed -i clang-tools-extra/clangd/GlobalCompilationDatabase.cpp -e 's/^\(.*\)Build\(CompileCommandsJson.*\)$/&\n\1Dot\2/' && \
    sed -i clang-tools-extra/clangd/GlobalCompilationDatabase.cpp -e 's/\(DotCompileCommands.*\)"build\//\1"./' && \
    cd /tmp/clang-build/build && \
    ninja install

RUN cp -a /tmp/clang-build/build/bin/clangd-indexer /tmp/clang-install/bin

#
# docker build -t clang-centos7:builder -f centos7/Dockerfile --target builder centos7
# docker run --rm -it -v "$PWD":/out clang-centos7:builder tar -C /tmp/clang-install --transform 's|^|clangd-custom/|' -czf /out/clangd-12-centos7.tar.gz bin/clangd bin/clangd-indexer lib/clang
#
# -------------------------------------------------------------------------------------------------

# Stage 2. Produce a minimal release image with build results, omitting the bulding layers:
FROM centos-updated
# Copy build results of stage 1 to /usr/local.
COPY --from=builder /tmp/clang-install/ /usr/local/
