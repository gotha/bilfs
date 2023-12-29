# BI Linux From Scratch

notes and some scripts to build [Linux From Scratch 12](https://www.linuxfromscratch.org/lfs/view/12.0/)


## Install prerequisites

To you get started depending on your OS follow one of these guides:
- NixOS (or any other Linux with nix package manager) - [README-nix.md](./README-nix.md)
- OpenSUSE - [README-opensuse.md](./README-opensuse.md)
- RHEL, Fedora, Alma Linux - [README-beret.md](./README-beret.md)

And run this script to verify:

```sh
./check-versions.sh
```

## Prepare disk image and folders

set environment variables (if you are using the nix-shell you don't need to do this):

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


`prepare.sh` is going to download packages from [wget-list-sysv](./wget-list-sysv) and store them in `./sources` folder to be re-used in later executions. 
Delete the folder if you change the list of packages.

Sources are basically [LFS 12 wget-list-sysv](https://www.linuxfromscratch.org/lfs/view/12.0/wget-list-sysv) + `sudo` and `curl`


```sh
# defaults
# LFS_DISK_IMAGE=lfs.img
# LFS_DISK_SIZE_GB=50
LFS_DISK_IMAGE=/mnt/storage/lfs-my-image.img \
    LFS_DISK_SIZE_GB=100 \
    ./prepare.sh
```

## Install tools from host

You can follow [README-manual.md](./README-manual.md) to execute the commands one by one (note that the instructions are less complete and you are going to have to improvise at the end to get it all working)

..or you can run the scripts that automate this process:

```sh
./install.sh
```

and verify the compiler it's working:

```sh
echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
#cleanup
rm -v a.out
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

./chroot-mount.sh
```


Copy install scripts in the new fs:

```sh
mkdir $LFS/opt
cp install3.sh $LFS/opt
cp install4.sh $LFS/opt
```


Enter chroot:

```sh
sudo mkdir -pv $LFS/root
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

## Setup sudo

`sudo` is configured to allow access to all users in the `wheel` group so if you need new user

```sh
mkdir -pv /home/myuser
useradd -d /home/myuser
usermod -a -G wheel myuser
```

## Setup network

if the host is connected to the internet, you should just configure DNS for the chrooted environment

```sh
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

nameserver 8.8.8.8
nameserver 8.8.4.4

# End /etc/resolv.conf
EOF

echo "bilfs" > /etc/hostname
```

## Usage

Root SSL certificates are not installed so if you want to use curl for https links, you would need to run

```sh
echo "--insecure" >> ~/.curlrc
```

to turn off SSL checks


## Cleanup

exit the chroot and umount

```sh
./chroot-umount.sh
```

delete your disk

```sh
rm lfs.img
```

remove sources

```
rm -rf ./sources
```
