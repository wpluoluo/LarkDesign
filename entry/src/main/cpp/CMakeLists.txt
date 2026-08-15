cmake_minimum_required(VERSION 3.22)
project(LarkDesignEntryNative)

# Keep the C++ implementation in napi/ while exposing a standard module-local
# CMake entry point that Hvigor can discover and package for each ABI.
add_subdirectory(
    "${CMAKE_CURRENT_LIST_DIR}/../../../../napi"
    "${CMAKE_CURRENT_BINARY_DIR}/lark_engine"
)
