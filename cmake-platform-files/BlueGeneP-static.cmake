#
# BlueGeneP platform file for dynamic builds.
# by Todd Gamblin, tgamblin@llnl.gov
#
include(Platform/BlueGenePBase)

set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS FALSE)
set(CMAKE_FIND_LIBRARY_PREFIXES "lib")
set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")

set_bgp_static_flags()
