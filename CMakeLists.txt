cmake_minimum_required(VERSION 3.5)

project(dylib_dobby_hook)

enable_language(ASM)
enable_language(C)
enable_language(CXX)
enable_language(OBJC)
enable_language(OBJCXX)


set(CMAKE_C_STANDARD 17)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu17")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++20")


set(COMPILE_OPTION
        -Wno-int-conversion
        -Wno-nullability-completeness
        -Wno-incompatible-pointer-types
        -Wno-int-to-void-pointer-cast
        -Wno-unguarded-availability-new 
)

set(LINK_OPTION
        -Xlinker
        -x
)

set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
set(CMAKE_OSX_DEPLOYMENT_TARGET "14.2")

file(GLOB Main ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/*.m)
file(GLOB MainHeader ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/*.h)

file(GLOB Utils
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/utils/*.m
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/utils/*.c
)
file(GLOB UtilsHeader ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/utils/*.h)

file(GLOB Apps ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/apps/*.m)
file(GLOB AppsHeader ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/apps/*.h)

file(GLOB Helpers ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/helpers/*.m)
file(GLOB HelpersHeader ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/helpers/*.h)

file(GLOB StaticLibs ${CMAKE_SOURCE_DIR}/libs/*.a)

include_directories(
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/apps
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/helpers
        ${CMAKE_SOURCE_DIR}/dylib_dobby_hook/utils
)

add_library(${PROJECT_NAME} SHARED
        ${Main}
        ${MainHeader}
        ${UtilsHeader}
        ${AppsHeader}
        ${HelpersHeader}
        ${Utils}
        ${Apps}
        ${Helpers}
)
set_target_properties(${PROJECT_NAME} PROPERTIES
        
        EXECUTABLE_PREFIX "lib"
        EXECUTABLE_EXTENSION "dylib"
        XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH[variant=Debug] "YES"
        XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH[variant=Release] "NO"
        
        XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Debug] "dwarf"
        XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Release] "dwarf-with-dsym"
        XCODE_ATTRIBUTE_SKIP_INSTALL "YES"
        XCODE_ATTRIBUTE_DYLIB_INSTALL_NAME_BASE "$(INSTALL_PATH)"
        XCODE_ATTRIBUTE_LD_DYLIB_INSTALL_NAME "$(DYLIB_INSTALL_NAME_BASE:standardizepath)/$(EXECUTABLE_PATH)"
        XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS "@executable_path/"
        XCODE_ATTRIBUTE_DYLIB_COMPATIBILITY_VERSION "1"
        XCODE_ATTRIBUTE_DYLIB_CURRENT_VERSION "1"
        XCODE_ATTRIBUTE_CLANG_GCC_C_LANGUAGE_STANDARD "gnu17"
        XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "gnu++20"
        XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++"
        XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES "YES"
        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "No"
        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_WEAK "YES"
        XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS "YES"

)

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

target_compile_options(${PROJECT_NAME} PRIVATE ${COMPILE_OPTION})

target_link_options(${PROJECT_NAME} PRIVATE ${LINK_OPTION})
target_link_libraries(${PROJECT_NAME} PUBLIC
        "-framework Foundation"
        "-framework CoreFoundation"
        "-framework AppKit"
        "-framework Cocoa"
        "-framework IOKit"
        "-framework CloudKit"
        "-framework Security"
        "-framework CoreWLAN"
        objc
        c++
        c
        ${StaticLibs}
)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_definitions(-DDEBUG)
elseif (CMAKE_BUILD_TYPE STREQUAL "Release")
else ()
endif ()
install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_SOURCE_DIR}/release)
