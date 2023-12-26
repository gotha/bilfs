#!/bin/bash

if [ -d $LFS ]; then
  sudo umount $LFS
  sudo rm -rf $LFS
fi

dd if=/dev/zero of=lfs.img bs=1M count=50K status=progress
sudo mkfs.ext4 lfs.img

sudo mkdir -p $LFS
sudo mount -t auto lfs.img $LFS
