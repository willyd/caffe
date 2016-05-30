set(is_required REQUIRED)
if( MSVC AND NOT WITH_PREBUILD_MSVC_DEPENDENCIES )
	set(is_required)
endif()
find_package(HDF5 COMPONENTS C HL ${is_required})

macro (config_hdf5_filter filter_name header)
	string(TOUPPER ${filter_name} FILTER_VAR )
	set(${FILTER_VAR}_DIR "/usr/local/lib" CACHE PATH "Path to ${filter_name} root.")
	find_path(${FILTER_VAR}_INCLUDE_DIR NAMES ${header} HINTS ${${FILTER_VAR}_DIR}/include)
	if(EXISTS ${${FILTER_VAR}_INCLUDE_DIR})
	  include_directories(SYSTEM ${${FILTER_VAR}_INCLUDE_DIR})
	endif()

	find_file(${FILTER_VAR}_DEBUG_LIBRARY NAMES "${filter_name}_D.lib" "lib${filter_name}_D.lib" HINTS ${${FILTER_VAR}_DIR}/lib)
	find_file(${FILTER_VAR}_RELEASE_LIBRARY NAMES "${filter_name}.lib" "lib${filter_name}.lib" HINTS ${${FILTER_VAR}_DIR}/lib)
	if(EXISTS ${${FILTER_VAR}_DEBUG_LIBRARY} AND EXISTS ${${FILTER_VAR}_RELEASE_LIBRARY})
		list(APPEND Caffe_LINKER_LIBS 
			debug ${${FILTER_VAR}_DEBUG_LIBRARY}
			optimized ${${FILTER_VAR}_RELEASE_LIBRARY}
			)
	endif()
endmacro()

if( MSVC AND NOT WITH_PREBUILD_MSVC_DEPENDENCIES )
	# The default FindHDF5.cmake from CMake use h5cc to locate the files,
	# but h5cc is a .sh and thus not supported by windows environments.
	# In such a case look for the customized file instead. 
	set(CMAKE_MODULE_PATH "${HDF5_DIR};${CMAKE_MODULE_PATH}")

	find_package(HDF5 REQUIRED)

	set(HDF5_LIBRARIES)
	foreach(h5comp ${HDF5_EXPORT_LIBRARIES})
		get_target_property(h5lib ${h5comp} IMPORTED_LOCATION_RELEASE)
		list(APPEND HDF5_LIBRARIES ${h5lib})
	endforeach()

	if( NOT HDF5_PACKAGE_EXTLIBS )
		if( HDF5_ENABLE_Z_LIB_SUPPORT )
			config_hdf5_filter(zlib "zlib.h")
		endif()
		if( HDF5_ENABLE_SZIP_SUPPORT )
			config_hdf5_filter(szip "szlib.h")
		endif()
	endif()
endif()
