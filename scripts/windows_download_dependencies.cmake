# When the path to dependencies is changed also change it in build_win.cmd
set(DEPENDENCIES_FILE_EXT .7z)
set(DEPENDENCIES_NAME vcpkg-export-20180219-194445)
set(DEPENDENCIES_URL https://github.com/willyd/vcpkg/releases/download/v1.3/${DEPENDENCIES_NAME}.7z)
set(DEPENDENCIES_MD5 f2a3ab8b5b929f6d32cc540434a38e00)

message(STATUS "Downloading caffe dependencies")
file(TO_CMAKE_PATH $ENV{USERPROFILE} USERPROFILE_DIR)
if(NOT EXISTS ${USERPROFILE_DIR})
    message(FATAL_ERROR "Could not find %USERPROFILE% directory. Please specify an alternate CAFFE_DEPENDENCIES_ROOT_DIR")
endif()
set(CAFFE_DEPENDENCIES_ROOT_DIR ${USERPROFILE_DIR}/.caffe/dependencies CACHE PATH "Prebuild depdendencies root directory")
set(CAFFE_DEPENDENCIES_DOWNLOAD_DIR ${CAFFE_DEPENDENCIES_ROOT_DIR}/download CACHE PATH "Download directory for prebuilt dependencies")

# set the dependencies URL and SHA1
set(CAFFE_DEPENDENCIES_DIR ${CAFFE_DEPENDENCIES_ROOT_DIR})

foreach(_dir ${CAFFE_DEPENDENCIES_ROOT_DIR}
                ${CAFFE_DEPENDENCIES_DOWNLOAD_DIR}
                ${CAFFE_DEPENDENCIES_DIR})
    # create the directory if it does not exist
    if(NOT EXISTS ${_dir})
    file(MAKE_DIRECTORY ${_dir})
    endif()
endforeach()
# download and extract the file if it does not exist or if does not match the sha1
get_filename_component(_download_filename ${DEPENDENCIES_URL} NAME)
set(_download_path ${CAFFE_DEPENDENCIES_DOWNLOAD_DIR}/${_download_filename})
set(_download_file 1)
if(EXISTS ${_download_path})
    file(MD5 ${_download_path} _file_sha)
    if("${_file_sha}" STREQUAL "${DEPENDENCIES_MD5}")
        set(_download_file 0)
    else()
        set(_download_file 1)
        message(STATUS "Removing file because sha1 does not match.")
        file(REMOVE ${_download_path})
    endif()
endif()
if(_download_file)
    message(STATUS "Downloading prebuilt dependencies to ${_download_path}")
    file(DOWNLOAD "${DEPENDENCIES_URL}"
                    "${_download_path}"
                    EXPECTED_HASH MD5=${DEPENDENCIES_MD5}
                    SHOW_PROGRESS
                    )
    if(EXISTS ${CAFFE_DEPENDENCIES_DIR}/${DEPENDENCIES_NAME})
        file(REMOVE_RECURSE ${CAFFE_DEPENDENCIES_DIR}/${DEPENDENCIES_NAME})
    endif()
endif()
if(EXISTS ${_download_path} AND NOT EXISTS ${CAFFE_DEPENDENCIES_DIR}/${DEPENDENCIES_NAME})
    message(STATUS "Extracting dependencies")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xf ${_download_path}
                    WORKING_DIRECTORY ${CAFFE_DEPENDENCIES_DIR}
    )
endif()


