cmake_minimum_required(VERSION 3.22)

if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW)
endif()

project(SaveReminderSSE VERSION 0.2.3 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC AND NOT DEFINED CMAKE_MSVC_RUNTIME_LIBRARY)
    if(DEFINED VCPKG_TARGET_TRIPLET AND VCPKG_TARGET_TRIPLET MATCHES "-static")
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    else()
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()
endif()

include(FetchContent)

# alandtse's actively maintained CommonLibSSE-NG fork. Pin the exact revision so
# release builds do not silently change when the upstream ng branch advances.
set(ENABLE_SKYRIM_SE ON CACHE BOOL "Enable Skyrim SE support" FORCE)
set(ENABLE_SKYRIM_AE ON CACHE BOOL "Enable Skyrim AE support" FORCE)
set(ENABLE_SKYRIM_VR OFF CACHE BOOL "Enable Skyrim VR support" FORCE)
set(BUILD_TESTS OFF CACHE BOOL "Build CommonLibSSE tests" FORCE)
set(COMMONLIB_ENABLE_IPO OFF CACHE BOOL "Build CommonLibSSE without LTCG" FORCE)

FetchContent_Declare(
    CommonLibSSE
    GIT_REPOSITORY https://github.com/alandtse/CommonLibSSE-NG.git
    GIT_TAG 70c1acd5261210982bd52f6d4468a082fe04d798
    GIT_SHALLOW FALSE
)
FetchContent_MakeAvailable(CommonLibSSE)

add_library(${PROJECT_NAME} SHARED
    src/main.cpp
)

set_target_properties(${PROJECT_NAME} PROPERTIES
    OUTPUT_NAME "SaveReminderSSE"
    PREFIX ""
)

if(MSVC)
    # Keep Release optimizations, but emit symbols for crash debugging/support.
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:/Zi>
    )
    target_link_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:/DEBUG /OPT:REF /OPT:ICF>
    )
endif()

target_include_directories(${PROJECT_NAME}
    PRIVATE
        include
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        CommonLibSSE::CommonLibSSE
)

target_compile_definitions(${PROJECT_NAME}
    PRIVATE
        UNICODE
        _UNICODE
)
