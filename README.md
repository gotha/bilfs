# BILFS

## Check prerequisites

```sh
./check-versions.sh
```

## Prepare disk image and folders

set environment variables:

```sh
export LC_ALL=POSIX
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export CONFIG_SITE=$LFS/usr/share/config.site
export PATH=$LFS/tools/bin:$PATH
export NPROC=$(nproc)
export MAKEFLAGS="-j$NPROC"
umask 022
```


`prepare.sh` is going to download packages from`./wget-list-sysv` and store them in `./sources` folder to be re-used in later executions. 
Delete the folder if you change the list of packages.

```sh
LFS_DISK_IMAGE=/mnt/storage/lfs-20231227.img ./prepare.sh
LFS_DISK_IMAGE=/mnt/storage/lfs-20231227-2.img ./prepare.sh
```

## Install tools from host

```sh
./install.sh
```

and verify that it's working:

```sh
echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
rm -v a.out #cleanup
```

it if all looks good, execute the second step:

```sh
./install2.sh
```

## Install tools in chroot

Copy config files:

```sh
cp ./etc/* $LFS/etc/
```

Set permissions and mount directories to host

```sh
sudo chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools,lib64}

sudo mkdir -pv $LFS/{dev,proc,sys,run,tmp}

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
```


Copy install scripts in the new fs:

```sh
mkdir $LFS/opt
cp install3.sh $LFS/opt
cp install4.sh $LFS/opt
```


Enter chroot:

```sh
sudo chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j${NPROC}" \
    /bin/bash --login
```

run install script 3:

```sh
/opt/install3.sh
```

and when successful run install 4

```sh
/opt/install4.sh
```

## Cleanup

exit the chroot and umount

```sh
sudo umount $LFS/proc
sudo umount $LFS/dev/pts
sudo umount $LFS/dev/shm
sudo umount $LFS/dev
sudo umount $LFS/sys
sudo umount $LFS/run
sudo umount $LFS
```


