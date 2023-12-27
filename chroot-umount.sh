#!/bin/bash

set -e

sudo umount $LFS/proc
sudo umount $LFS/dev/pts
sudo umount $LFS/dev/shm
sudo umount $LFS/dev
sudo umount $LFS/sys
sudo umount $LFS/run
sudo umount $LFS
