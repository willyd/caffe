@echo off

REM We assume cudnn is installed in the CUDA installation directory on the build platform
REM But we could download it with the curl command
REM curl http://developer.download.nvidia.com/compute/redist/cudnn/v7.3.1/cudnn-9.0-windows10-x64-v7.3.1.20.zip -O

mkdir build
pushd build

cmake -GNinja ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DBUILD_SHARED_LIBS=ON ^
      -DBLAS=MKL ^
      -DUSE_LMDB=ON ^
      -DUSE_LEVELDB=OFF ^
      -Dpython_version=%PY_VER% ^
      -DCMAKE_PREFIX_PATH:PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_INSTALL_PREFIX:PATH="%LIBRARY_PREFIX%" ^
      -DCOPY_PREREQUISITES:BOOL=OFF ^
      -DINSTALL_PREREQUISITES:BOOL=OFF ^
      ..

cmake --build . --target install

move "%LIBRARY_PREFIX%\python\caffe" "%SP_DIR%\"
rmdir /S /Q "%LIBRARY_PREFIX%\python"

popd