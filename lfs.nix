with (import <nixpkgs> {});
mkShell {
  buildInputs = [
    coreutils
    bash
    binutils
    bison
    diffutils
    e2fsprogs
    findutils
    gawk
    gcc
    gzip
    m4
    patch
    perl
    python3
    sudo
    texinfo
    util-linux
    xz
  ];
  shellHook = ''
    if [ -f /run/wrappers/bin/sudo ]; then
      # needed for nix-shell --pure
      alias sudo=/run/wrappers/bin/sudo 
    fi
    export LC_ALL=POSIX
    export LFS=/mnt/lfs
    export LFS_TGT=$(uname -m)-lfs-linux-gnu
    export CONFIG_SITE=$LFS/usr/share/config.site
    export PATH=$LFS/tools/bin:$PATH
    export NPROC=$(nproc)
    export MAKEFLAGS="-j$NPROC"
    umask 022

    echo "Hello buddy"
  '';
}
