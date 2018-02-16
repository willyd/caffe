param(
  [string]$BuildDir
)

$CaffeRoot = (Resolve-Path (Join-Path $PSScriptRoot ..\..))
if("$BuildDir" -eq "") {
  $BuildDir = "$CaffeRoot\build"
}

. $BuildDir\tools\caffe.exe train --solver="$PSScriptRoot\lenet_solver.prototxt" $args
