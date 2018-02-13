@echo off
@setlocal EnableDelayedExpansion

if NOT DEFINED MSVC_VERSION set MSVC_VERSION=15
if NOT DEFINED WITH_NINJA set WITH_NINJA=1
if "%WITH_CUDA%"=="1" (
  if NOT DEFINED CPU_ONLY set CPU_ONLY=0
) else (
  if NOT DEFINED CPU_ONLY set CPU_ONLY=1
)
if NOT DEFINED CUDA_ARCH_NAME set CUDA_ARCH_NAME=Auto
if NOT DEFINED CMAKE_CONFIG set CMAKE_CONFIG=Release
if NOT DEFINED USE_NCCL set USE_NCCL=0
if NOT DEFINED CMAKE_BUILD_SHARED_LIBS set CMAKE_BUILD_SHARED_LIBS=1
if NOT DEFINED PYTHON_VERSION set PYTHON_VERSION=3
if NOT DEFINED BUILD_PYTHON set BUILD_PYTHON=1
if NOT DEFINED BUILD_PYTHON_LAYER set BUILD_PYTHON_LAYER=1
if NOT DEFINED BUILD_MATLAB set BUILD_MATLAB=0
if NOT DEFINED PYTHON_EXE set PYTHON_EXE=python
if NOT DEFINED RUN_TESTS set RUN_TESTS=1
if NOT DEFINED RUN_LINT set RUN_LINT=1
if NOT DEFINED RUN_INSTALL set RUN_INSTALL=0

if "%MSVC_VERSION%"=="15" (
    set CMAKE_GENERATOR=Visual Studio 15 2017 Win64
    if NOT DEFINED VS2017INSTALLDIR (
        echo Calling "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
        call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
    ) else (
        echo Calling "!VS2017INSTALLDIR!\VC\Auxiliary\Build\vcvarsall.bat" x64
        call "!VS2017INSTALLDIR!\VC\Auxiliary\Build\vcvarsall.bat" x64
    )
)
if "%MSVC_VERSION%"=="14" (
    set CMAKE_GENERATOR=Visual Studio 14 2015 Win64
    echo Calling "!VS140COMNTOOLS!..\..\VC\vcvarsall.bat" amd64
    call "!VS140COMNTOOLS!..\..\VC\vcvarsall.bat" amd64
)
if %WITH_NINJA%==1 (
    set CMAKE_GENERATOR=Ninja
)

if NOT DEFINED VCPKG_DIR set VCPKG_DIR=%USERPROFILE%\.caffe\dependencies\vcpkg-export-20171219-000540
set VCPKG_TOOLCHAIN=%VCPKG_DIR%\scripts\buildsystems\vcpkg.cmake
if NOT EXIST "%VCPKG_TOOLCHAIN%" (
    echo calling cmake
    cmake -P "%~dp0\windows_download_dependencies.cmake" || exit /b 1
)
if NOT EXIST "%VCPKG_TOOLCHAIN%" (
    echo Cannot find tool chain file "%VCPKG_TOOLCHAIN%"
    set ERRORLEVEL=1
    goto :EOF
)

if DEFINED APPVEYOR (
    set CONDA_ROOT=C:\Miniconda36-x64
    set PATH=!CONDA_ROOT!;!CONDA_ROOT!\Library\mingw-w64\bin;!CONDA_ROOT!\Scripts;!CONDA_ROOT!\Library\bin;!PATH!
    conda config --add channels conda-forge
    conda config --add channels defaults
    conda install --yes cmake ninja
    cmake --version
    ninja --version
    conda install --yes numpy scipy protobuf==3.3.0 six scikit-image pyyaml pydotplus graphviz
)

echo INFO: ============================================================
echo INFO: Summary:
echo INFO: ============================================================
echo INFO: MSVC_VERSION               = !MSVC_VERSION!
echo INFO: WITH_NINJA                 = !WITH_NINJA!
echo INFO: CMAKE_GENERATOR            = "!CMAKE_GENERATOR!"
echo INFO: CPU_ONLY                   = !CPU_ONLY!
echo INFO: CUDA_ARCH_NAME             = !CUDA_ARCH_NAME!
echo INFO: CMAKE_CONFIG               = !CMAKE_CONFIG!
echo INFO: USE_NCCL                   = !USE_NCCL!
echo INFO: CMAKE_BUILD_SHARED_LIBS    = !CMAKE_BUILD_SHARED_LIBS!
echo INFO: PYTHON_VERSION             = !PYTHON_VERSION!
echo INFO: BUILD_PYTHON               = !BUILD_PYTHON!
echo INFO: BUILD_PYTHON_LAYER         = !BUILD_PYTHON_LAYER!
echo INFO: BUILD_MATLAB               = !BUILD_MATLAB!
echo INFO: PYTHON_EXE                 = "!PYTHON_EXE!"
echo INFO: RUN_TESTS                  = !RUN_TESTS!
echo INFO: RUN_LINT                   = !RUN_LINT!
echo INFO: RUN_INSTALL                = !RUN_INSTALL!
echo INFO: ============================================================

REM Build and exectute the tests
REM Do not run the tests with shared library
if !RUN_TESTS! EQU 1 (
    if %CMAKE_BUILD_SHARED_LIBS% EQU 1 (
        echo WARNING: Disabling tests with shared library build
        set RUN_TESTS=0
    )
)

set BUILD_DIR=%~dp0\..\build
if NOT EXIST "%BUILD_DIR%" mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"

REM Configure using cmake and using the caffe-builder dependencies
REM Add -DCUDNN_ROOT=C:/Projects/caffe/cudnn-8.0-windows10-x64-v5.1/cuda ^
REM below to use cuDNN
cmake -G"!CMAKE_GENERATOR!" ^
      -DBLAS=Open ^
      -DCMAKE_TOOLCHAIN_FILE:FILEPATH=%VCPKG_TOOLCHAIN% ^
      -DCMAKE_BUILD_TYPE:STRING=%CMAKE_CONFIG% ^
      -DBUILD_SHARED_LIBS:BOOL=%CMAKE_BUILD_SHARED_LIBS% ^
      -Dpython_version=!PYTHON_VERSION! ^
      -DBUILD_python:BOOL=%BUILD_PYTHON% ^
      -DBUILD_python_layer:BOOL=%BUILD_PYTHON_LAYER% ^
      -DBUILD_matlab:BOOL=%BUILD_MATLAB% ^
      -DCPU_ONLY:BOOL=!CPU_ONLY! ^
      -DCOPY_PREREQUISITES:BOOL=0 ^
      -DINSTALL_PREREQUISITES:BOOL=0 ^
      -DUSE_PREBUILT_DEPENDENCIES=OFF ^
      -DUSE_NCCL:BOOL=!USE_NCCL! ^
      -DCUDA_ARCH_NAME:STRING=%CUDA_ARCH_NAME% ^
      -DUSE_LEVELDB=OFF ^
      "%~dp0\.."

if ERRORLEVEL 1 (
  echo ERROR: Configure failed
  exit /b 1
)

REM Lint
if %RUN_LINT% EQU 1 (
    cmake --build . --target lint  --config %CMAKE_CONFIG%
)

if ERRORLEVEL 1 (
  echo ERROR: Lint failed
  exit /b 1
)

REM Build the library and tools
cmake --build . --config %CMAKE_CONFIG%

if ERRORLEVEL 1 (
  echo ERROR: Build failed
  exit /b 1
)

REM Build and exectute the tests
if !RUN_TESTS! EQU 1 (
    cmake --build . --target runtest --config %CMAKE_CONFIG%

    if ERRORLEVEL 1 (
        echo ERROR: Tests failed
        exit /b 1
    )

    if %BUILD_PYTHON% EQU 1 (
        if %BUILD_PYTHON_LAYER% EQU 1 (
            REM Run python tests only in Release build since
            REM the _caffe module is _caffe-d is debug
            if "%CMAKE_CONFIG%"=="Release" (
                REM Run the python tests
                cmake --build . --target pytest

                if ERRORLEVEL 1 (
                    echo ERROR: Python tests failed
                    exit /b 1
                )
            )
        )
    )
)

if %RUN_INSTALL% EQU 1 (
    cmake --build . --target install --config %CMAKE_CONFIG%
)

popd
@endlocal