@echo off
set CONDA_LIBRARY_PREFIX=%CONDA_PREFIX%\Library
FOR /F "tokens=* USEBACKQ" %%F IN ( `python -c "import sys; sys.stdout.write('%%s.%%s' %%(sys.version_info.major, sys.version_info.minor))"` ) DO (
SET PYTHON_VERSION=%%F
)
cmake -GNinja ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DBLAS=MKL ^
      -DUSE_LMDB=OFF ^
      -DUSE_LEVELDB=OFF ^
      -DHDF5_DIR="%CONDA_LIBRARY_PREFIX%\cmake" ^
      -Dpython_version=%PYTHON_VERSION% ^
      -DCMAKE_PREFIX_PATH:PATH="%CONDA_LIBRARY_PREFIX%" ^
      ..