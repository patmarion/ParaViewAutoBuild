base=/gpfs/small/PHASTA/home/PHASmari/source/auto_build
make_command="make -j2"

install_base=$base/install
xinstall_base=$base/install/xlc
git_install_dir=$install_base/git-1.7.1
cmake_install_dir=$install_base/cmake-2.8.1
osmesa_install_dir=$install_base/osmesa-7.0.2
osmesa_xinstall_dir=$xinstall_base/osmesa-7.0.2
python_install_dir=$install_base/python-2.5.2
python_xinstall_dir=$xinstall_base/python-2.5.2
paraview_install_dir=$install_base/paraview
paraview_xinstall_dir=$xinstall_base/paraview

#git_command=$git_install_dir/bin/git
git_command=$base/source/git/git-1.7.1/git
cmake_command=$cmake_install_dir/bin/cmake
toolchain_file=$base/toolchains/toolchain-xlc-bgl.cmake

# Get full path to this script
cd `dirname $0`
script_dir=`pwd`


use_mpi_compilers()
{
export CC=mpicc
export CXX=mpicxx
}

unset_compilers()
{
unset CC
unset CXX
}

do_git()
{
rm -rf $base/source/git
mkdir -p $base/source/git
cd $base/source/git
package=git-1.7.1
#wget http://kernel.org/pub/software/scm/git/$package.tar.gz
cp $script_dir/$package.tar.gz ./
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
package=cmake-2.8.1
#wget http://www.cmake.org/files/v2.8/$package.tar.gz
cp $script_dir/$package.tar.gz ./
tar -zxf $package.tar.gz
mkdir build
cd build
../$package/bootstrap --prefix=$cmake_install_dir
$make_command && make install
}

do_toolchain()
{
rm -rf $base/toolchains
mkdir -p $base/toolchains
cd $base/toolchains
fname=`basename $toolchain_file`
cp $script_dir/toolchains/$fname ./
sed -i -e "s|XINSTALL_DIR|$xinstall_base|g" $toolchain_file 
}

do_python()
{
rm -rf $base/source/python
mkdir -p $base/source/python
cd $base/source/python
package=Python-2.5.2
#wget http://www.python.org/ftp/python/2.5.2/$package.tgz
cp $script_dir/$package.tgz ./
tar -zxf $package.tgz
cp $script_dir/add_cmake_files_to_python2-5-2.patch ./
patch -p1 -d $package < add_cmake_files_to_python2-5-2.patch
mkdir build-bgl-xlc
cd build-bgl-xlc
use_mpi_compilers
$cmake_command \
  -DCMAKE_TOOLCHAIN_FILE=$toolchain_file \
  -DHAVE_GETGROUPS:BOOL=0 \
  -DHAVE_SETGROUPS:BOOL=0 \
  -DENABLE_IPV6:BOOL=0 \
  -DCMAKE_INSTALL_PREFIX=$python_xinstall_dir \
  -C ../$package/CMake/TryRunResults-Python-bgl-gcc.cmake \
  ../$package
#../Python-2.5.2/configure --prefix=$python_install_dir --enable-shared
$make_command && make install
unset_compilers

}

do_python_native()
{
package=Python-2.5.2
cd $base/source/python
mkdir build-native
cd build-native
unset_compilers
#$cmake_command \
#  -DCMAKE_INSTALL_PREFIX=$python_install_dir \
#  ../$package
../$package/configure --prefix=$python_install_dir --enable-shared
$make_command && make install

}

do_osmesa_cross()
{
rm -rf $base/source/mesa
mkdir -p $base/source/mesa
cd $base/source/mesa
package=MesaLib-7.0.4
#wget http://downloads.sourceforge.net/project/mesa3d/MesaLib/7.0.4/MesaLib-7.0.4.tar.gz
cp $script_dir/$package.tar.gz ./
tar -zxf $package.tar.gz

cp -r Mesa-7.0.4 build-xlc
cd build-xlc
sed -i.original -e 's|INSTALL_DIR = /usr/local|INSTALL_DIR = '$osmesa_xinstall_dir'|g' configs/default
use_mpi_compilers
$make_command bluegene-osmesa && make install
unset_compilers
}

do_osmesa_native()
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

do_paraview_download()
{
mkdir -p $base/source/paraview
cd $base/source/paraview
rm -rf ParaView
#$git_command clone git://paraview.org/ParaView.git
$git_command clone home:/source/paraview/ParaView
cd ParaView
$git_command submodule init
$git_command config submodule.VTK.url home:/source/paraview/ParaView/VTK
$git_command config submodule.Xdmf.url home:/source/paraview/ParaView/Utilities/Xdmf2
$git_command config submodule.IceT.url home:/source/paraview/ParaView/Utilities/IceT
$git_command submodule update
}

do_paraview_configure_native()
{
rm -rf $base/source/paraview/build-native
mkdir -p $base/source/paraview/build-native
cd $base/source/paraview/build-native
bash $script_dir/configure_paraview_native.sh ../ParaView $paraview_install_dir $osmesa_install_dir $python_install_dir $cmake_command
}

do_paraview_configure_cross()
{
rm -rf $base/source/paraview/build-bgl-xlc
mkdir -p $base/source/paraview/build-bgl-xlc
cd $base/source/paraview/build-bgl-xlc
bash $script_dir/configure_paraview_bgl_xlc.sh ../ParaView $paraview_xinstall_dir $osmesa_xinstall_dir $python_xinstall_dir $cmake_command $toolchain_file $base/source/paraview/build-native
}


do_paraview_build_native()
{
cd $base/source/paraview/build-native
$make_command && make install
}

do_paraview_build_cross()
{
cd $base/source/paraview/build-bgl-xlc
$make_command && make install
}

do_paraview()
{
do_paraview_download
do_paraview_configure
do_paraview_build
}

do_all()
{
do_git
do_cmake
do_toolchains
do_python
do_osmesa
do_paraview
}

if [ -z $1 ]
then
  set -x
  do_all
else
  set -x
  $1
fi
