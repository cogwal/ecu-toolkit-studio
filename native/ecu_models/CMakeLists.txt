cmake_minimum_required(VERSION 3.10)
project(ecu_models LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

set(SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(SOURCES
  ${SRC_DIR}/ecu_models.cpp
)

if(WIN32)
  set(LIB_NAME ecu_models)
  add_library(${LIB_NAME} SHARED ${SOURCES})
  set_target_properties(${LIB_NAME} PROPERTIES PREFIX "" SUFFIX ".dll")
elseif(APPLE)
  add_library(ecu_models SHARED ${SOURCES})
  set_target_properties(ecu_models PROPERTIES OUTPUT_NAME "ecu_models" SUFFIX ".dylib")
else()
  add_library(ecu_models SHARED ${SOURCES})
  set_target_properties(ecu_models PROPERTIES OUTPUT_NAME "ecu_models" PREFIX "lib" SUFFIX ".so")
endif()

if(WIN32)
  # When building the DLL on Windows, define ECU_MODELS_DLL_EXPORTS so
  # the headers know to export symbols instead of importing them.
  target_compile_definitions(ecu_models PRIVATE ECU_MODELS_DLL_EXPORTS)
endif()

# Add include directories for the third-party libraries so headers like
# <ttctk.h> and <PCANBasic.h> can be included from `ecu_models.h`.
target_include_directories(ecu_models
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/lib/toolkit/Include
    ${CMAKE_CURRENT_SOURCE_DIR}/lib/PCAN-Basic/Include
)

## Platform-specific library paths
set(TTCTK_DLL "")
set(PCAN_DLL "")
set(TTCTK_LIB "")
set(PCAN_LIB "")
set(CRYPTO_DLL "")
if(WIN32)
  set(TTCTK_DLL ${CMAKE_CURRENT_SOURCE_DIR}/lib/toolkit/windows_x64/ttctk.dll)
  set(TTCTK_LIB ${CMAKE_CURRENT_SOURCE_DIR}/lib/toolkit/windows_x64/ttctk.lib)
  set(CRYPTO_DLL ${CMAKE_CURRENT_SOURCE_DIR}/lib/toolkit/windows_x64/libcrypto-3-x64.dll)
  set(PCAN_DLL ${CMAKE_CURRENT_SOURCE_DIR}/lib/PCAN-Basic/x64/PCANBasic.dll)
  set(PCAN_LIB ${CMAKE_CURRENT_SOURCE_DIR}/lib/PCAN-Basic/x64//VC_LIB/PCANBasic.lib)
elseif(UNIX)
  set(TTCTK_DLL ${CMAKE_CURRENT_SOURCE_DIR}/lib/toolkit/linux_x64/libttctk.so)
  # No PCANBasic linux libs are needed, socketcan will be use instead later.
endif()

## Create IMPORTED shared targets and link those targets so we link shared libs
if(WIN32)
  if(EXISTS ${TTCTK_DLL})
    add_library(ttctk_shared SHARED IMPORTED)
    set_target_properties(ttctk_shared PROPERTIES
      IMPORTED_LOCATION "${TTCTK_DLL}"
      IMPORTED_IMPLIB "${TTCTK_LIB}"
    )
    message(STATUS "Linking TTCTK library (imported target): ${TTCTK_DLL}")
    target_link_libraries(ecu_models PRIVATE ttctk_shared)
  endif()

  if(EXISTS ${PCAN_DLL})
    add_library(pcanbasic_shared SHARED IMPORTED)
    set_target_properties(pcanbasic_shared PROPERTIES
      IMPORTED_LOCATION "${PCAN_DLL}"
      IMPORTED_IMPLIB "${PCAN_LIB}"
    )
    message(STATUS "Linking PCANBasic library (imported target): ${PCAN_DLL}")
    target_link_libraries(ecu_models PRIVATE pcanbasic_shared)
  endif()
else()
if(EXISTS ${TTCTK_DLL})
    add_library(ttctk_shared SHARED IMPORTED)
    set_target_properties(ttctk_shared PROPERTIES
      IMPORTED_LOCATION "${TTCTK_DLL}"
    )
    message(STATUS "Linking TTCTK library (imported target): ${TTCTK_DLL}")
    target_link_libraries(ecu_models PRIVATE ttctk_shared)
  endif()
  # PCANBasic is not used on Unix (socketcan is used instead)
endif()

# Add test executable for the ecu_models library
add_executable(ecu_models_test src/ecu_model_test.cpp)
target_link_libraries(ecu_models_test PRIVATE ecu_models)

include(GNUInstallDirs)

# Location to install the library
## Copy to build for the test executable
if(WIN32 AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/build")
  if(EXISTS ${TTCTK_DLL})
    add_custom_command(TARGET ecu_models_test POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${TTCTK_DLL}" "${CMAKE_CURRENT_SOURCE_DIR}/build"
    )
  endif()
  if(EXISTS ${PCAN_DLL})
    add_custom_command(TARGET ecu_models_test POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${PCAN_DLL}" "${CMAKE_CURRENT_SOURCE_DIR}/build"
    )
  endif()
endif()

set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../..)

## Copy runtime DLLs for Windows to the application runner path if present
if(WIN32 AND EXISTS "${PROJECT_ROOT}/build/windows/x64/runner/Debug")
  if(EXISTS ${TTCTK_DLL})
    add_custom_command(TARGET ecu_models POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${TTCTK_DLL}" "${PROJECT_ROOT}/build/windows/x64/runner/Debug"
    )
  endif()
  if(EXISTS ${PCAN_DLL})
    add_custom_command(TARGET ecu_models POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${PCAN_DLL}" "${PROJECT_ROOT}/build/windows/x64/runner/Debug"
    )
  endif()
  if(EXISTS ${CRYPTO_DLL})
    add_custom_command(TARGET ecu_models POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CRYPTO_DLL}" "${PROJECT_ROOT}/build/windows/x64/runner/Debug"
    )
  endif()
endif()

# TODO Wrong paths in exists and install for macos and linux, need to fix
if(WIN32 AND EXISTS "${PROJECT_ROOT}/build/windows/x64/runner/Debug")
  add_custom_command(TARGET ecu_models POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:ecu_models> "${PROJECT_ROOT}/build/windows/x64/runner/Debug"
  )
elseif(APPLE AND EXISTS "${PROJECT_ROOT}/macos")
  add_custom_command(TARGET ecu_models POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:ecu_models> "${PROJECT_ROOT}/macos/"
  )
elseif(UNIX AND EXISTS "${PROJECT_ROOT}/linux")
  add_custom_command(TARGET ecu_models POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:ecu_models> "${PROJECT_ROOT}/linux/"
  )
endif()
