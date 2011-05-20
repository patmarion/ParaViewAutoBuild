#!/bin/bash


# Get full path to this script
cd `dirname $0`
script_dir=`pwd`


# Get build options
source $script_dir/build_options.sh

if [ -z "$base" ]; then
  echo "build_options.sh did not specify base directory"
  exit 1
fi

if [ -z "$cross_compiler_module" ]; then
  echo "build_options.sh did not specify cross_compiler_module"
  exit 1
fi


install_base=$base/install
xinstall_base=$base/install/cross
git_install_dir=$install_base/git-1.7.3
cmake_install_dir=$install_base/cmake-2.8.4
osmesa_install_dir=$install_base/osmesa-7.6.1
osmesa_xinstall_dir=$xinstall_base/osmesa-7.6.1
python_install_dir=$install_base/python-2.5.2
python_xinstall_dir=$xinstall_base/python-2.5.2
paraview_install_dir=$install_base/paraview
paraview_xinstall_dir=$xinstall_base/paraview

git_command=$git_install_dir/bin/git
cmake_command=$cmake_install_dir/bin/cmake
toolchain_file=$base/toolchains/$toolchain_file

setup_native_compilers()
{
module unload PrgEnv-pgi PrgEnv-gnu Base-opts
module load gcc
}

setup_cross_compilers()
{
module unload gcc
module load Base-opts $cross_compiler_module
}

grab()
{
url=$1
file=$2
cp $script_dir/$file ./
}


do_git()
{
rm -rf $base/source/git
mkdir -p $base/source/git
cd $base/source/git
package=git-1.7.3
grab http://kernel.org/pub/software/scm/git $package.tar.gz
tar -zxf $package.tar.gz
cd $package
./configure --prefix=$git_install_dir
$make_command && make install
}


do_cmake()
{
rm -rf $base/source/cmake
mkdir -p $base/source/cmake
cd $base/source/cmake

package=cmake-2.8.4
grab http://www.cmake.org/files/v2.8 $package.tar.gz
tar -zxf $package.tar.gz

mkdir build
cd build
../$package/bootstrap --prefix=$cmake_install_dir
$make_command && make install

# install extra platform files
cp $script_dir/cmake-platform-files/* $cmake_install_dir/share/cmake-2.8/Modules/Platform/
}


do_cmake_git()
{
rm -rf $base/source/cmake
mkdir -p $base/source/cmake
cd $base/source/cmake

$git_command clone -b next git://cmake.org/cmake.git CMakeNext
mkdir build
cd build
../CMakeNext/bootstrap --prefix=$cmake_install_dir
$make_command && make install

# install extra platform files
cp $script_dir/cmake-platform-files/* $cmake_install_dir/share/cmake-2.8/Modules/Platform/
}


do_toolchains()
{
rm -rf $base/toolchains
mkdir -p $base/toolchains
cd $base/toolchains
fname=`basename $toolchain_file`
cp $script_dir/toolchains/$fname ./
sed -i -e "s|XINSTALL_DIR|$xinstall_base|g" $toolchain_file 
}


do_python_download()
{
mkdir -p $base/source/python
cd $base/source/python
package=Python-2.5.2
grab http://www.python.org/ftp/python/2.5.2 $package.tgz
rm -rf $package
tar -zxf $package.tgz
}

do_python_build_native()
{
cd $base/source/python
source=Python-2.5.2
rm -rf build-native
mkdir build-native
cd build-native
../$source/configure --prefix=$python_install_dir --enable-shared
$make_command && make install
}


do_python_build_cross()
{
cd $base/source/python
source=Python-2.5.2
rm -rf $source-cmakeified
cp -r $source $source-cmakeified
source=$source-cmakeified
cp $script_dir/add_cmake_files_to_python2-5-2.patch ./
patch -p1 -d $source < add_cmake_files_to_python2-5-2.patch

rm -rf build-cross
mkdir build-cross
cd build-cross

# todo - remove PYTHON_BUILD_LIB_SHARED=0
# it is here for bg/p which finds libdl and sets
# build shared default to true, should key off TARGET_SUPPORTS_SHARED_LIBS

$cmake_command \
  -DCMAKE_TOOLCHAIN_FILE=$toolchain_file \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DPYTHON_BUILD_LIB_SHARED:BOOL=0 \
  -DWITH_THREAD:BOOL=0 \
  -DHAVE_GETGROUPS:BOOL=0 \
  -DHAVE_SETGROUPS:BOOL=0 \
  -DENABLE_IPV6:BOOL=0 \
  -DCMAKE_INSTALL_PREFIX=$python_xinstall_dir \
  -C ../$source/CMake/TryRunResults-Python-bgl-gcc.cmake \
  -C $script_dir/python_modules.cmake \
  ../$source

$make_command && make install

}


do_osmesa_download()
{
mkdir -p $base/source/mesa
cd $base/source/mesa
package=MesaLib-7.6.1
grab ftp://ftp.freedesktop.org/pub/mesa/7.6.1 $package.tar.gz

rm -rf Mesa-7.6.1
tar -zxf $package.tar.gz
}

do_osmesa_build_native()
{
cd $base/source/mesa
rm -rf build-native
cp -r Mesa-7.6.1 build-native
cd build-native
cp configs/linux-osmesa configs/linux-osmesa.original
cp $script_dir/linux-osmesa configs/linux-osmesa
sed -i.original -e 's|INSTALL_DIR = /usr/local|INSTALL_DIR = '$osmesa_install_dir'|g' configs/default
$make_command linux-osmesa && make install
}

do_osmesa_build_cross()
{
cd $base/source/mesa
rm -rf build-cross
cp -r Mesa-7.6.1 build-cross
cd build-cross

cp $script_dir/$osmesa_config_name configs/
sed -i.original -e 's|linux-osmesa-static|'$osmesa_config_name'|g' Makefile
sed -i.original -e 's|INSTALL_DIR = /usr/local|INSTALL_DIR = '$osmesa_xinstall_dir'|g' configs/default

$make_command $osmesa_config_name && make install
}

do_paraview_download()
{
mkdir -p $base/source/paraview
cd $base/source/paraview
rm -rf ParaView

package=ParaView-3.10.0-RC1
grab http://paraview.org/files/v3.8 $package.tar.gz
tar -zxf $package.tar.gz
mv $package ParaView

cp $script_dir/TryRunResults-ParaView3.8.1-crayxt-gcc.cmake ParaView/CMake/TryRunResults-ParaView3-bgl-xlc.cmake
}


do_paraview_download_git()
{
mkdir -p $base/source/paraview
cd $base/source/paraview
rm -rf ParaView

paraview_git_url=git://paraview.org/ParaView.git

$git_command clone -o kitware -b release --recursive $paraview_git_url
}


do_paraview_configure_native()
{
rm -rf $base/source/paraview/build-native
mkdir -p $base/source/paraview/build-native
cd $base/source/paraview/build-native
bash $script_dir/configure_paraview_native.sh ../ParaView $paraview_install_dir $osmesa_install_dir $python_install_dir $cmake_command
}


do_paraview_configure_hosttools()
{
rm -rf $base/source/paraview/build-hosttools
mkdir -p $base/source/paraview/build-hosttools
cd $base/source/paraview/build-hosttools
bash $script_dir/configure_paraview_hosttools.sh ../ParaView $paraview_install_dir $osmesa_install_dir $python_install_dir $cmake_command
}

do_paraview_configure_cross()
{
rm -rf $base/source/paraview/build-cross
mkdir -p $base/source/paraview/build-cross
cd $base/source/paraview/build-cross
bash $script_dir/configure_paraview_cross.sh ../ParaView $paraview_xinstall_dir $osmesa_xinstall_dir $python_xinstall_dir $cmake_command $toolchain_file $base/source/paraview/build-hosttools "$paraview_cross_cxx_flags"
}

do_paraview_build_native()
{
cd $base/source/paraview/build-native
$make_command
}

do_paraview_build_hosttools()
{
cd $base/source/paraview/build-hosttools
$make_command pvHostTools
}

do_paraview_build_cross()
{
cd $base/source/paraview/build-cross
$make_command
}


do_paraview_native_prereqs()
{
do_git
do_cmake
#do_cmake_git
do_python_download
do_python_build_native
do_osmesa_download
do_osmesa_build_native
#do_paraview_download
do_paraview_download_git
}

do_native()
{
do_paraview_native_prereqs
do_paraview_configure_native
do_paraview_build_native
}

do_cross()
{
setup_native_compilers
do_paraview_native_prereqs
do_paraview_configure_hosttools
do_paraview_build_hosttools
setup_cross_compilers

do_toolchains
do_python_build_cross
do_osmesa_build_cross
do_paraview_configure_cross
do_paraview_build_cross
}


# this line is needed so that the "module" command will work
source /opt/modules/default/init/bash

if [ -z $1 ]
then
  set -x
  echo "Please specify a build step."
  exit 1
else
  set -x
  $1
fi
