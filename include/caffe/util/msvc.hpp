#ifndef CAFFE_UTIL_MSVC_H_
#define CAFFE_UTIL_MSVC_H_

#ifdef _MSC_VER
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

#define getpid _getpid

#endif  // _MSC_VER


#endif
