#!/bin/sh
set -e

# 当前工作目录。拼接绝对路径的时候需要用到这个值。
WORKDIR=$(pwd)

# 如果存在旧的目录和文件，就清理掉
rm -rf *.tar.gz \
    ohos-sdk \
    daily_build.log \
    manifest_tag.xml \
    make-4.4.1 \
    make-4.4.1-ohos-arm64

# 准备 ohos-sdk
curl -fL -o ohos-sdk-full_6.1-Release.tar.gz https://cidownload.openharmony.cn/version/Master_Version/OpenHarmony_6.1.0.31/20260311_020435/version-Master_Version-OpenHarmony_6.1.0.31-20260311_020435-ohos-sdk-full_6.1-Release.tar.gz
tar -zxf ohos-sdk-full_6.1-Release.tar.gz
cd ohos-sdk/linux
unzip -q native-*.zip
unzip -q toolchains-*.zip
cd ../..

# 设置交叉编译所需的环境变量
LLVM_BIN=$WORKDIR/ohos-sdk/linux/native/llvm/bin
export CC=$LLVM_BIN/aarch64-unknown-linux-ohos-clang
export CXX=$LLVM_BIN/aarch64-unknown-linux-ohos-clang++
export LD=$LLVM_BIN/ld.lld
export AR=$LLVM_BIN/llvm-ar
export AS=$LLVM_BIN/llvm-as
export NM=$LLVM_BIN/llvm-nm
export OBJCOPY=$LLVM_BIN/llvm-objcopy
export OBJDUMP=$LLVM_BIN/llvm-objdump
export RANLIB=$LLVM_BIN/llvm-ranlib
export STRIP=$LLVM_BIN/llvm-strip

# 编译 make
curl -fLO https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz
tar -zxf make-4.4.1.tar.gz
cd make-4.4.1
./configure --prefix=$WORKDIR/make-4.4.1-ohos-arm64 --host=aarch64-linux
sed -i '/#define MAKE_CXX/c #define MAKE_CXX "c++"' src/config.h
make -j$(nproc)
make install
cd ..

# 进行代码签名
cd $WORKDIR/make-4.4.1-ohos-arm64
find . -type f \( -perm -0111 -o -name "*.so*" \) | while read FILE; do
    if file -b "$FILE" | grep -iqE "elf|sharedlib|ELF|shared object"; then
        echo "Signing binary file $FILE"
        ORIG_PERM=$(stat -c %a "$FILE")
        $WORKDIR/ohos-sdk/linux/toolchains/lib/binary-sign-tool sign -inFile "$FILE" -outFile "$FILE" -selfSign 1
        chmod "$ORIG_PERM" "$FILE"
    fi
done
cd $WORKDIR

# 履行开源义务，将 license 随制品一起发布
cp make-4.4.1/COPYING make-4.4.1-ohos-arm64/

# 打包最终产物
tar -zcf make-4.4.1-ohos-arm64.tar.gz make-4.4.1-ohos-arm64
