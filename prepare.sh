#!/bin/bash

if [ -z "${LFS_DISK_IMAGE}" ]; then
  LFS_DISK_IMAGE="lfs.img"
fi
if [ -z "${LFS_DISK_SIZE_GB}"]; then
  LFS_DISK_SIZE_GB=50
fi


if [ -d $LFS ]; then
  sudo umount $LFS
  sudo rm -rf $LFS
fi

dd if=/dev/zero of=$LFS_DISK_IMAGE bs=1M count="${LFS_DISK_SIZE_GB}K" status=progress
sudo mkfs.ext4 $LFS_DISK_IMAGE

sudo mkdir -p $LFS
sudo mount -t auto $LFS_DISK_IMAGE $LFS

sudo chown -vR $USER $LFS

if [ ! -d ./sources ]; then
  mkdir sources
  wget --input-file=wget-list-sysv --continue --directory-prefix=./sources
fi
cp -r ./sources $LFS

# create directories
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

cd $LFS
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

mkdir -v $LFS/lib64 # only on x86_64

mkdir -pv $LFS/tools

cd $LFS/sources
for f in {*.tar.gz,*.tar.xz,*.tar.bz2}; do
  tar -xf "$f"
done
