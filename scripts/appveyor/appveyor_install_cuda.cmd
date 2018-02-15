@echo off
echo Downloading CUDA toolkit 9.1 ...
appveyor DownloadFile  https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.85_win10 -FileName cuda_9.1.85_win10.exe
echo Installing CUDA toolkit 9.1 ...
cuda_9.1.85_win10.exe -s nvcc_9.1 ^
                         cublas_9.1 ^
                         cublas_dev_9.1 ^
                         cudart_9.1 ^
                         curand_9.1 ^
                         curand_dev_9.1 ^
                         nvml_dev_9.1
:: Add CUDA toolkit to PATH
set PATH=%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v9.1\bin;%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v9.1\libnvvp;%PATH%
nvcc -V