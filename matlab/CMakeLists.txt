# Builds Matlab (or Octave) interface. In case of Matlab caffe must be
# compield as shared library. Octave can link static or shared caffe library
# To install octave run: sudo apt-get install liboctave-dev

if(NOT BUILD_matlab)
  return()
endif()

if(HAVE_MATLAB AND Octave_compiler)
  set(build_using ${Matlab_build_mex_using})
elseif(HAVE_MATLAB AND NOT Octave_compiler)
  set(build_using "Matlab")
elseif(NOT HAVE_MATLAB AND Octave_compiler)
  set(build_using "Octave")
else()
  return()
endif()

if(NOT MSVC AND NOT BUILD_SHARED_LIBS AND build_using MATCHES Matlab)
  message(FATAL_ERROR "Matlab MEX interface (with default mex options file) can only be built if caffe is compiled as shared library on UNIX systems. Please enable 'BUILD_SHARED_LIBS' in CMake. Aternativelly you can switch to Octave compiler.")
endif()

# global settings
file(GLOB Matlab_srcs +caffe/private/caffe_.cpp)

caffe_get_current_cflags(cflags)
caffe_parse_linker_libs(Caffe_LINKER_LIBS folders libflags macos_frameworks)
set(folders $<TARGET_LINKER_FILE_DIR:caffe> ${folders})

# prepare linker flag lists
string(REPLACE ";" ";-L" link_folders "-L${folders}")
string(REPLACE ";" ":"  rpath_folders   "${folders}")

if(build_using MATCHES "Matlab")
  # keep this line as a reminder of the linker problems
  #set(libflags -lcaffe${Caffe_POSTFIX} ${libflags}) # Matlab R2014a complans for -Wl,--whole-archive

  # Handle build with or without GPUArray
  if(HAVE_MATLAB_GPUARRAY)
    include_directories(${MATLAB_GPUARRAY_INCLUDE_DIR})
    add_definitions(-DHAVE_MATLAB_GPUARRAY)
    set(MATLAB_ADDITIONAL_LIBRARIES ${MATLAB_GPU_LIB})
  endif()

  matlab_add_mex(NAME matlab
                 SRC ${Matlab_srcs} # maybe you need to add some other sources
                 OUTPUT_NAME caffe_ # change the output name to _caffe.mexw64
                 LINK_TO ${MATLAB_ADDITIONAL_LIBRARIES} caffe # cmake will take care of forwarding the correct transitive library dependencies to your mex file
                 )
  # output the target in the source tree as in the original version. 
  set_target_properties(matlab PROPERTIES 
                        RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/matlab/+caffe/private
                        )

elseif(build_using MATCHES "Octave")
    set(Matlab_caffe_mex ${PROJECT_SOURCE_DIR}/matlab/+caffe/private/caffe_.mex)

  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(libflags -Wl,-force_load,$<TARGET_LINKER_FILE:caffe> ${libflags})
  elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(libflags -Wl,--whole-archive -lcaffe${Caffe_POSTFIX} -Wl,--no-whole-archive ${libflags})
  endif()

  add_custom_command(OUTPUT ${Matlab_caffe_mex} COMMAND ${Octave_compiler}
      ARGS --mex -o ${Matlab_caffe_mex} ${Matlab_srcs} ${cflags} ${link_folders} ${libflags} -Wl,-rpath,${rpath_folders}
      DEPENDS caffe COMMENT "Building Octave interface: ${Matlab_caffe_mex}" VERBATIM)

  add_custom_target(octave ALL DEPENDS ${Matlab_caffe_mex} SOURCES ${Matlab_srcs})
endif()

# ---[ Install
file(GLOB mfiles caffe/*.m)
install(FILES ${mfiles} ${Matlab_caffe_mex} DESTINATION matlab)

