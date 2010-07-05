#!/bin/bash

BASE=/gpfs/small/PHASTA/shared/ParaView/BGL-Cross-Compile

cmake \
-DCMAKE_TOOLCHAIN_FILE=$BASE/toolchains/toolchain-xlc-bgl.cmake \
-DParaView3CompileTools_DIR=$BASE/source/paraview/build-host-tools-xlc/ \
-DPARAVIEW_USE_MPI=1 \
-DPARAVIEW_ENABLE_PYTHON=1 \
-DPARAVIEW_ENABLE_COPROCESSING=1 \
-DBUILD_COPROCESSING_ADAPTORS=1 \
-DBUILD_FORTRAN_COPROCESSING_ADAPTORS=1 \
-DBUILD_PYTHON_COPROCESSING_ADAPTOR=1 \
-DBUILD_PHASTA_ADAPTOR=1 \
-DPARAVIEW_BUILD_QT_GUI=0 \
-DENABLE_MPI4PY=0 \
-DBUILD_TESTING=0 \
-DOPENGL_gl_LIBRARY="" \
-DCMAKE_CXX_FLAGS="-O3 -qstrict -qarch=440 -qtune=440  -qcpluscmt" \
-C $BASE/source/paraview/ParaView/CMake/TryRunResults-ParaView3-bgl-xlc.cmake \
$BASE/source/paraview/ParaView/

# Optionally turn off some libraries:
#-DVTK_USE_INFOVIS=0 \
#-DVTK_USE_METAIO=0 \
