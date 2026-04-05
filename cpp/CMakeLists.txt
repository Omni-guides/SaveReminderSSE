cmake_minimum_required(VERSION 3.22)

if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW)
endif()

project(SaveReminderSSE VERSION 0.1.4 LANGUAGES CXX)

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

find_package(CommonLibSSE CONFIG REQUIRED)

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
