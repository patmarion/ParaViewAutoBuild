#!/bin/bash

paraview_source_dir=$1
paraview_install_dir=$2
osmesa_install_dir=$3
python_install_dir=$4
cmake_command=$5
toolchain_file=$6
native_build_dir=$7
cache_file=$8


$cmake_command \
-DCMAKE_TOOLCHAIN_FILE=$toolchain_file \
-DParaView3CompileTools_DIR=$native_build_dir \
-DPYTHON_INCLUDE_DIR="$python_install_dir/include/python2.5" \
-DPYTHON_LIBRARY="$python_install_dir/lib/libpython2.5.a" \
-DOPENGL_INCLUDE_DIR="$osmesa_install_dir/include" \
-DOPENGL_gl_LIBRARY="" \
-DOPENGL_glu_LIBRARY="$osmesa_install_dir/lib/libGLU.a" \
-DVTK_OPENGL_HAS_OSMESA=1 \
-DOSMESA_LIBRARY="$osmesa_install_dir/lib/libOSMesa.a" \
-DOSMESA_INCLUDE_DIR="$osmesa_install_dir/include" \
-DCMAKE_INSTALL_PREFIX:PATH="$paraview_install_dir" \
-C $cache_file \
-C $paraview_source_dir/CMake/TryRunResults-ParaView3-bgl-xlc.cmake \
$paraview_source_dir
