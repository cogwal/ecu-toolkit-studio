cmake_minimum_required(VERSION 3.10)
project(ecu_models LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
file(GLOB SOURCES "${SRC_DIR}/*.cpp")

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

include(GNUInstallDirs)

add_custom_target(copy_to_runners ALL
  COMMAND ${CMAKE_COMMAND} -E echo "Copying built library to Flutter runner folders (if present)"
)

set(PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../..)

if(EXISTS "${PROJECT_ROOT}/windows")
  add_custom_command(TARGET ecu_models POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:ecu_models> "${PROJECT_ROOT}/windows/"
  )
endif()

if(EXISTS "${PROJECT_ROOT}/linux")
  add_custom_command(TARGET ecu_models POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:ecu_models> "${PROJECT_ROOT}/linux/"
  )
endif()

if(EXISTS "${PROJECT_ROOT}/macos")
  add_custom_command(TARGET ecu_models POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:ecu_models> "${PROJECT_ROOT}/macos/"
  )
endif()
