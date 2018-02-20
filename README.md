# Windows Caffe

**This is an experimental, community based branch led by Guillaume Dumont (@willyd). It is a work-in-progress.**

This branch of Caffe ports the framework to Windows.

[![Travis Build Status](https://api.travis-ci.org/BVLC/caffe.svg?branch=windows)](https://travis-ci.org/BVLC/caffe) Travis (Linux build)

[![Build status](https://ci.appveyor.com/api/projects/status/ew7cl2k1qfsnyql4/branch/windows?svg=true)](https://ci.appveyor.com/project/BVLC/caffe/branch/windows) AppVeyor (Windows build)

## Installing Caffe on Windows
### Requirements

To install Caffe on Windows you need the following:

 - Visual Studio 2015 or 2017
   - Technically only the VS C/C++ compiler is required (cl.exe)
 - [CMake](https://cmake.org/) 3.8 or higher (Visual Studio and [Ninja](https://ninja-build.org/) generators are supported)

 Optional requirements are:

 - Python for the pycaffe interface. Anaconda (or Miniconda) Python 3.6 x64 is supported
 - Matlab for the matcaffe interface.
 - CUDA 8.0 (use CUDA 9 if using Visual Studio 2017)
 - cuDNN

`cmake.exe` and `python.exe` are assumed to be available in your `PATH`.

When building with CUDA we recommend to use Visual Studio 2015 since CUDA 9.1 only works with Visual Studio 2017 version 15.1 and 15.2 (not with 15.3 and up).

To install and use Caffe on Windows you can:

1. Use vcpkg to build the Caffe C++/CUDA libraries and tools.
2. Build from source.

### Building with vcpkg

**WARNING**: This feature is not yet available but should be soon.

If you want to build with Python support you should use the instructions in [Building from source](#building-from-source).

After installing vcpkg execute the following command:
```Batch
> vcpkg install caffe[core,cuda,opencv,lmdb,leveldb,mkl] --triplet x64-windows --featurepackages
```
Remove the cuda, opencv, lmdb, etc if you wish to exclude those features from your build. Once this is done you can integrate Caffe in your own C++ project by following the vcpkg [documentation](https://github.com/Microsoft/vcpkg/blob/master/docs/examples/using-sqlite.md). You can also use the `caffe.exe` tool that will be located in your vcpkg install tree (e.g. in `C:\Projects\vcpkg\installed\x64-windows\tools`)

### Building from source

To install Caffe from source you first need to obtain the sources:

```Batch
C:\Projects> git clone https://github.com/BVLC/caffe.git
C:\Projects> cd caffe
C:\Projects\caffe> git checkout windows
```

Then you can use the provided [build_win.cmd](scripts/build_win.cmd) script as follows:

```
C:\Projects\caffe> scripts\build_win.cmd
```

You can customize what gets built by setting some environment variables before calling the script:

```
REM Customize the build (choose from the options below)
C:\Projects\caffe> set MSVC_VERSION=15 # Visual Studio 2017
C:\Projects\caffe> set MSVC_VERSION=14 # Visual Studio 2015
C:\Projects\caffe> set WITH_CUDA=1 # Build with CUDA
C:\Projects\caffe> set WITH_CUDA=0 # Build without CUDA
C:\Projects\caffe> set WITH_NINJA=1 # Build with ninja (faster)
C:\Projects\caffe> set WITH_NINJA=0 # Build with Visual Studio IDE (you get nice VS solutions)
C:\Projects\caffe> set CMAKE_BUILD_SHARED_LIBS=0 # Build a static library
C:\Projects\caffe> set CMAKE_BUILD_SHARED_LIBS=1 # Build a shared library (DLL)
C:\Projects\caffe> set CMAKE_CONFIG=Release # Release build
C:\Projects\caffe> set CMAKE_CONFIG=Debug # Debug build
REM Call the build script
C:\Projects\caffe> scripts\build_win.cmd
```

The build script will download prebuilt dependencies that were built using vcpkg. If you wish to build your own version of the libraries you can still use the build script to build Caffe but you need to set the environment variable `VCPKG_DIR` to the root of your vcpkg install. To build Caffe you need to install at least:

```
C:\Projects\vcpkg> vcpkg install gflags glog boost protobuf hdf5 openblas --triplet x64-windows
REM optional dependencies are
C:\Projects\vcpkg> vcpkg install opencv lmdb leveldb python3 --triplet x64-windows
```

When building from source, all the required DLLs will be copied (or hard linked when possible) next to the consuming binaries. If you wish to disable this option, you can by changing the command line option `-DCOPY_PREREQUISITES=0`.

If you have GCC installed (e.g. through MinGW), then Ninja will detect it before detecting the Visual Studio compiler, causing errors.  In this case you have several options:

- [Pass CMake the path](https://cmake.org/Wiki/CMake_FAQ#How_do_I_use_a_different_compiler.3F) (Set `CMAKE_C_COMPILER=your/path/to/cl.exe` and `CMAKE_CXX_COMPILER=your/path/to/cl.exe`)
- or Use the Visual Studio Generator by setting `WITH_NINJA` to 0 (This is slower, but may work even if Ninja is failing.)
- or uninstall your copy of GCC

The path to cl.exe is usually something like
`"C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/bin/your_processor_architecture/cl.exe".`
If you don't want to install Visual Studio, Microsoft's C/C++ compiler [can be obtained here](http://landinghub.visualstudio.com/visual-cpp-build-tools).

#### Building with cuDNN

To use cuDNN the easiest way is to copy the content of the `cuda` folder into your CUDA toolkit installation directory. For example if you installed CUDA 8.0 and downloaded cudnn-8.0-windows10-x64-v5.1.zip you should copy the content of the `cuda` directory to `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v8.0`.

#### Building with MKL

To use MKL instead of OpenBLAS you only need to install MKL and add the CMake command line option `-DBLAS=MKL`.

#### Building the Python interface

The recommended Python distribution is Anaconda or Miniconda. To successfully build the python interface you need to add the following conda channels:
```
conda config --add channels conda-forge
conda config --add channels defaults
```
and install the following packages:
```
conda install --yes cmake ninja  numpy scipy protobuf==3.5.0 six scikit-image pyyaml pydotplus graphviz
```

If Python is installed the default is to build the python interface and python layers. If you wish to disable the python layers or the python build use the CMake options `-DBUILD_python_layer=0` and `-DBUILD_python=0` respectively. In order to use the python interface you need to either add the `C:\Projects\caffe\python` folder to your python path of copy the `C:\Projects\caffe\python\caffe` folder to your `site_packages` folder AFTER building.

#### Building the MATLAB interface

Follow the above procedure and use `-DBUILD_matlab=ON`. Change your current directory in MATLAB to `C:\Projects\caffe\matlab` and run the following command to run the tests:
```
>> caffe.run_tests()
```
If all tests pass you can test if the classification_demo works as well. First, from `C:\Projects\caffe` run `python scripts\download_model_binary.py models\bvlc_reference_caffenet` to download the pre-trained caffemodel from the model zoo. Then change your MATLAB directory to `C:\Projects\caffe\matlab\demo` and run `classification_demo`.

## Troubleshooting

Should you encounter any error please post the output of the above commands by redirecting the output to a file and open a topic on the [caffe-users list](https://groups.google.com/forum/#!forum/caffe-users) mailing list.

## Known issues

- The `GPUTimer` related test cases always fail on Windows. This seems to be a difference between UNIX and Windows.

## Further Details

Refer to the BVLC/caffe master branch README for all other details such as license, citation, and so on.
