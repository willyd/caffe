# - Try to find Glog
#
# The following variables are optionally searched for defaults
#  GLOG_ROOT_DIR:            Base directory where all GLOG components are found
#
# The following are set after configuration is done:
#  GLOG_FOUND
#  GLOG_INCLUDE_DIRS
#  GLOG_LIBRARIES
#  GLOG_LIBRARYRARY_DIRS

include(FindPackageHandleStandardArgs)

set(GLOG_ROOT_DIR "" CACHE PATH "Folder contains Google glog")

if(WIN32)
    set(GLOG_STATIC "" CACHE BOOL "Use glog for static linking.")
    if( GLOG_STATIC )
        add_definitions(
            -DGOOGLE_GLOG_DLL_DECL= 
            )
    endif()
    
    find_path(GLOG_INCLUDE_DIR glog/logging.h
        PATHS ${GLOG_ROOT_DIR}/src/windows ${GLOG_ROOT_DIR}
        PATH_SUFFIXES include)
else()
    find_path(GLOG_INCLUDE_DIR glog/logging.h
        PATHS ${GLOG_ROOT_DIR})
endif()

if(MSVC)
    find_library(GLOG_LIBRARY_RELEASE NAMES libglog_static libglog glog
        PATHS ${GLOG_ROOT_DIR}
        PATH_SUFFIXES lib lib/Release)

    find_library(GLOG_LIBRARY_DEBUG NAMES libglog_static libglog glog
        PATHS ${GLOG_ROOT_DIR}
        PATH_SUFFIXES lib lib/Debug)

    set(GLOG_LIBRARY optimized ${GLOG_LIBRARY_RELEASE} debug ${GLOG_LIBRARY_DEBUG})
else()
    find_library(GLOG_LIBRARY glog
        PATHS ${GLOG_ROOT_DIR}
        PATH_SUFFIXES lib lib64)
endif()

find_package_handle_standard_args(Glog DEFAULT_MSG GLOG_INCLUDE_DIR GLOG_LIBRARY)

if(GLOG_FOUND)
  set(GLOG_INCLUDE_DIRS ${GLOG_INCLUDE_DIR})
  set(GLOG_LIBRARIES ${GLOG_LIBRARY})
  message(STATUS "Found glog    (include: ${GLOG_INCLUDE_DIR}, library: ${GLOG_LIBRARY})")
  mark_as_advanced(GLOG_ROOT_DIR GLOG_LIBRARY_RELEASE GLOG_LIBRARY_DEBUG
                                 GLOG_LIBRARY GLOG_INCLUDE_DIR)
endif()
