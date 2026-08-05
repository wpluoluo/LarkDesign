/**
 * napi_register.cpp - NAPI 模块注册入口
 *
 * ArkTS 侧通过 import nativeEngine from "lark_engine" 加载本模块。
 * 注册所有 NAPI 函数，调用 lark_engine.h 的 C ABI 实现。
 */

#include <napi/native_api.h>
#include <napi/native_node.h>
#include "../include/lark_engine.h"

// ─── 引擎实例（单例） ───
static LarkEngine* g_engine = nullptr;

static LarkEngine* ensure_engine() {
    if (!g_engine) {
        g_engine = lark_engine_create();
    }
    return g_engine;
}

// ─── NAPI 函数实现 ───

static napi_value NapiGetVersion(napi_env env, napi_callback_info info) {
    napi_value result;
    const char* ver = lark_engine_version_string();
    napi_create_string_utf8(env, ver, NAPI_AUTO_LENGTH, &result);
    return result;
}

static napi_value NapiCreateCanvas(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int32_t width, height;
    napi_get_value_int32(env, args[0], &width);
    napi_get_value_int32(env, args[1], &height);

    LarkRenderTarget target = { width, height, 72.0f, 0xFFFFFFFF };
    LarkCanvas* canvas = lark_canvas_create(ensure_engine(), &target);

    napi_value result;
    napi_create_bigint_int64(env, (int64_t)(intptr_t)canvas, &result);
    return result;
}

static napi_value NapiDestroyCanvas(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t ptr;
    bool lossless;
    napi_get_value_bigint_int64(env, args[0], &ptr, &lossless);
    lark_canvas_destroy((LarkCanvas*)(intptr_t)ptr);
    return nullptr;
}

static napi_value NapiClearCanvas(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t ptr;
    bool lossless;
    napi_get_value_bigint_int64(env, args[0], &ptr, &lossless);
    uint32_t color;
    napi_get_value_uint32(env, args[1], &color);
    lark_canvas_clear((LarkCanvas*)(intptr_t)ptr, color);
    return nullptr;
}

static napi_value NapiDrawRect(napi_env env, napi_callback_info info) {
    size_t argc = 6;
    napi_value args[6];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t ptr; bool lossless;
    napi_get_value_bigint_int64(env, args[0], &ptr, &lossless);
    LarkCanvas* canvas = (LarkCanvas*)(intptr_t)ptr;

    double x, y, w, h, sw;
    uint32_t fill, stroke;
    napi_get_value_double(env, args[1], &x);
    napi_get_value_double(env, args[2], &y);
    napi_get_value_double(env, args[3], &w);
    napi_get_value_double(env, args[4], &h);
    napi_get_value_uint32(env, args[5], &fill);
    napi_get_value_double(env, args[6], &sw);
    napi_get_value_uint32(env, args[7], &stroke);

    LarkRect rect = { (float)x, (float)y, (float)w, (float)h };
    lark_canvas_draw_rect(canvas, &rect, fill, (float)sw, stroke);
    return nullptr;
}

static napi_value NapiDrawText(napi_env env, napi_callback_info info) {
    size_t argc = 6;
    napi_value args[6];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    int64_t ptr; bool lossless;
    napi_get_value_bigint_int64(env, args[0], &ptr, &lossless);
    LarkCanvas* canvas = (LarkCanvas*)(intptr_t)ptr;

    char text[1024];
    size_t textLen;
    napi_get_value_string_utf8(env, args[1], text, sizeof(text), &textLen);

    double x, y, size;
    uint32_t color;
    napi_get_value_double(env, args[2], &x);
    napi_get_value_double(env, args[3], &y);
    napi_get_value_double(env, args[4], &size);
    napi_get_value_uint32(env, args[5], &color);

    lark_canvas_draw_text(canvas, text, (float)x, (float)y, (float)size, color, nullptr);
    return nullptr;
}

// ─── 模块注册 ───

static napi_value RegisterModule(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "getVersion", nullptr, NapiGetVersion, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "createCanvas", nullptr, NapiCreateCanvas, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyCanvas", nullptr, NapiDestroyCanvas, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "clearCanvas", nullptr, NapiClearCanvas, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "drawRect", nullptr, NapiDrawRect, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "drawText", nullptr, NapiDrawText, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(lark_engine, RegisterModule)
