@setlocal
@echo off
if NOT EXIST build mkdir build
pushd build

set vcpkg_root=C:\Users\guillaume\work\vcpkg

set CMAKE_CONFIG=Release
REM CMake can find anaconda zlib. Force it to use the vcpkg zlib instead
set ZLIB_LIBRARY=%vcpkg_root%\installed\x64-windows\lib\zlib.lib

REM set CMAKE_CONFIG=Debug
REM REM CMake can find anaconda zlib. Force it to use the vcpkg zlib instead
REM set ZLIB_LIBRARY=%vcpkg_root%\installed\x64-windows\debug\lib\zlib.lib

call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat" amd64
cmake -GNinja ^
      -DCMAKE_BUILD_TYPE=%CMAKE_CONFIG% ^
      -DBUILD_SHARED_LIBS:BOOL=ON ^
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
      -DZLIB_LIBRARY:FILEPATH="%ZLIB_LIBRARY%" ^
      -DCMAKE_TOOLCHAIN_FILE:FILEPATH="%vcpkg_root%\scripts\buildsystems\vcpkg.cmake" ^
      ..
call ninja > build.log
popd