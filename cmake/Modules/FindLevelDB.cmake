# - Find LevelDB
#
#  LevelDB_INCLUDES  - List of LevelDB includes
#  LevelDB_LIBRARIES - List of libraries when using LevelDB.
#  LevelDB_FOUND     - True if LevelDB found.

# Look for the header file.

find_path(LevelDB_INCLUDE NAMES leveldb/db.h
                          PATHS $ENV{LEVELDB_ROOT}/include /opt/local/include /usr/local/include /usr/include
                          DOC "Path in which the file leveldb/db.h is located." )

if(MSVC)
  # when using vcpkg the libraries are hard to find using standard means
  # so we try to find them using the found include directory and known
  # layout of the vcpkg install tree.
  get_filename_component(LevelDB_ROOT_DIR "${LevelDB_INCLUDE}/../" ABSOLUTE)
  find_library(LevelDB_LIBRARY NAMES libleveldb
               PATHS ${LevelDB_ROOT_DIR}/lib
               DOC "Path to leveldb library."
               NO_DEFAULT_PATH)

  find_library(LevelDB_LIBRARY_DEBUG NAMES libleveldb
               PATHS ${LevelDB_ROOT_DIR}/debug/lib
               DOC "Path to leveldb debug library."
               NO_DEFAULT_PATH)
else()
  # Look for the library.
  find_library(LevelDB_LIBRARY NAMES leveldb
              PATHS /usr/lib $ENV{LEVELDB_ROOT}/lib
              DOC "Path to leveldb library." )
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LevelDB DEFAULT_MSG LevelDB_INCLUDE LevelDB_LIBRARY)

if(LEVELDB_FOUND)
  message(STATUS "Found LevelDB (include: ${LevelDB_INCLUDE}, library: ${LevelDB_LIBRARY})")
  set(LevelDB_INCLUDES ${LevelDB_INCLUDE})
  if(LevelDB_LIBRARY_DEBUG)
    set(LevelDB_LIBRARIES $<$<NOT:$<CONFIG:DEBUG>>:${LevelDB_LIBRARY}> $<$<CONFIG:DEBUG>:${LevelDB_LIBRARY_DEBUG}>)
  else()
    set(LevelDB_LIBRARIES ${LevelDB_LIBRARY})
  endif()
  mark_as_advanced(LevelDB_INCLUDE LevelDB_LIBRARY)

  if(EXISTS "${LevelDB_INCLUDE}/leveldb/db.h")
    file(STRINGS "${LevelDB_INCLUDE}/leveldb/db.h" __version_lines
           REGEX "static const int k[^V]+Version[ \t]+=[ \t]+[0-9]+;")

    foreach(__line ${__version_lines})
      if(__line MATCHES "[^k]+kMajorVersion[ \t]+=[ \t]+([0-9]+);")
        set(LEVELDB_VERSION_MAJOR ${CMAKE_MATCH_1})
      elseif(__line MATCHES "[^k]+kMinorVersion[ \t]+=[ \t]+([0-9]+);")
        set(LEVELDB_VERSION_MINOR ${CMAKE_MATCH_1})
      endif()
    endforeach()

    if(LEVELDB_VERSION_MAJOR AND LEVELDB_VERSION_MINOR)
      set(LEVELDB_VERSION "${LEVELDB_VERSION_MAJOR}.${LEVELDB_VERSION_MINOR}")
    endif()

    caffe_clear_vars(__line __version_lines)
  endif()
endif()
