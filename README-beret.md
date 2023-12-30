# Preparing environment on RHEL, Fedora Linux, AlmaLinux, etc

Install tools 

```sh
sudo yum install git tmux zsh

sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum install -y neovim 
```

Build tools

```sh
sudo yum install  \
    binutils bison byacc gcc gcc-g++ lbzip2 m4 make patch info tar texi2html texinfo wget
```


Install stow if you use it for managing dotfiles or so

```sh
sudo yum instal cpan

cd /tmp
wget https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz
tar -xf stow-latest.tar.gz
cd $(ls -d */ | grep stow)
./configure
make
sudo make install
```
