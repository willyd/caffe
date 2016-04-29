@echo off
:: Download the ninja build tool
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/willyd/caffe-builder/master/download_ninja.ps1'))"
set PATH=%PATH%;%cd%

:: Set the directory for downloading dependencies
set CAFFE_DEPENDENCIES_DIR=%cd%\dependencies

:: Create build directory and configure cmake
mkdir build
pushd build
:: Setup the environement for VS 2013 x64
call "%VS120COMNTOOLS%..\..\VC\vcvarsall.bat" amd64
cmake -GNinja -DBLAS=Open -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ..\

:: Build the library and tools
cmake --build .
 
:: Build and exectute the tests
cmake --build . --target runtest

:: Lint
cmake --build . lint
popd