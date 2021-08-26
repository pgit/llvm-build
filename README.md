# llvm-build

Dockerfiles for building llvm `clangd` binaries for centos7 and centos8. I'm using it with the [clangd plugin](https://marketplace.visualstudio.com/items?itemName=llvm-vs-code-extensions.vscode-clangd) for [Visual Studio Code](https://code.visualstudio.com/).

Also includes Dockerfiles for building [Proxygen](https://github.com/facebook/proxygen) and [SVN](https://subversion.apache.org/).

This is mostly a playground only for getting Dockerfiles right. LLVM Version is 12.x and currently hardcoded, but can easily changed.

## Synopsis

```bash
docker build -t clang-centos7:builder -f centos7/Dockerfile --target builder centos7
docker run --rm -it -v "$PWD":/out clang-centos7:builder \
    tar -C /tmp/clang-install --transform 's|^|clangd-custom/|' \
    -czf /out/clangd-12-centos7.tar.gz \
    bin/clangd bin/clangd-indexer lib/clang
```
