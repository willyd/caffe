# - Find Protobuf
#
#  Protobuf_INCLUDE_DIR  - Protobuf source code folder
#  Protobuf_LIBRARIES - List of libraries when using Protobuf.
#  Protobuf_EXECUTABLE - Protobuf executable file
#  Protobuf_FOUND     - True if Protobuf found.

# Look for the source file.
find_path(PROTOBUF_INCLUDE_DIR NAMES google/protobuf/stubs/common.h
  PATHS ${PROTOBUF_SRC_ROOT_FOLDER}/src/
  DOC "Path in which the source files for protobuf are located." )

find_library(PROTOBUF_LIBRARY NAMES libprotobuf.lib
  PATHS ${CMAKE_INSTALL_PREFIX}/vsprojects/Release
  DOC "Path to libprotobuf.lib release build")

find_library(PROTOBUF_LIBRARY_DEBUG NAMES libprotobuf.lib
  PATHS ${CMAKE_INSTALL_PREFIX}/vsprojects/Debug
  DOC "Path to libprotobuf.lib debug build")

find_program(PROTOBUF_PROTOC_EXECUTABLE NAMES protoc.exe
  PATHS ${CMAKE_INSTALL_PREFIX}/vsprojects/Release
  DOC "Path to protoc.exe release build")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Protobuf DEFAULT_MSG
  PROTOBUF_INCLUDE_DIR PROTOBUF_PROTOC_EXECUTABLE
  PROTOBUF_LIBRARY PROTOBUF_LIBRARY_DEBUG)

if(Protobuf_FOUND)
  set(PROTOBUF_LIBRARIES optimized ${PROTOBUF_LIBRARY} debug ${PROTOBUF_LIBRARY_DEBUG})
  message(STATUS "Found Protobuf, include:")
  message(STATUS "  ${PROTOBUF_INCLUDE_DIR}")
  message(STATUS "  ${PROTOBUF_PROTOC_EXECUTABLE}")
  message(STATUS "  ${PROTOBUF_LIBRARY} ${PROTOBUF_LIBRARY_DEBUG}")
  message(STATUS "  ${PROTOBUF_LIBRARIES}")
endif()
