# Linux From Scratch 12

##  create disk

sudo dd if=/dev/zero of=/mnt/storage/lfs.img bs=1M count=50K status=progress
sudo mkfs.ext4 /mnt/storage/lfs.img

mkdir /mnt/lfs
sudo mount -t auto /mnt/storage/lfs.img /mnt/lfs

## download sources

wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources

## make dirs

export LFS=/mnt/lfs

mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

mkdir -v $LFS/lib64

mkdir -pv $LFS/tools

## give your own user rights to acess fs

chown -v $USER $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools,lib64}

put at the end of your .zshrc
```
export LC_AL=POSIX
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export CONFIG_SITE=$LFS/usr/share/config.site
export PATH=$LFS/tools/bin:$PATH
export NPROC=$(nproc)
export MAKEFLAGS="-j$NPROC"
umask 022
```

# Chapter 5
## install binutils
/mnt/lfs/sources/binutils-2.41 ❯ tar -xvf binutils-2.41.tar.xz
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

## install gcc

tar -xvf gcc-13.2.0.tar.xz
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
    
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h # this did not work for me; try the command below

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    /mnt/lfs/tools/lib/gcc/x86_64-lfs-linux-gnu/13.2.0/include/limits.h

## 5.4.1 - linux api headers

cd /mnt/lfs/sources
tar -xf linux-6.4.12.tar.xz
cd linux-6.4.12

make mrproper

make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

## 5.5 - glibc

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

### check if all works

echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
rm -v a.out #cleanup

## 5.6 - libstdc++

cd $LFS/sources/gcc-13.2.0
mkdir build_libcpp
cd build_libcpp

../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/13.2.0

make
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la


## 6.2 - M4

tar -xf m4-1.4.19.tar.xz
cf m4-1.4.19

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

## 6.3 - ncurses

tar -xf ncurses-6.4.tar.gz
cd ncurses-6.4

sed -i s/mawk// configure

mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd

./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            --enable-widec

make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so

## 6.4 - bash

tar -xf bash-5.2.15.tar.gz
cd bash-5.2.15

./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc
make
make DESTDIR=$LFS install

ln -sv bash $LFS/bin/sh

## 6.5 - coreutils

tar -xf coreutils-9.3.tar.xz
cd coreutils-9.3

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime \
            gl_cv_macro_MB_CUR_MAX_good=y

make
make DESTDIR=$LFS install

mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

## 6.6 - diffutils

tar -xf diffutils-3.10.tar.xz
cd diffutils-3.10

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install

## 6.7 - file

tar -xf file-5.45.tar.gz
cd file-5.45

mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la

## 6.8 - findutils

tar -xf findutils-4.9.0.tar.xz
cd findutils-4.9.0

./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

## 6.9 - gawk

tar -xf gawk-5.2.2.tar.xz
cd gawk-5.2.2

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

## 6.10 - grep

tar -xf grep-3.11.tar.xz
cd grep-3.11

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make
make DESTDIR=$LFS install

## 6.11 - gzip

tar -xf gzip-1.12.tar.xz
cd gzip-1.12

./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install

## 6.12 - make

tar -xf make-4.4.1.tar.gz
cd make-4.4.1

./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

## 6.13 - patch

tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install


## 6.14 - sed

tar -xf sed-4.9.tar.xz
cd sed-4.9

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make
make DESTDIR=$LFS install

## 6.15 - tar

tar -xf tar-1.35.tar.xz
cd tar-1.35

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$LFS install

## 6.16 - xz

tar -xf xz-5.4.4.tar.xz
cd xz-5.4.4

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.4.4

make
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/liblzma.la

## 6.17 - binutils pt.2

cd $LFS/sources/binutils-2.41

sed '6009s/$add_dir//' -i ltmain.sh

rm -rf build
mkdir build
cd build

../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd

make
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

## 6.18 - GCC - pt.2

cd $LFS/sources/gcc-13.2.0

sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

rm -rf build
mkdir build
cd build

../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++

make
make DESTDIR=$LFS install

ln -sv gcc $LFS/usr/bin/cc

## 7.2 - ownership

sudo chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools,lib64}

## 7.3 - vkfs

sudo mkdir -pv $LFS/{dev,proc,sys,run}

sudo mount -v --bind /dev $LFS/dev

sudo mount -v --bind /dev/pts $LFS/dev/pts
sudo mount -vt proc proc $LFS/proc
sudo mount -vt sysfs sysfs $LFS/sys
sudo mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  sudo mkdir -pv $LFS/$(readlink $LFS/dev/shm)
else
  sudo mount -t tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

## 7.4 - chroot

sudo chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login

## 7.5 - dirs 

mkdir -pv /{boot,home,mnt,opt,srv}

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
