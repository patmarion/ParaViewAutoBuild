
#platform=bgl
#platform=bgp
#platform=eureka
#platform=jaguarpf
platform=jaguarpfgcc

set_bgl_options()
{
  base=$HOME/source/autobuild2
  toolchain_file=toolchain-xlc-bgl.cmake
  make_command="make -j2"
  paraview_cross_cxx_flags="-O2 -qstrict -qarch=440 -qtune=440 -qcpluscmt"
  osmesa_config_name=bgl-osmesa-xlc
}



set_bgp_options()
{
  base=/scratch/pmarion/build-bgp
  toolchain_file=BlueGeneP-xl-static.cmake
  make_command="make -j2"
  paraview_cross_cxx_flags="-O2 -qstrict -qarch=450d -qtune=450 -qcpluscmt"
  osmesa_config_name=bgp-osmesa-xlc
}


set_eureka_options()
{
  base=/scratch/pmarion/test_build
  make_command="make -j2"
}

set_jaguarpf_options()
{
  base=/ccs/proj/tur013/marionp
  toolchain_file=cray-cnl-pgi-toolchain.cmake
  make_command="make -j2"
  paraview_cross_cxx_flags="-O2"
  osmesa_config_name=craycle-osmesa-pgi
}

set_jaguarpfgcc_options()
{
  base=/ccs/proj/tur013/marionp/gccbuild
  toolchain_file=cray-cnl-gnu-toolchain.cmake
  make_command="make -j2"
  paraview_cross_cxx_flags="-O2"
  osmesa_config_name=craycle-osmesa-gnu
}


set_${platform}_options

