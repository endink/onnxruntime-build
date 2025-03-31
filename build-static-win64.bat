@echo off


set "ONNXRUNTIME_VERSION=1.17.3"
set "DML_VERSION=1.15.4"


set "WIN_SDK_VERSION=10.0.22621.0"

pushd %~dp0
set SCRIPT_DIR=%cd%
echo Work Dir: %SCRIPT_DIR%

nuget restore -SolutionDirectory . || exit

set "USE_CUDA=ON"
set "USE_DML=ON"

set "CUDA_HOME=C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.4"
set "CUDNN_HOME=E:/DevProgrames/cudnn-windows-x86_64-9.8.0.87_cuda12-archive"
SET "CUDA_VERSION=12.4"

@rem cmake env
set "OUTPUT_DIR=%SCRIPT_DIR%/output"
set "ARCHIVE_DIR=%OUTPUT_DIR%/archive"
set "ARCHIVE_NAME=onnxruntime-win64-%ONNXRUNTIME_VERSION%"
set "DML_DIR=%SCRIPT_DIR:\=/%/packages/Microsoft.AI.DirectML.%DML_VERSION%"

set "SOURCE_DIR=%SCRIPT_DIR%/static_lib"
set "BUILD_DIR=build/static_lib"
set "OUTPUT_DIR=output/static_lib"
set "ONNXRUNTIME_SOURCE_DIR=%SCRIPT_DIR%/onnxruntime"
set "CMAKE_BUILD_OPTIONS="

@rem set "CMAKE_OPTIONS=-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>DLL -DONNX_USE_MSVC_STATIC_RUNTIME=OFF -Dprotobuf_MSVC_STATIC_RUNTIME=OFF -Dgtest_force_shared_crt=ON -Donnxruntime_BUILD_UNIT_TESTS=OFF "

set "CMAKE_OPTIONS=-DUSE_MSVC_STATIC_RUNTIME=ON "

if not exist "%SCRIPT_DIR%/onnxruntime" (
    echo Clone onnxruntime ...
    git clone -b v%ONNXRUNTIME_VERSION% --depth=1 --recursive https://github.com/microsoft/onnxruntime.git
)

@echo on
cmake -S %SOURCE_DIR% ^
    -G "Visual Studio 17 2022" ^
    -A x64 ^
    -B %BUILD_DIR% ^
    -D CMAKE_BUILD_TYPE=Release ^
    -D CMAKE_CONFIGURATION_TYPES=Release ^
    -D CMAKE_INSTALL_PREFIX=%OUTPUT_DIR% ^
    -D ONNXRUNTIME_SOURCE_DIR=%ONNXRUNTIME_SOURCE_DIR% ^
    -D USE_DML=%USE_DML% ^
    -D DML_DIR=%DML_DIR% ^
    -D USE_CUDA=%USE_CUDA% ^
    -D CUDA_VERSION=%CUDA_VERSION% ^
    -D CUDA_HOME="%CUDA_HOME%" ^
    -D CUDNN_HOME="%CUDNN_HOME%" ^
    --compile-no-warning-as-error ^
    %CMAKE_OPTIONS%

cmake --build %BUILD_DIR% ^
    --config Release ^
    --parallel 8 ^
    %CMAKE_BUILD_OPTIONS%

cmake --install %BUILD_DIR% --config Release

pause
exit


:rm_rebuild_dir
if "%~1"=="" (
    echo build folder is null !!
) else (
    del /f /s /q "%~1\*.*"  >nul 2>&1
    rd /s /q  "%~1" >nul 2>&1
)
goto:eof

:remove_space
:remove_left_space
if "%tmp_var:~0,1%"==" " (
    set "tmp_var=%tmp_var:~1%"
    goto remove_left_space
)

:remove_right_space
if "%tmp_var:~-1%"==" " (
    set "tmp_var=%tmp_var:~0,-1%"
    goto remove_left_space
)
goto:eof
