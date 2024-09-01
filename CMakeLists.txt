cmake_minimum_required(VERSION 3.15)
PROJECT(FlutterEmbedderWayland)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11" )


add_executable(flutter-waygets FlutterEmbedderWayland.cc)
############################################################
# OPENGL
############################################################
find_package(OpenGL REQUIRED COMPONENTS EGL)
include_directories(${OPENGL_INCLUDE_DIRS})
target_link_libraries(flutter-waygets OpenGL::EGL)


############################################################
# wlr-protocols 
############################################################
find_package(WLR_PROTOCOLS REQUIRED)
include_directories(${WLR_PROTOCOLS_INCLUDE_DIRS})
target_link_libraries(flutter-waygets WLR_PROTOCOLS)
############################################################
# Flutter Engine
############################################################


# This is assuming you've built a local version of the Flutter Engine.  If you
# downloaded yours is from the internet you'll have to change this.
#include_directories(${CMAKE_SOURCE_DIR}/../../shell/platform/embedder)
include_directories(/usr/lib/flutter_embedder)
find_library(FLUTTER_LIB flutter_engine PATHS ${CMAKE_SOURCE_DIR}/../linux-x64-embedder) 
#find_library(FLUTTER_LIB flutter_engine PATHS ${CMAKE_SOURCE_DIR}/../../../out/host_debug_unopt)
target_link_libraries(flutter-waygets ${FLUTTER_LIB})

# Copy the flutter library here since the shared library
# name is `./libflutter_engine.dylib`.
#add_custom_command(
#        TARGET flutter-waygets POST_BUILD
#        COMMAND ${CMAKE_COMMAND} -E copy
#                ${FLUTTER_LIB}
#                ${CMAKE_CURRENT_BINARY_DIR})
