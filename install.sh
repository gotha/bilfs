#!/bin/bash
# A script to install stuff on $LFS

set -e

sudo chown -vR $USER $LFS
#mkdir -p $LFS/sources
cp -r ./sources $LFS

# create directories
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

cd $LFS
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

mkdir -v $LFS/lib64 # only on x86_64

mkdir -pv $LFS/tools


echo " >>> Install binutils"
cd $LFS/sources
tar -xf binutils-2.41.tar.xz
cd ./binutils-2.41
mkdir build 
cd build

../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror

make
make install

echo " >>> install GCC"
cd $LFS/sources
tar -xf gcc-13.2.0.tar.xz
cd gcc-13.2.0

tar -xf ../mpfr-4.2.0.tar.xz
mv -v mpfr-4.2.0 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64

mkdir -v build
cd       build

../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.38 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++

make
make install

cd ..

GCC_DIR=$(dirname $($LFS_TGT-gcc -print-libgcc-file-name))
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > "$GCC_DIR/include/limits.h"

echo " >>> Linux headers"

cd $LFS/sources
tar -xf linux-6.4.12.tar.xz
cd linux-6.4.12

make mrproper

make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr


echo " >>> GlibC"

cd $LFS/sources
tar -xf glibc-2.38.tar.xz
cd glibc-2.38

ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3

patch -Np1 -i ../glibc-2.38-fhs-1.patch

mkdir -v build
cd build
echo "rootsbindir=/usr/sbin" > configparms

../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=4.14               \
      --with-headers=$LFS/usr/include    \
      libc_cv_slibdir=/usr/lib

make
make DESTDIR=$LFS install
