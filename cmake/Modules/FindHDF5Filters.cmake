if( MSVC AND NOT WITH_PREBUILD_MSVC_DEPENDENCIES )
    # ---[ SZIP
    set(SZIP_DIR "/usr/local/szip" CACHE PATH "Path to SZIP root.")
    find_path(SZIP_INCLUDE_DIR NAMES "szlib.h" HINTS ${SZIP_DIR}/include)
    if(EXISTS ${SZIP_INCLUDE_DIR})
      include_directories(SYSTEM ${SZIP_INCLUDE_DIR})
    endif()

    set(LIBEXT "a")
    if( DEFINED WIN32 )
        set(LIBEXT "lib")
    endif()
    find_file(SZIP_DEBUG_LIBRARY NAMES "szip_D.${LIBEXT}" "libszip_D.${LIBEXT}" HINTS ${SZIP_DIR}/lib)
    find_file(SZIP_RELEASE_LIBRARY NAMES "szip.${LIBEXT}" "libszip.${LIBEXT}" HINTS ${SZIP_DIR}/lib)
    if(EXISTS ${SZIP_DEBUG_LIBRARY} AND EXISTS ${SZIP_RELEASE_LIBRARY})
    list(APPEND Caffe_LINKER_LIBS 
        debug ${SZIP_DEBUG_LIBRARY}
        optimized ${SZIP_RELEASE_LIBRARY}
        )
    endif()
        
    # ---[ ZLIB
    # TODO: Skip if Caffe_LINKER_LIBS already contains zlib.
    set(ZLIB_DIR "/usr/local/zlib" CACHE PATH "Path to ZLIB root.")
    find_path(ZLIB_INCLUDE_DIR NAMES "zlib.h" HINTS ${ZLIB_DIR}/include)
    if(EXISTS ${ZLIB_INCLUDE_DIR})
        include_directories(SYSTEM ${ZLIB_INCLUDE_DIR})
    endif()

    find_file(ZLIB_DEBUG_LIBRARY NAMES "zlib_D.${LIBEXT}" "libzlib_D.${LIBEXT}" HINTS ${ZLIB_DIR}/lib)
    find_file(ZLIB_RELEASE_LIBRARY NAMES "zlib.${LIBEXT}" "libzlib.${LIBEXT}" HINTS ${ZLIB_DIR}/lib)
    if(EXISTS ${ZLIB_DEBUG_LIBRARY} AND EXISTS ${ZLIB_RELEASE_LIBRARY})
        list(APPEND Caffe_LINKER_LIBS 
            debug ${ZLIB_DEBUG_LIBRARY}
            optimized ${ZLIB_RELEASE_LIBRARY}
            )
    endif()
endif()
