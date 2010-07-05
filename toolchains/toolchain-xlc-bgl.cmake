# the name of the target operating system
SET(CMAKE_SYSTEM_NAME BlueGeneL)

# set the compiler
set(CMAKE_C_COMPILER  /opt/ibmcmp/vac/bg/8.0/bin/blrts_xlc)
set(CMAKE_CXX_COMPILER  /opt/ibmcmp/vacpp/bg/8.0/bin/blrts_xlC)
set(CMAKE_Fortran_COMPILER /opt/ibmcmp/xlf/bg/10.1/bin/blrts_xlf )

# set the search path for the environment coming with the compiler
# and a directory where you can install your own compiled software
set(CMAKE_FIND_ROOT_PATH
    /bgl/BlueLight/ppcfloor/bglsys
    /opt/ibmcmp/vacpp/bg/8.0/blrts_lib
    XINSTALL_DIR
)

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search 
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
