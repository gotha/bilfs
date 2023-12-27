#!/bin/bash

set -e

ln -sv /proc/self/mounts /etc/mtab

install -o tester -d /home/tester

mkdir -pv /var/log
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

cd /sources/gettext-0.22
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd /sources/bison-3.8.2
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make 
make install

cd /sources/perl-5.38.0
sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Duseshrplib                                \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl     \
             -Darchlib=/usr/lib/perl5/5.38/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl
make 
make install

cd /sources/Python-3.11.4
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
make
make install


cd /sources/texinfo-7.0.3
./configure --prefix=/usr
make
make install


cd /sources/util-linux-2.39.1
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
            --libdir=/usr/lib    \
            --runstatedir=/run   \
            --docdir=/usr/share/doc/util-linux-2.39.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python
make
make install

#echo ">>> Cleanup"
#rm -rf /usr/share/{info,man,doc}/*
#find /usr/{lib,libexec} -name \*.la -delete
#rm -rf /tools
