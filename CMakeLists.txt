cmake_minimum_required(VERSION 3.15)
project(flutter-waygets)


find_package(PkgConfig)

#### Pkgconfig lookup
pkg_search_module(WAYLAND_CLIENT wayland-client REQUIRED)
pkg_search_module(OPENGL opengl REQUIRED)
pkg_search_module(WLROOTS wlroots-0.18 REQUIRED)

find_library(FLUTTER_LIB flutter_engine PATHS ${CMAKE_SOURCE_DIR}/../linux-x64-embedder)


set(SOURCES
    src/main.cc
)

add_executable(flutter-waygets ${SOURCES})

target_link_libraries(flutter-waygets
    ${WAYLAND_CLIENT_LIBS}
    ${OPENGL_LIBS}
    ${WLROOTS_LIBS}
)

target_include_directories(flutter-waygets
    PRIVATE
    ${WAYLAND_CLIENT_INCLUDE_DIRS}
    ${OPENGL_INCLUDE_DIRS}
    ${WLROOTS_INCLUDE_DIRS}
)

target_include_directories(flutter-waygets
    PRIVATE
    ${CMAKE_SOURCE_DIR}/../linux-x64-embedder
)

install(TARGETS flutter-waygets DESTINATION build)

############################################################
# wlr-protocols 
############################################################
#find_package(WLR_PROTOCOLS REQUIRED)

#include_directories(${WLR_PROTOCOLS_INCLUDE_DIRS})
#target_link_libraries(flutter-waygets WLR_PROTOCOLS)
############################################################
# Flutter Engine
############################################################


# This is assuming you've built a local version of the Flutter Engine.  If you
# downloaded yours is from the internet you'll have to change this.
#include_directories(${CMAKE_SOURCE_DIR}/../../shell/platform/embedder)
#find_library(FLUTTER_LIB flutter_engine PATHS ${CMAKE_SOURCE_DIR}/../linux-x64-embedder)
#find_library(FLUTTER_LIB flutter_engine PATHS ${CMAKE_SOURCE_DIR}/../../../out/host_debug_unopt)
#target_link_libraries(flutter-waygets ${FLUTTER_LIB})

# Copy the flutter library here since the shared library
# name is `./libflutter_engine.dylib`.
#add_custom_command(
#        TARGET flutter-waygets POST_BUILD
#        COMMAND ${CMAKE_COMMAND} -E copy
#                ${FLUTTER_LIB}
#                ${CMAKE_CURRENT_BINARY_DIR})
