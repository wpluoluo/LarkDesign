/**
 * napi_register.cpp - NAPI 模块注册入口
 *
 * ArkTS 侧通过 import nativeEngine from "lark_engine" 加载本模块。
 * 注册所有 NAPI 函数，调用 lark_engine.h 的 C ABI 实现。
 */

#include <napi/native_api.h>
#include "../include/lark_engine.h"
#include <cstring>
#include <cstdint>

// ─── 引擎实例（单例） ───
static LarkEngine* g_engine = nullptr;

static LarkEngine* ensure_engine() {
    if (!g_engine) {
        g_engine = lark_engine_create();
    }
    return g_engine;
}

static bool get_handle(napi_env env, napi_value value, int64_t* out) {
    if (value == nullptr || out == nullptr) return false;
    bool lossless = false;
    if (napi_get_value_bigint_int64(env, value, out, &lossless) != napi_ok || !lossless || *out == 0) {
        napi_throw_type_error(env, nullptr, "expected a non-zero native handle");
        return false;
    }
    return true;
}

static bool require_args(napi_env env, size_t argc, size_t expected, const char* name) {
    if (argc >= expected) return true;
    napi_throw_type_error(env, nullptr, name);
    return false;
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

    if (!require_args(env, argc, 2, "createCanvas requires width and height")) return nullptr;
    int32_t width = 0, height = 0;
    if (napi_get_value_int32(env, args[0], &width) != napi_ok ||
        napi_get_value_int32(env, args[1], &height) != napi_ok) {
        napi_throw_type_error(env, nullptr, "canvas dimensions must be integers");
        return nullptr;
    }

    LarkRenderTarget target = { width, height, 72.0f, 0xFFFFFFFF };
    LarkCanvas* canvas = lark_canvas_create(ensure_engine(), &target);
    if (canvas == nullptr) {
        napi_throw_error(env, nullptr, "failed to create native canvas");
        return nullptr;
    }

    napi_value result;
    napi_create_bigint_int64(env, (int64_t)(intptr_t)canvas, &result);
    return result;
}

static napi_value NapiDestroyCanvas(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (!require_args(env, argc, 1, "destroyCanvas requires a canvas handle")) return nullptr;
    int64_t ptr = 0;
    if (!get_handle(env, args[0], &ptr)) return nullptr;
    lark_canvas_destroy((LarkCanvas*)(intptr_t)ptr);
    return nullptr;
}

static napi_value NapiClearCanvas(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (!require_args(env, argc, 2, "clearCanvas requires a canvas handle and color")) return nullptr;
    int64_t ptr = 0;
    if (!get_handle(env, args[0], &ptr)) return nullptr;
    uint32_t color = 0;
    if (napi_get_value_uint32(env, args[1], &color) != napi_ok) {
        napi_throw_type_error(env, nullptr, "color must be an unsigned integer");
        return nullptr;
    }
    lark_canvas_clear((LarkCanvas*)(intptr_t)ptr, color);
    return nullptr;
}

static napi_value NapiDrawRect(napi_env env, napi_callback_info info) {
    size_t argc = 8;
    napi_value args[8];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (argc < 8) {
        napi_throw_error(env, nullptr, "drawRect requires 8 arguments");
        return nullptr;
    }

    int64_t ptr = 0;
    if (!get_handle(env, args[0], &ptr)) return nullptr;
    LarkCanvas* canvas = (LarkCanvas*)(intptr_t)ptr;

    double x, y, w, h, sw;
    uint32_t fill, stroke;
    if (napi_get_value_double(env, args[1], &x) != napi_ok ||
        napi_get_value_double(env, args[2], &y) != napi_ok ||
        napi_get_value_double(env, args[3], &w) != napi_ok ||
        napi_get_value_double(env, args[4], &h) != napi_ok ||
        napi_get_value_uint32(env, args[5], &fill) != napi_ok ||
        napi_get_value_double(env, args[6], &sw) != napi_ok ||
        napi_get_value_uint32(env, args[7], &stroke) != napi_ok) {
        napi_throw_type_error(env, nullptr, "drawRect arguments have invalid types");
        return nullptr;
    }

    LarkRect rect = { (float)x, (float)y, (float)w, (float)h };
    lark_canvas_draw_rect(canvas, &rect, fill, (float)sw, stroke);
    return nullptr;
}

static napi_value NapiDrawText(napi_env env, napi_callback_info info) {
    size_t argc = 6;
    napi_value args[6];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (!require_args(env, argc, 6, "drawText requires 6 arguments")) return nullptr;
    int64_t ptr = 0;
    if (!get_handle(env, args[0], &ptr)) return nullptr;
    LarkCanvas* canvas = (LarkCanvas*)(intptr_t)ptr;

    char text[1024];
    size_t textLen;
    if (napi_get_value_string_utf8(env, args[1], text, sizeof(text), &textLen) != napi_ok) {
        napi_throw_type_error(env, nullptr, "text must be a string");
        return nullptr;
    }

    double x, y, size;
    uint32_t color;
    if (napi_get_value_double(env, args[2], &x) != napi_ok ||
        napi_get_value_double(env, args[3], &y) != napi_ok ||
        napi_get_value_double(env, args[4], &size) != napi_ok ||
        napi_get_value_uint32(env, args[5], &color) != napi_ok) {
        napi_throw_type_error(env, nullptr, "drawText arguments have invalid types");
        return nullptr;
    }

    lark_canvas_draw_text(canvas, text, (float)x, (float)y, (float)size, color, nullptr);
    return nullptr;
}

static napi_value NapiDrawRoundRect(napi_env env, napi_callback_info info) {
    size_t argc = 10;
    napi_value args[10];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (!require_args(env, argc, 10, "drawRoundRect requires 10 arguments")) return nullptr;
    int64_t ptr = 0;
    if (!get_handle(env, args[0], &ptr)) return nullptr;
    double x = 0, y = 0, w = 0, h = 0, rx = 0, ry = 0, sw = 0;
    uint32_t fill = 0, stroke = 0;
    if (napi_get_value_double(env, args[1], &x) != napi_ok ||
        napi_get_value_double(env, args[2], &y) != napi_ok ||
        napi_get_value_double(env, args[3], &w) != napi_ok ||
        napi_get_value_double(env, args[4], &h) != napi_ok ||
        napi_get_value_double(env, args[5], &rx) != napi_ok ||
        napi_get_value_double(env, args[6], &ry) != napi_ok ||
        napi_get_value_uint32(env, args[7], &fill) != napi_ok ||
        napi_get_value_double(env, args[8], &sw) != napi_ok) {
        napi_throw_type_error(env, nullptr, "drawRoundRect arguments have invalid types");
        return nullptr;
    }
    if (napi_get_value_uint32(env, args[9], &stroke) != napi_ok) {
        napi_throw_type_error(env, nullptr, "stroke color must be an unsigned integer");
        return nullptr;
    }
    LarkRect rect = { static_cast<float>(x), static_cast<float>(y), static_cast<float>(w), static_cast<float>(h) };
    lark_canvas_draw_round_rect(reinterpret_cast<LarkCanvas*>(static_cast<intptr_t>(ptr)), &rect,
        static_cast<float>(rx), static_cast<float>(ry), fill, static_cast<float>(sw), stroke);
    return nullptr;
}

static napi_value NapiDrawEllipse(napi_env env, napi_callback_info info) {
    size_t argc = 8;
    napi_value args[8];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (!require_args(env, argc, 8, "drawEllipse requires 8 arguments")) return nullptr;
    int64_t ptr = 0;
    if (!get_handle(env, args[0], &ptr)) return nullptr;
    double x = 0, y = 0, w = 0, h = 0, sw = 0;
    uint32_t fill = 0, stroke = 0;
    if (napi_get_value_double(env, args[1], &x) != napi_ok ||
        napi_get_value_double(env, args[2], &y) != napi_ok ||
        napi_get_value_double(env, args[3], &w) != napi_ok ||
        napi_get_value_double(env, args[4], &h) != napi_ok ||
        napi_get_value_uint32(env, args[5], &fill) != napi_ok ||
        napi_get_value_double(env, args[6], &sw) != napi_ok) {
        napi_throw_type_error(env, nullptr, "drawEllipse arguments have invalid types");
        return nullptr;
    }
    if (napi_get_value_uint32(env, args[7], &stroke) != napi_ok) {
        napi_throw_type_error(env, nullptr, "stroke color must be an unsigned integer");
        return nullptr;
    }
    LarkRect rect = { static_cast<float>(x), static_cast<float>(y), static_cast<float>(w), static_cast<float>(h) };
    lark_canvas_draw_ellipse(reinterpret_cast<LarkCanvas*>(static_cast<intptr_t>(ptr)), &rect, fill,
        static_cast<float>(sw), stroke);
    return nullptr;
}

static napi_value NapiGetCapabilities(napi_env env, napi_callback_info info) {
    (void)info;
    napi_value result;
    napi_create_uint32(env, lark_engine_capabilities(ensure_engine()), &result);
    return result;
}

static napi_value NapiGetPixels(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (!require_args(env, argc, 1, "getPixels requires a canvas handle")) return nullptr;
    int64_t ptr = 0;
    if (!get_handle(env, args[0], &ptr)) return nullptr;
    size_t length = 0;
    const uint8_t* pixels = lark_canvas_pixels(reinterpret_cast<LarkCanvas*>(static_cast<intptr_t>(ptr)), &length);
    if (pixels == nullptr || length == 0) {
        napi_throw_error(env, nullptr, "native canvas has no readable pixels");
        return nullptr;
    }
    void* destination = nullptr;
    napi_value result;
    if (napi_create_arraybuffer(env, length, &destination, &result) != napi_ok || destination == nullptr) {
        napi_throw_error(env, nullptr, "failed to allocate pixel buffer");
        return nullptr;
    }
    std::memcpy(destination, pixels, length);
    return result;
}

static napi_value NapiExportPng(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (!require_args(env, argc, 1, "exportPng requires a canvas handle")) return nullptr;
    int64_t ptr = 0;
    if (!get_handle(env, args[0], &ptr)) return nullptr;
    LarkExportJob* job = lark_export_create(ensure_engine(),
        reinterpret_cast<LarkCanvas*>(static_cast<intptr_t>(ptr)), LARK_FORMAT_PNG, 100);
    if (job == nullptr) {
        napi_throw_error(env, nullptr, "failed to create PNG export job");
        return nullptr;
    }
    size_t length = 0;
    const uint8_t* data = lark_export_buffer(job, &length);
    void* destination = nullptr;
    napi_value result = nullptr;
    if (data == nullptr || length == 0 || napi_create_arraybuffer(env, length, &destination, &result) != napi_ok || destination == nullptr) {
        lark_export_destroy(job);
        napi_throw_error(env, nullptr, "failed to encode PNG");
        return nullptr;
    }
    std::memcpy(destination, data, length);
    lark_export_destroy(job);
    return result;
}

// ─── 模块注册 ───

static napi_value RegisterModule(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "getVersion", nullptr, NapiGetVersion, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCapabilities", nullptr, NapiGetCapabilities, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "createCanvas", nullptr, NapiCreateCanvas, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyCanvas", nullptr, NapiDestroyCanvas, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "clearCanvas", nullptr, NapiClearCanvas, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "drawRect", nullptr, NapiDrawRect, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "drawRoundRect", nullptr, NapiDrawRoundRect, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "drawEllipse", nullptr, NapiDrawEllipse, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "drawText", nullptr, NapiDrawText, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getPixels", nullptr, NapiGetPixels, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "exportPng", nullptr, NapiExportPng, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(lark_engine, RegisterModule)
