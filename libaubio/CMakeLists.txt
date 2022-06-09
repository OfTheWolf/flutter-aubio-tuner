# Specify the minimum version.
cmake_minimum_required(VERSION 3.9)

# Specify the project info.
project(aubio VERSION 1.0.0 DESCRIPTION "A library for audio and music analysis")

include_directories(${PROJECT_SOURCE_DIR})
include_directories(${PROJECT_SOURCE_DIR}/include)
#file(GLOB sources ${PROJECT_SOURCE_DIR}/*.c ${PROJECT_SOURCE_DIR}/include/*.c)
file(GLOB_RECURSE sources "*.c" "*.h")
foreach (filename ${sources})
    message(STATUS "filename: ${filename}")
endforeach()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHAVE_CONFIG_H")

# Declare the library target.
add_library(${PROJECT_NAME} SHARED
    ${sources}
)

## Configure the directories to search for header files.
#target_include_directories(${PROJECT_NAME} PRIVATE source)
#
## Set the version property.
#set_target_properties(${PROJECT_NAME} PROPERTIES VERSION ${PROJECT_VERSION})
#
## Set the shared object version property to the project's major version.
#set_target_properties(${PROJECT_NAME} PROPERTIES SOVERSION ${PROJECT_VERSION_MAJOR})
#
## Set the public header property to the one with the actual API.
#set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER source/convert.h)