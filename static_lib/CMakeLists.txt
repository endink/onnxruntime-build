cmake_minimum_required(VERSION 3.26)
project(onnxruntime_static_lib)

# Hide symbols
set(C_HEADER_FILE ${ONNXRUNTIME_SOURCE_DIR}/include/onnxruntime/core/session/onnxruntime_c_api.h)
file(COPY_FILE ${C_HEADER_FILE} ${C_HEADER_FILE}.bak)
file(READ ${C_HEADER_FILE} C_HEADER_CONTENTS)
string(REPLACE "__attribute__((visibility(\"default\")))" "__attribute__((visibility(\"hidden\")))" MODIFIED_C_HEADER_CONTENTS "${C_HEADER_CONTENTS}")
file(WRITE ${C_HEADER_FILE} "${MODIFIED_C_HEADER_CONTENTS}")

option(USE_MSVC_STATIC_RUNTIME "Use static crt or not" OFF)
option(USE_DML "Use DirectML" OFF)
option(USE_CUDA "Use CUDA" OFF)
set(CUDA_VERSION "12.4" CACHE STRING "CUDA default version")

set(onnxruntime_BUILD_UNIT_TESTS OFF)
set(onnxruntime_BUILD_SHARED_LIB ON)

if(MSVC)
    if(USE_DML)
        #SEE https://github.com/microsoft/onnxruntime/blob/main/cmake/external/dml.cmake    
        set(onnxruntime_USE_DML ON)
        # if DML_DIR defined, use local DML, else use Nuget package
        if(DEFINED DML_DIR)
            set(onnxruntime_USE_CUSTOM_DIRECTML ON)
            set(dml_LIB_DIR ${DML_DIR}/bin/x64-win)
            set(dml_INCLUDE_DIR ${DML_DIR}/include)
            message(STATUS "onnxruntime_USE_CUSTOM_DIRECTML: ${onnxruntime_USE_CUSTOM_DIRECTML}")
            message(STATUS "dml_LIB_DIR: ${dml_LIB_DIR}")
            message(STATUS "dml_INCLUDE_DIR: ${dml_INCLUDE_DIR}")
        endif()
    endif()

    if(USE_MSVC_STATIC_RUNTIME)
        message("------------------ Use Static MSVC CRT ------------------")
        # Set MSVC runtime library
        set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreaded)
        set(ONNX_USE_MSVC_STATIC_RUNTIME ON)
        set(protobuf_MSVC_STATIC_RUNTIME ON)
        set(ABSL_MSVC_STATIC_RUNTIME ON)
        set(gtest_force_shared_crt OFF)

    else()
    message("------------------ Use Dynamic MSVC CRT ------------------")
        set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
        set(ONNX_USE_MSVC_STATIC_RUNTIME OFF)
        set(protobuf_MSVC_STATIC_RUNTIME OFF)
        set(ABSL_MSVC_STATIC_RUNTIME OFF)
        set(gtest_force_shared_crt ON)
    endif()
endif()

if(USE_CUDA)
    set(onnxruntime_USE_CUDA ON)
    if(DEFINED CUDA_HOME)
        set(onnxruntime_CUDA_HOME "${CUDA_HOME}")
    endif()
    if(DEFINED CUDNN_HOME)
        set(onnxruntime_CUDNN_HOME "${CUDNN_HOME}")
    endif()
    set(onnxruntime_CUDA_VERSION "${CUDA_VERSION}")
    
    message(STATUS "USE_CUDA: ${onnxruntime_USE_CUDA} (VER: ${onnxruntime_CUDA_VERSION})")
    message(STATUS "CUDA_HOME: ${onnxruntime_CUDA_HOME}")
    message(STATUS "CUDNN_HOME: ${onnxruntime_CUDNN_HOME}")
endif()


# Suppress C++23 deprecation warnings
add_compile_definitions(_SILENCE_ALL_CXX23_DEPRECATION_WARNINGS)

# Add ONNX Runtime
add_subdirectory(${ONNXRUNTIME_SOURCE_DIR}/cmake onnxruntime EXCLUDE_FROM_ALL)

# Bundle the static library
include(bundle_static_library.cmake)
bundle_static_library(${PROJECT_NAME} onnxruntime)

# Install the static library
install(
    FILES $<TARGET_PROPERTY:onnxruntime,PUBLIC_HEADER>
    TYPE INCLUDE
)
install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${PROJECT_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX}
    RENAME ${CMAKE_STATIC_LIBRARY_PREFIX}onnxruntime${CMAKE_STATIC_LIBRARY_SUFFIX}
    TYPE LIB
)

# Restore the original header file
install(
    CODE "file(RENAME ${C_HEADER_FILE}.bak ${C_HEADER_FILE})"
)
