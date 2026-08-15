# LarkDesign NAPI 引擎层
# 构建 HarmonyOS native library (.so) 供 ArkTS 通过 NAPI 调用
#
# 依赖：HarmonyOS NativeDrawing（平台 Skia 后端）与 zlib
# 构建工具：HarmonyOS NDK (CMake 3.22+)
#
# 用法：
#   DevEco Studio 会自动加载本 CMakeLists.txt（通过 entry/build-profile.json5 的 externalNativeOptions）
#   或手动：
#     cd napi && mkdir build && cd build
#     cmake -DOHOS_STL=c++_shared -DCMAKE_TOOLCHAIN_FILE=$OHOS_NDK/build/cmake/ohos.toolchain.cmake ..
#     cmake --build .

cmake_minimum_required(VERSION 3.22)
project(LarkDesignEngine VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ─── 引擎产物名称 ───
# DevEco Studio 中 entry/build-profile.json5 的 externalNativeOptions.abiFilters 控制 ABI
set(ENGINE_NAME lark_engine)

# ─── 源码 ───
file(GLOB_RECURSE ENGINE_SRC
    src/bridge/*.cpp
    src/render/*.cpp
    src/font/*.cpp
    src/export/*.cpp
)

# ─── 头文件 ───
include_directories(
    include
    ${CMAKE_CURRENT_SOURCE_DIR}
)

add_library(${ENGINE_NAME} SHARED ${ENGINE_SRC})

target_link_libraries(${ENGINE_NAME}
    ace_napi.z
    native_drawing
    z
)

# ─── NAPI 导出 ───
# NAPI 注册入口在 bridge/napi_register.cpp
# 无需额外导出符号，NAPI 宏自动处理

# ─── 编译选项 ───
target_compile_options(${ENGINE_NAME} PRIVATE
    -Wall -Wextra -Wno-unused-parameter
    -fvisibility=hidden  # 只导出 NAPI 符号
)

# ─── 安装规则 ───
# DevEco Studio 自动处理 .so 到 libs/ 目录的拷贝
# 手动时：
# install(TARGETS ${ENGINE_NAME} LIBRARY DESTINATION libs/${OHOS_ABI})

message(STATUS "LarkDesign Engine: ${ENGINE_NAME}")
message(STATUS "NativeDrawing: platform Skia backend")
