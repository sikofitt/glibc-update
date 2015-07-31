#  glibc-update.sh
#  
#  Copyright 2015 R. Eric Wheeler <eric@rewiv.com>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.  
#  
#!/bin/bash

# Decide where we are installing

if test "z$1" == "z"; then
  PREFIX="/opt";
else
  PREFIX=$1;
fi 

CURRENT_DIR=$(pwd) # Save root directory of script
##
# GCC version to get.
# has to be at least 4.8.x I think.
# CentOS 6.6 ships with 4.4.7
# GCC 5.x isn't really support yet (7/30/2015)
##
GCCV="4.9.3"                      
cgreen=$(tput setaf 2; tput bold) # Just
cnormal=$(tput sgr0)              # some
cwhite=$(tput setaf 7)            # fun

##
# installs dependencies we can get from Centos
##
function yum_installs() {
  echo -e "  ${cgreen}*${cwhite} Installing wget ... ${cnormal}"
  yum -y install wget glibc-devel.i686 glibc-devel.x86_64 || exit 1
  echo -e "  ${cgreen}*${cwhite} Installing Development tools ... ${cnormal}"
  yum -y groupinstall "Development tools"
}
##
# installs updated binutils that
# gcc needs to compile, (as, ld)
##
function install_binutils() {
  cd $CURRENT_DIR
  echo -e "Downloading updated binutils package.\n"
  wget --progress=dot http://ftp.gnu.org/gnu/binutils/binutils-2.25.tar.bz2 || exit 1
  echo -n "  ${cgreen}*${cwhite} Unpacking binutils ... "
  tar -jxvf binutils-2.25.tar.bz2 >/dev/null 2>&1 || exit 1
  echo "done!${cnormal}"
  cd binutils-2.25 || exit 1
  echo -n "  ${cgreen}*${cwhite} Configuring ... "
  ./configure --prefix=/usr >/dev/null 2>&1 || exit 1
  echo "done!${cnormal}"
  echo -n "  ${cgreen}*${cwhite} Making ... "
  make || exit 1
  echo "done!${cnormal}"
  echo -n "  ${cgreen}*${cwhite} Installing ... "
  make install || exit 1
  echo -e " ... done!\n${cnormal}"
  cd $CURRENT_DIR
}
##
# installs dependencies that we can't get from centos
# actually doesn't install them, downloads and moves
# them to the gcc directory where gcc compiles them
##
function install_deps() {
cd $CURRENT_DIR
mkdir tmp
deps=(
  "ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz"
  #MPC="ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.2.tar.gz" # Alternate Version
  #MPC="ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.1.tar.gz" # Alternate Version
  "http://www.mpfr.org/mpfr-current/mpfr-3.1.3.tar.bz2"
  #GMP="https://gmplib.org/download/gmp/gmp-5.1.3.tar.bz2" # Version 5.1.3
  "https://gmplib.org/download/gmp/gmp-6.0.0a.tar.bz2" # Version 6.0.0a Newest as of 7/30/2015
  "ftp://ftp.irisa.fr/pub/mirrors/gcc.gnu.org/gcc/infrastructure/isl-0.11.1.tar.bz2" # Must be this version
  "ftp://ftp.irisa.fr/pub/mirrors/gcc.gnu.org/gcc/infrastructure/cloog-0.18.0.tar.gz"
);
for dep in "${deps[@]}"
  do
     wget --progress=dot "$dep"
  done

for t in $(find . -maxdepth 1 -type f -name "*.tar.*" ! -name binutils-2.25.tar.bz2 ! -name "*gcc*")
  do
    echo -n "  ${cgreen}*${cwhite} Unpacking $t ... "
    tar -xvf "$t" -C tmp >/dev/null 2>&1
    echo "done!${cnormal}"
  done
cd tmp
for dir in $(find . -maxdepth 1 -type d ! -name gcc-4.9.3 ! -name binutils-2.25 ! -name .. ! -name . ! -name tmp);
  do
    strippeddir=$(echo $dir | cut -f1 -d'-' | cut -f2 -d'.')
    echo -n "  ${cgreen}*${cwhite} Moving $dir to gcc-$GCCV$strippeddir ... "
    mv $dir ../gcc-4.9.3$strippeddir
    echo "done!${cnormal}"
  done
}
##
# downloads and unpacks gcc
##
function unpack_gcc() {
  cd $CURRENT_DIR
  GCC="ftp://ftp.gnu.org/gnu/gcc/gcc-$GCCV/gcc-$GCCV.tar.bz2"
  GCCDIR="gcc-$GCCV"
  wget --progress=dot $GCC;
  echo -n "  ${cgreen}*${cwhite} Unpacking GCC ... "
  tar -jxvf gcc-$GCCV.tar.bz2  >/dev/null 2>&1
  echo "done!${cnormal}"
}
##
# builds gcc and installs it
# we need this to compile glibc
# CentOS 6.6 version is to old
##
function build_gcc() {
  cd $CURRENT_DIR/gcc-$GCCV
  ./configure --prefix=$PREFIX --disable-multilib || exit 1
  echo "  ${cgreen}*${cwhite} Making ... ${cnormal}"
  make || exit 1
  echo "  ${cgreen}*${cwhite} Installing ... ${cnormal}"
  make install || exit 1
  echo "${cwhite}done!${cnormal}"  
}
##
# downloads, builds and installs updated
# glibc, now we can run chromedriver
##
function build_glibc() {
  cd $CURRENT_DIR
  wget --progress=dot ftp://ftp.gnu.org/gnu/glibc/glibc-2.21.tar.bz2
  echo -n "  ${cgreen}*${cwhite} Unpacking glibc ... "
  tar -jxvf glibc-2.21.tar.bz2 >/dev/null 2>&1 || exit 1
  echo "done!${cnormal}"
  cd $CURRENT_DIR/glibc-2.21
  ./configure --prefix=/usr
  echo "  ${cgreen}*${cwhite} Making ... "
  make || exit 1
  echo "  ${cgreen}*${cwhite} Installing ... "
  make install || exit 1
  echo "done!${cnormal}"
}
function install_finished() {

}
# run functions
yum_installs || exit 1
install_binutils || exit 1
unpack_gcc || exit 1
install_deps || exit 1
build_gcc || exit 1
build_glibc || exit 1
install_finished;
