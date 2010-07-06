#
# BlueGeneP base platform file.
# by Todd Gamblin, tgamblin@llnl.gov
#
# NOTE: Do not set your platform to "BlueGenePBase".  This file is included
# by the real platform files.  Use one of these two platforms instead:
#
#     BlueGeneP          For dynamically linked builds
#     BlueGeneP-static   For statically linked builds
#
# This platform file tries its best to adhere to the behavior of the MPI 
# compiler wrappers included with the latest BG/P drivers.
#


#
# For BGP builds, we're cross compiling, but we don't want to re-root things
# (e.g. with CMAKE_FIND_ROOT_PATH) because users may have libraries anywhere on
# the shared filesystems, and this may lie outside the root.  Instead, we set the
# system directories so that the various system BGP CNK library locations are
# searched first.  This is not the clearest thing in the world, given IBM's driver
# layout, but this should cover all the standard ones.
#
set(CMAKE_SYSTEM_LIBRARY_PATH
  /bgsys/drivers/ppcfloor/comm/default/lib                # default comm layer (used by mpi compiler wrappers)
  /bgsys/drivers/ppcfloor/comm/sys/lib                    # DCMF, other lower-level comm libraries
  /bgsys/drivers/ppcfloor/runtime/SPI                     # other low-level stuff
  /bgsys/drivers/ppcfloor/gnu-linux/lib                   # CNK python installation directory
  /bgsys/drivers/ppcfloor/gnu-linux/powerpc-bgp-linux/lib # CNK Linux image -- standard runtime libs, pthread, etc.
)

#
# Indicate that this is a unix-like system
#
set(UNIX 1)

#
# Languages we'll set language-specific flags for on this platform.
#
set(BGP_LANGUAGES C CXX Fortran)

#
# Library prefixes, suffixes, extra libs.
#
set(CMAKE_LINK_LIBRARY_SUFFIX "")
set(CMAKE_STATIC_LIBRARY_PREFIX "lib")     # lib
set(CMAKE_STATIC_LIBRARY_SUFFIX ".a")      # .a

set(CMAKE_SHARED_LIBRARY_PREFIX "lib")     # lib
set(CMAKE_SHARED_LIBRARY_SUFFIX ".so")     # .so
set(CMAKE_EXECUTABLE_SUFFIX "")            # .exe
set(CMAKE_DL_LIBS "dl")

#
# This macro needs to be called for dynamic library support.  Unfortunately on BGP,
# We can't support both static and dynamic links in the same platform file.  The
# dynamic link platform file needs to call this explicitly to set up dynamic linking.
#
macro(set_bgp_shlib_flags)
  foreach(lang ${BGP_LANGUAGES})
    if (CMAKE_${lang}_COMPILER_ID STREQUAL XL)
      # Flags for XL compilers if we explicitly detected XL
      set(CMAKE_SHARED_LIBRARY_${lang}_FLAGS "-qpic")                            # -pic 
      set(CMAKE_SHARED_LIBRARY_CREATE_${lang}_FLAGS "-qmkshrobj -qnostaticlink") # -shared
      set(CMAKE_SHARED_LIBRARY_RUNTIME_${lang}_FLAG "-Wl,-rpath,")               # -rpath
      set(BGP_${lang}_DYNAMIC_EXE_FLAGS "-Wl,-relax -qnostaticlink -qnostaticlink=libgcc")
    else()
      # Assume flags for GNU compilers (if the ID is GNU *or* anything else).
      set(CMAKE_SHARED_LIBRARY_${lang}_FLAGS "-fPIC")               # -pic 
      set(CMAKE_SHARED_LIBRARY_CREATE_${lang}_FLAGS "-shared")      # -shared
      set(CMAKE_SHARED_LIBRARY_RUNTIME_${lang}_FLAG "-Wl,-rpath,")  # -rpath
      set(BGP_${lang}_DYNAMIC_EXE_FLAGS "-Wl,-relax -dynamic")
    endif()
    
    set(CMAKE_SHARED_LIBRARY_LINK_${lang}_FLAGS        "") # +s, flag for exe link to use shared lib
    set(CMAKE_SHARED_LIBRARY_RUNTIME_${lang}_FLAG_SEP ":") # : or empty

    set(BGP_${lang}_DEFAULT_EXE_FLAGS
      "<FLAGS> <CMAKE_${lang}_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET> <LINK_LIBRARIES>")
    set(CMAKE_${lang}_LINK_EXECUTABLE 
      "<CMAKE_${lang}_COMPILER> ${BGP_${lang}_DYNAMIC_EXE_FLAGS} ${BGP_${lang}_DEFAULT_EXE_FLAGS}")
  endforeach()
endmacro()


