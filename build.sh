#!/bin/sh
set -e

# 当前工作目录。拼接绝对路径的时候需要用到这个值。
WORKDIR=$(pwd)

# 如果存在旧的目录和文件，就清理掉
rm -rf *.tar.gz \
    ohos-sdk \
    make-4.4.1 \
    make-4.4.1-ohos-arm64

# 准备 ohos-sdk
mkdir ohos-sdk
curl -L -O https://repo.huaweicloud.com/openharmony/os/6.0-Release/ohos-sdk-windows_linux-public.tar.gz
tar -zxf ohos-sdk-windows_linux-public.tar.gz -C ohos-sdk
cd ohos-sdk/linux
unzip -q native-*.zip
cd ../..

# 设置交叉编译所需的环境变量
export OHOS_SDK=${WORKDIR}/ohos-sdk/linux
export AS=${OHOS_SDK}/native/llvm/bin/llvm-as
export CC="${OHOS_SDK}/native/llvm/bin/clang --target=aarch64-linux-ohos"
export CXX="${OHOS_SDK}/native/llvm/bin/clang++ --target=aarch64-linux-ohos"
export LD=${OHOS_SDK}/native/llvm/bin/ld.lld
export STRIP=${OHOS_SDK}/native/llvm/bin/llvm-strip
export RANLIB=${OHOS_SDK}/native/llvm/bin/llvm-ranlib
export OBJDUMP=${OHOS_SDK}/native/llvm/bin/llvm-objdump
export OBJCOPY=${OHOS_SDK}/native/llvm/bin/llvm-objcopy
export NM=${OHOS_SDK}/native/llvm/bin/llvm-nm
export AR=${OHOS_SDK}/native/llvm/bin/llvm-ar
export CFLAGS="-D__MUSL__=1"
export CXXFLAGS="-D__MUSL__=1"

# 编译 make
curl -L -O https://mirrors.ustc.edu.cn/gnu/make/make-4.4.1.tar.gz
tar -zxf make-4.4.1.tar.gz
cd make-4.4.1
./configure --prefix=${WORKDIR}/make-4.4.1-ohos-arm64 --host=aarch64-linux
make -j$(nproc)
make install
cd ..

# 履行开源义务，将 license 随制品一起发布
cp make-4.4.1/COPYING make-4.4.1-ohos-arm64/

# 打包最终产物
tar -zcf make-4.4.1-ohos-arm64.tar.gz make-4.4.1-ohos-arm64
