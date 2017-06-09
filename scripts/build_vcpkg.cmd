@setlocal
@echo off
if NOT EXIST build mkdir build
pushd build

set vcpkg_root=C:\Users\guillaume\work\vcpkg
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat" amd64
cmake -GNinja ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DBUILD_SHARED_LIBS:BOOL=ON ^
      -DUSE_OPENCV:BOOL=OFF ^
      -DUSE_LEVELDB:BOOL=OFF ^
      -DUSE_PREBUILT_DEPENDENCIES:BOOL=OFF ^
      -DCPU_ONLY:BOOL=ON ^
      -DUSE_CUDNN:BOOL=OFF ^
      -DUSE_NCCL:BOOL=OFF ^
      -DBUILD_python_layer:BOOL=OFF ^
      -DBUILD_python:BOOL=OFF ^
      -DBUILD_matlab:BOOL=OFF ^
      -DCOPY_PREREQUISITES:BOOL=OFF ^
      -DINSTALL_PREREQUISITES:BOOL=OFF ^
      -DUSE_OPENMP:BOOL=OFF ^
      -DBLAS=Open ^
      -DGLOG_LIBRARY="glog::glog" ^
      -DCMAKE_TOOLCHAIN_FILE:FILEPATH=%vcpkg_root%\scripts\buildsystems\vcpkg.cmake ^
      ..
call ninja > build.log
popd