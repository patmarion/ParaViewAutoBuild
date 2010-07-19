base=$HOME/source/auto_build
base=/scratch/pmarion/eureka_autobuild

toolchain_file=BlueGeneP-xl-static.cmake

make_command="make -j2"

install_base=$base/install
xinstall_base=$base/install/xlc
git_install_dir=$install_base/git-1.7.1
cmake_install_dir=$install_base/cmake-2.8.2
osmesa_install_dir=$install_base/osmesa-7.0.2
osmesa_xinstall_dir=$xinstall_base/osmesa-7.0.2
python_install_dir=$install_base/python-2.5.2
python_xinstall_dir=$xinstall_base/python-2.5.2
paraview_install_dir=$install_base/paraview
paraview_xinstall_dir=$xinstall_base/paraview

use_wget=0
broken_git_install=0

#c_cross_compiler=/opt/ibmcmp/vac/bg/8.0/bin/blrts_xlc
#cxx_cross_compiler=/opt/ibmcmp/vacpp/bg/8.0/bin/blrts_xlC

c_cross_compiler=bgxlc
cxx_cross_compiler=bgxlC


if [ $broken_git_install -eq 1 ]; then
    git_command=$base/source/git/git-1.7.1/git
else
    git_command=$git_install_dir/bin/git
fi

cmake_command=$cmake_install_dir/bin/cmake
toolchain_file=$base/toolchains/$toolchain_file


# Get full path to this script
cd `dirname $0`
script_dir=`pwd`


grab()
{
url=$1
file=$2
if [ $use_wget -eq 1 ]; then
    wget $url/$file
else 
    cp $script_dir/$file ./
fi 
}


do_git()
{
rm -rf $base/source/git
mkdir -p $base/source/git
cd $base/source/git
package=git-1.7.1
grab http://kernel.org/pub/software/scm/git $package.tar.gz
tar -zxf $package.tar.gz
cd $package
./configure --prefix=$git_install_dir
$make_command && make install
}


do_cmake_next()
{
rm -rf $base/source/cmake
mkdir -p $base/source/cmake
cd $base/source/cmake

$git_command clone -b next git://cmake.org/cmake.git CMakeNext
mkdir build
cd build
../CMakeNext/bootstrap --prefix=$cmake_install_dir
$make_command && make install

# install extra platform files, this can be removed when they are part of cmake
cp $script_dir/cmake-platform-files/* $cmake_install_dir/share/cmake-2.8/Modules/Platform/
}

do_cmake()
{
rm -rf $base/source/cmake
mkdir -p $base/source/cmake
cd $base/source/cmake

package=cmake-2.8.2
grab http://www.cmake.org/files/v2.8 $package.tar.gz
tar -zxf $package.tar.gz

# Fix FindMPI.cmake for BGL
patch -p1 -d $package -i $script_dir/find_mpi_fix.diff

mkdir build
cd build
../$package/bootstrap --prefix=$cmake_install_dir
$make_command && make install
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
rm -rf $base/source/python
mkdir -p $base/source/python
cd $base/source/python
package=Python-2.5.2
grab http://www.python.org/ftp/python/2.5.2 $package.tgz
tar -zxf $package.tgz
}

do_python_build_native()
{
cd $base/source/python
source=Python-2.5.2
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

rm -rf build-xlc
mkdir build-xlc
cd build-xlc

# todo - remove PYTHON_BUILD_LIB_SHARED=0
# it is here for bg/p which finds libdl and sets
# build shared default to true, should key off TARGET_SUPPORTS_SHARED_LIBS

$cmake_command \
  -DCMAKE_TOOLCHAIN_FILE=$toolchain_file \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DPYTHON_BUILD_LIB_SHARED:BOOL=0 \
  -DHAVE_GETGROUPS:BOOL=0 \
  -DHAVE_SETGROUPS:BOOL=0 \
  -DENABLE_IPV6:BOOL=0 \
  -DCMAKE_INSTALL_PREFIX=$python_xinstall_dir \
  -C ../$source/CMake/TryRunResults-Python-bgl-gcc.cmake \
  ../$source

$make_command && make install

}


do_osmesa_download()
{
rm -rf $base/source/mesa
mkdir -p $base/source/mesa
cd $base/source/mesa
package=MesaLib-7.0.4
grab http://downloads.sourceforge.net/project/mesa3d/MesaLib/7.0.4 $package.tar.gz
tar -zxf $package.tar.gz
}

do_osmesa_build_native()
{
cd $base/source/mesa
rm -rf build-native
cp -r Mesa-7.0.4 build-native
cd build-native
cp configs/linux-osmesa configs/linux-osmesa.original
cp $script_dir/linux-osmesa configs/linux-osmesa
sed -i.original -e 's|INSTALL_DIR = /usr/local|INSTALL_DIR = '$osmesa_install_dir'|g' configs/default
$make_command linux-osmesa && make install
}

do_osmesa_build_cross()
{
cd $base/source/mesa
rm -rf build-xlc
cp -r Mesa-7.0.4 build-xlc
cd build-xlc
sed -i.original -e 's|INSTALL_DIR = /usr/local|INSTALL_DIR = '$osmesa_xinstall_dir'|g' configs/default
sed -i.original -e 's|CC = .*|CC = '$c_cross_compiler'|g' configs/bluegene-xlc-osmesa
sed -i.original -e 's|CXX = .*|CXX = '$cxx_cross_compiler'|g' configs/bluegene-xlc-osmesa
$make_command bluegene-xlc-osmesa && make install
}

do_paraview_download()
{
mkdir -p $base/source/paraview
cd $base/source/paraview
rm -rf ParaView

$git_command clone git://paraview.org/ParaView.git
#$git_command clone home:/source/paraview/ParaView
cd ParaView
$git_command submodule init
#$git_command config submodule.VTK.url home:/source/paraview/ParaView/VTK
#$git_command config submodule.Xdmf.url home:/source/paraview/ParaView/Utilities/Xdmf2
#$git_command config submodule.IceT.url home:/source/paraview/ParaView/Utilities/IceT
$git_command submodule update

#cd VTK/.git/hooks
#$git_command init
#$git_command pull .. remotes/origin/hooks
#cd -

mkdir -p VTK/.git/hooks/.git
touch VTK/.git/hooks/.git/config

mkdir -p .git/hooks/.git
touch .git/hooks/.git/config

# Apply patch to workaround ostream problem
patch_file=paraview-fix-cswrapper.patch
cp $script_dir/$patch_file ./
$git_command apply $patch_file

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
rm -rf $base/source/paraview/build-xlc
mkdir -p $base/source/paraview/build-xlc
cd $base/source/paraview/build-xlc
bash $script_dir/configure_paraview_xlc.sh ../ParaView $paraview_xinstall_dir $osmesa_xinstall_dir $python_xinstall_dir $cmake_command $toolchain_file $base/source/paraview/build-native
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
cd $base/source/paraview/build-xlc
$make_command
}


do_native()
{
do_git
#do_cmake
do_cmake_next
do_python_download
do_python_build_native
do_osmesa_download
do_osmesa_build_native
do_paraview_download
do_paraview_configure_native
do_paraview_build_native
}

do_cross()
{
do_toolchains
do_python_build_cross
do_osmesa_build_cross
do_paraview_configure_hosttools
do_paraview_build_hosttools
do_paraview_configure_cross
do_paraview_build_cross
}

do_all()
{
do_native
do_cross
}


if [ -z $1 ]
then
  set -x
  do_all
else
  set -x
  $1
fi
