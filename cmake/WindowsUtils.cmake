################################################################################################
# Function to resolve the folder containing the prebuilt dependencies. It not folder was specified
# via the CAFFE_DEPENDENCIES_DIR environment of cache variable of if this folder is empty. CMake will
# download and extract a zip archive containing pre-built dependencies and supporting CMake files.
# Usage:
#   windows_resolve_dependencies()
macro(windows_resolve_dependencies)
    if( MSVC AND WITH_PREBUILD_MSVC_DEPENDENCIES )
        # TODO check architecture, compiler, build_type and download the right archive
        # Initialize the download url from the environment variable of default value
        set(__dependencies_url "$ENV{CAFFE_DEPENDENCIES_URL}")
        if(NOT __dependencies_url)
            set(__dependencies_url "https://ci.appveyor.com/api/buildjobs/5hsad4lflemkbrt9/artifacts/build/install/super-builder-libraries.zip")
        endif()

        # initialize the dependencies download directory
        set(CAFFE_DEPENDENCIES_URL ${__dependencies_url} CACHE STRING "The URL to download the prebuilt dependencies for Caffe")
        file(TO_CMAKE_PATH "$ENV{CAFFE_DEPENDENCIES_DIR}" __dependencies_dir)
        if(NOT __dependencies_dir)
            set(__dependencies_dir "${CMAKE_CURRENT_BINARY_DIR}/dependencies")
        endif()
        set(CAFFE_DEPENDENCIES_DIR "${__dependencies_dir}" CACHE PATH "The directory where one can find the precompiled dependencies")

        # Determine if we need to download dependencies
        set(__download_dependencies TRUE)
        if(EXISTS ${CAFFE_DEPENDENCIES_DIR})
            # check that the directory is not empty
            file(GLOB_RECURSE __dependencies_dir_content LIST_DIRECTORIES FALSE ${CAFFE_DEPENDENCIES_DIR}/*.*)
            list(LENGTH __dependencies_dir_content _n_files)
            if(_n_files GREATER 0)
                set(__download_dependencies FALSE)
            endif()
        endif()
        if(__download_dependencies)
            windows_download_dependencies(${CAFFE_DEPENDENCIES_URL} ${CAFFE_DEPENDENCIES_DIR})
        endif()
        # include the cache file to use the right find modules
        include("${CAFFE_DEPENDENCIES_DIR}/InitialCache.cmake")
    endif()
endmacro()

################################################################################################
# Function to download and extract an archive of pre-built dependencies
# Usage:
#   windows_download_dependencies(url destination)
function(windows_download_dependencies url destination)
    set(__download_dir ${CMAKE_CURRENT_BINARY_DIR}/dependencies_download)
    set(__extract_dir ${CMAKE_CURRENT_BINARY_DIR}/dependencies_extract)
    set(__dependencies_archive "${__download_dir}/dependencies.zip")
    set(__dependencies_download_stamp "${CMAKE_CURRENT_BINARY_DIR}/dependencies_download.stamp")
    set(__dependencies_extract_stamp "${CMAKE_CURRENT_BINARY_DIR}/dependencies_extract.stamp")

    if(NOT EXISTS ${__dependencies_download_stamp})
        message(STATUS "Downloading dependencies archive...")
        # download and extract dependencies to  CAFFE_DEPENDENCIES_DIR
        file(MAKE_DIRECTORY ${__download_dir})
        # todo expected hash EXPECTED_HASH SHA1=...
        file(DOWNLOAD "${url}" "${__dependencies_archive}" SHOW_PROGRESS STATUS _download_success)
    else()
        set(_download_success 0)
    endif()
    if(_download_success EQUAL 0)
        # create a stamp file for the download
        execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${__dependencies_download_stamp})

        if(NOT EXISTS ${__dependencies_extract_stamp})
            message(STATUS "Extracting dependencies archive...")
            file(MAKE_DIRECTORY ${__extract_dir})
            execute_process(COMMAND ${CMAKE_COMMAND} -E tar xf "${__dependencies_archive}"
                            WORKING_DIRECTORY ${__extract_dir}
                            RESULT_VARIABLE __extract_success
            )
            if(__extract_success EQUAL 0)
                execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${__dependencies_extract_stamp})
                file(RENAME "${__extract_dir}" "${destination}")
            else()
                file(REMOVE_RECURSE ${__extract_dir})
                message(FATAL_ERROR "Failed to extract: ${__dependencies_archive}")
            endif()
        endif()
    else()
        file(REMOVE_RECURSE ${__download_dir})
        message(FATAL_ERROR "Failed to download: ${url}")
    endif()
endfunction()

set(_target_copy_dependencies_file "${CMAKE_CURRENT_LIST_FILE}")

################################################################################################
# Function to add a post build command to a target to copy all its
# shared library dependencies (.dll on Windows) inside its output folder
# Usage:
#   target_copy_dependencies(target_name)
include(CMakeParseArguments)
function(target_copy_dependencies target)
    set(options)
    set(oneValueArgs
	DESTINATION
	)
    set(multiValueArgs "")
    cmake_parse_arguments(tcd "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN})
    if(MSVC)
		unset(_target_dirs)
		# get the output directory the libraries this target links to
		get_target_property(_link_libs ${target} LINK_LIBRARIES)
		foreach(_link_lib ${_link_libs})
			if(TARGET ${_link_lib})
				get_target_property(_type ${_link_lib} TYPE)
				if(_type STREQUAL "SHARED_LIBRARY")
					get_target_property(_output_dir ${_link_lib} RUNTIME_OUTPUT_DIRECTORY)
					if(_output_dir)
						list(APPEND _target_dirs ${_output_dir})
					endif()
				endif()
			endif()
		endforeach()
		# TODO add escaping for list
        add_custom_command( TARGET ${target} POST_BUILD
                            COMMAND ${CMAKE_COMMAND}
                            -DMSVC_VERSION=${MSVC_VERSION}
                            -DTARGET_PATH=$<TARGET_FILE:${target}>
                            -DTARGET_DIRS="${_target_dirs}"
                            -DCAFFE_DEPENDENCIES_DIR=${CAFFE_DEPENDENCIES_DIR}
                            -DDESTINATION="${tcd_DESTINATION}"
                            -DCMAKE_CURRENT_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}
                            -P ${_target_copy_dependencies_file}
                            )
    endif()
endfunction()

################################################################################################
# Utility function to retreive all the folders containing shared libraries
# starting a some root folder
# Usage:
#   glob_dependencies_directories(root_dir output_variable)
function(glob_dependencies_directories _root_dir out_var)
    file(GLOB_RECURSE _paths "${_root_dir}/*.dll")
	unset(_dirs)
    foreach(_path ${_paths})
		get_filename_component(_dir ${_path} DIRECTORY)
		list(APPEND _dirs ${_dir})
	endforeach()
	list(REMOVE_DUPLICATES _dirs)
    set(${out_var} ${_dirs} PARENT_SCOPE)
endfunction()

function(find_dumpbin var)
    # MSVC_VERSION =
    # 1200 = VS  6.0
    # 1300 = VS  7.0
    # 1310 = VS  7.1
    # 1400 = VS  8.0
    # 1500 = VS  9.0
    # 1600 = VS 10.0
    # 1700 = VS 11.0
    # 1800 = VS 12.0
    # 1900 = VS 14.0
    set(MSVC_PRODUCT_VERSION_1200 6.0)
    set(MSVC_PRODUCT_VERSION_1300 7.0)
    set(MSVC_PRODUCT_VERSION_1310 7.1)
    set(MSVC_PRODUCT_VERSION_1400 8.0)
    set(MSVC_PRODUCT_VERSION_1500 9.0)
    set(MSVC_PRODUCT_VERSION_1600 10.0)
    set(MSVC_PRODUCT_VERSION_1700 11.0)
    set(MSVC_PRODUCT_VERSION_1800 12.0)
    set(MSVC_PRODUCT_VERSION_1900 14.0)
    get_filename_component(MSVC_VC_DIR [HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VisualStudio\\${MSVC_PRODUCT_VERSION_${MSVC_VERSION}}\\Setup\\VC;ProductDir] REALPATH CACHE)

    find_program(DUMPBIN_EXECUTABLE dumpbin ${MSVC_VC_DIR}/bin)
    if(NOT DUMPBIN_EXECUTABLE)
        message(FATAL_ERROR "Could not find DUMPBIN_EXECUTABLE please define this variable")
    endif()
    set(${var} ${DUMPBIN_EXECUTABLE} PARENT_SCOPE)
endfunction()

function(is_system_library lib var)    
    string(TOLOWER "$ENV{SystemRoot}" sysroot)
    file(TO_CMAKE_PATH "${sysroot}" sysroot)

    string(TOLOWER "$ENV{windir}" windir)
    file(TO_CMAKE_PATH "${windir}" windir)

    string(TOLOWER "${lib}" _lower)

    if(_lower MATCHES "^(api-ms-win-|${sysroot}/sys(tem|wow)|${windir}/sys(tem|wow)|(.*/)*msvc[^/]+dll)")
        set(${var} TRUE  PARENT_SCOPE)
    else()
        set(${var} FALSE PARENT_SCOPE)    
    endif()
endfunction()

function(list_dependencies target var)
    find_dumpbin(dumpbin)
    execute_process(COMMAND ${dumpbin} /dependents ${target}
                    RESULT_VARIABLE _result
                    OUTPUT_VARIABLE _output
                    ERROR_VARIABLE _error
    )
    if(NOT _result EQUAL 0)
        message(FATAL_ERROR "dumpbin failed on ${target}")
    endif()
    string(REPLACE "\n" ";" _output_list "${_output}")
    set(gp_regex "^    ([^ ].*[Dd][Ll][Ll])$")
    unset(_dependencies)
    foreach(_output_line ${_output_list})
        if(${_output_line} MATCHES ${gp_regex})
            if(NOT "${CMAKE_MATCH_1}" STREQUAL "${target}")
                list(APPEND _dependencies ${CMAKE_MATCH_1})
            endif()
        endif()
    endforeach()    
    set(${var} ${_dependencies} PARENT_SCOPE)
endfunction()

function(internal_resolve_dependencies target dirs var)    
    list_dependencies("${target}" _dependencies)
    foreach(_dep ${_dependencies})
        unset(is_sytem)
        find_file(${_dep}_file ${_dep} PATHS ${dirs} NO_DEFAULT_PATH)
        if(${_dep}_file)

            is_system_library(${${_dep}_file} ${_dep}_is_system)

            if(NOT ${_dep}_is_system)
                list(APPEND _found_dependencies ${${_dep}_file})
                internal_resolve_dependencies(${${_dep}_file} "${dirs}" ${_dep}_dependencies_var)
                list(REMOVE_DUPLICATES ${_dep}_dependencies_var)
                list(APPEND _found_dependencies ${${_dep}_dependencies_var})
                list(REMOVE_DUPLICATES _found_dependencies)
            endif()
        else()
            #message(STATUS "Could not find ${_dep}")
        endif()
    endforeach()
    set(${var} ${_found_dependencies} PARENT_SCOPE)
    
endfunction()

function(resolve_dependencies target dirs var)
    internal_resolve_dependencies(${target} "${dirs}" _found_dependencies)
    set(${var} ${_found_dependencies} PARENT_SCOPE)
endfunction()

function(copy_resolved_dependencies target dependencies destination)
    if(NOT destination)
        get_filename_component(destination ${target} DIRECTORY)
    endif()
    message(STATUS "Copying resolved dependencies for ${target} to ${destination}...")
    # lock a file to prevent concurrent copies
    set(_lock_file ${destination}/copy_resolved_dependencies.lock) 
    file(LOCK ${_lock_file})         
    file(COPY ${dependencies} DESTINATION ${destination})    
    file(LOCK ${_lock_file} RELEASE)
endfunction()

if( CMAKE_SCRIPT_MODE_FILE AND WITH_PREBUILD_MSVC_DEPENDENCIES )
    # use custom script instead of BundleUtilities
    # because they require an executable and the target provided
    # could be a dll
    message(STATUS "Resolving dependencies for ${TARGET_PATH}...")    
    glob_dependencies_directories(${CAFFE_DEPENDENCIES_DIR} _dirs)
    list(APPEND _dirs ${TARGET_DIRS})
    resolve_dependencies("${TARGET_PATH}" "${_dirs}" _dependencies)    
    copy_resolved_dependencies("${TARGET_PATH}" "${_dependencies}" "${DESTINATION}")
endif()
