#!/bin/bash

paraview_source_dir=$1
paraview_install_dir=$2
osmesa_install_dir=$3
python_install_dir=$4
cmake_command=$5
toolchain_file=$6
native_build_dir=$7
cxx_flags=$8

if [ ! -z "$cxx_flags" ]; then
  cxx_flags=-DCMAKE_CXX_FLAGS_RELEASE:STRING=\"$cxx_flags\"
fi


$cmake_command \
-DCMAKE_TOOLCHAIN_FILE=$toolchain_file \
-DParaView3CompileTools_DIR=$native_build_dir \
-DBUILD_SHARED_LIBS=0 \
-DPARAVIEW_USE_MPI=1 \
-DPARAVIEW_ENABLE_PYTHON=1 \
-DPARAVIEW_BUILD_QT_GUI=0 \
-DENABLE_MPI4PY=0 \
-DVTK_USE_X=0 \
-DBUILD_TESTING=0 \
\
-DVTK_USE_SYSTEM_HDF5:BOOL=1 \
-DHDF5_LIBRARIES:FILEPATH=/opt/cray/hdf5-parallel/1.8.5.0/hdf5-parallel-gnu/lib/libhdf5.a \
-DHDF5_LIBRARY:FILEPATH=/opt/cray/hdf5-parallel/1.8.5.0/hdf5-parallel-gnu/lib/libhdf5.a \
-DHDF5_INCLUDE_DIRS:PATH=/opt/cray/hdf5-parallel/1.8.5.0/hdf5-parallel-gnu/include \
-DHDF5_INCLUDE_DIR:PATH=/opt/cray/hdf5-parallel/1.8.5.0/hdf5-parallel-gnu/include \
-DVTK_USE_SYSTEM_ZLIB:BOOL=1 \
-DZLIB_INCLUDE_DIR:PATH=/usr/include \
-DZLIB_LIBRARY:FILEPATH=/usr/lib64/libz.a \
\
-DPYTHON_INCLUDE_DIR="$python_install_dir/include/python2.5" \
-DPYTHON_LIBRARY="$python_install_dir/lib/libpython2.5.a" \
-DOPENGL_INCLUDE_DIR="$osmesa_install_dir/include" \
-DOPENGL_gl_LIBRARY="" \
-DOPENGL_glu_LIBRARY="$osmesa_install_dir/lib/libGLU.a" \
-DVTK_OPENGL_HAS_OSMESA=1 \
-DOSMESA_LIBRARY="$osmesa_install_dir/lib/libOSMesa.a" \
-DOSMESA_INCLUDE_DIR="$osmesa_install_dir/include" \
-DCMAKE_BUILD_TYPE:STRING="Release" \
"$cxx_flags" \
-DCMAKE_INSTALL_PREFIX:PATH="$paraview_install_dir" \
-C $paraview_source_dir/CMake/TryRunResults-ParaView3-bgl-xlc.cmake \
$paraview_source_dir

#-DPARAVIEW_ENABLE_COPROCESSING=1 \
#-DBUILD_COPROCESSING_ADAPTORS=1 \
#-DBUILD_FORTRAN_COPROCESSING_ADAPTORS=1 \
#-DBUILD_PYTHON_COPROCESSING_ADAPTOR=1 \
#-DBUILD_PHASTA_ADAPTOR=1 \
