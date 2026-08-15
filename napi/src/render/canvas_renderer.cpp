/**
 * canvas_renderer.cpp - HarmonyOS NativeDrawing/Skia-backed renderer.
 *
 * NativeDrawing is the supported public HarmonyOS drawing ABI and is backed
 * by the platform Skia renderer. Keeping this adapter on the platform ABI
 * avoids shipping an unverified desktop Skia binary into the HAP.
 */

#include "../include/lark_engine.h"
#include <native_drawing/drawing_bitmap.h>
#include <native_drawing/drawing_brush.h>
#include <native_drawing/drawing_canvas.h>
#include <native_drawing/drawing_color.h>
#include <native_drawing/drawing_font.h>
#include <native_drawing/drawing_matrix.h>
#include <native_drawing/drawing_pen.h>
#include <native_drawing/drawing_rect.h>
#include <native_drawing/drawing_round_rect.h>
#include <native_drawing/drawing_text_blob.h>
#include <zlib.h>

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

struct LarkCanvas {
    OH_Drawing_Bitmap* bitmap = nullptr;
    OH_Drawing_Canvas* canvas = nullptr;
    int32_t width = 0;
    int32_t height = 0;
    float dpi = 72.0f;
    std::vector<uint8_t> pixels;
};

namespace {

struct DrawingBrush {
    OH_Drawing_Brush* value;
    explicit DrawingBrush(uint32_t color) : value(OH_Drawing_BrushCreate()) {
        if (value != nullptr) {
            OH_Drawing_BrushSetColor(value, color);
            OH_Drawing_BrushSetAntiAlias(value, true);
        }
    }
    ~DrawingBrush() { if (value != nullptr) OH_Drawing_BrushDestroy(value); }
};

struct DrawingPen {
    OH_Drawing_Pen* value;
    DrawingPen(uint32_t color, float width) : value(OH_Drawing_PenCreate()) {
        if (value != nullptr) {
            OH_Drawing_PenSetColor(value, color);
            OH_Drawing_PenSetWidth(value, width);
            OH_Drawing_PenSetAntiAlias(value, true);
        }
    }
    ~DrawingPen() { if (value != nullptr) OH_Drawing_PenDestroy(value); }
};

void copyPixels(LarkCanvas* canvas) {
    if (canvas == nullptr || canvas->bitmap == nullptr) return;
    const size_t byteCount = static_cast<size_t>(canvas->width) * static_cast<size_t>(canvas->height) * 4u;
    canvas->pixels.resize(byteCount);
    OH_Drawing_Image_Info info = {
        canvas->width,
        canvas->height,
        COLOR_FORMAT_RGBA_8888,
        ALPHA_FORMAT_UNPREMUL,
    };
    if (!OH_Drawing_BitmapReadPixels(canvas->bitmap, &info, canvas->pixels.data(),
                                    static_cast<size_t>(canvas->width) * 4u, 0, 0)) {
        canvas->pixels.clear();
    }
}

void writeU32(std::vector<uint8_t>& out, uint32_t value) {
    out.push_back(static_cast<uint8_t>((value >> 24u) & 0xffu));
    out.push_back(static_cast<uint8_t>((value >> 16u) & 0xffu));
    out.push_back(static_cast<uint8_t>((value >> 8u) & 0xffu));
    out.push_back(static_cast<uint8_t>(value & 0xffu));
}

void writeChunk(std::vector<uint8_t>& out, const char type[4], const std::vector<uint8_t>& data) {
    writeU32(out, static_cast<uint32_t>(data.size()));
    const size_t typeOffset = out.size();
    out.insert(out.end(), type, type + 4);
    out.insert(out.end(), data.begin(), data.end());
    const uint32_t crc = crc32(0L, out.data() + typeOffset, static_cast<uInt>(4u + data.size()));
    writeU32(out, crc);
}

std::shared_ptr<std::vector<uint8_t>> encodePng(const LarkCanvas* canvas) {
    if (canvas == nullptr || canvas->pixels.empty() || canvas->width <= 0 || canvas->height <= 0) {
        return nullptr;
    }
    const size_t rowSize = static_cast<size_t>(canvas->width) * 4u;
    std::vector<uint8_t> raw(static_cast<size_t>(canvas->height) * (rowSize + 1u));
    for (int32_t y = 0; y < canvas->height; ++y) {
        const size_t rawOffset = static_cast<size_t>(y) * (rowSize + 1u);
        raw[rawOffset] = 0;
        std::memcpy(raw.data() + rawOffset + 1u,
                    canvas->pixels.data() + static_cast<size_t>(y) * rowSize, rowSize);
    }
    uLongf compressedSize = compressBound(static_cast<uLong>(raw.size()));
    std::vector<uint8_t> compressed(compressedSize);
    if (compress2(compressed.data(), &compressedSize, raw.data(), static_cast<uLong>(raw.size()), Z_BEST_SPEED) != Z_OK) {
        return nullptr;
    }
    compressed.resize(compressedSize);

    auto png = std::make_shared<std::vector<uint8_t>>();
    png->insert(png->end(), { 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a });
    std::vector<uint8_t> header;
    writeU32(header, static_cast<uint32_t>(canvas->width));
    writeU32(header, static_cast<uint32_t>(canvas->height));
    header.insert(header.end(), { 8, 6, 0, 0, 0 });
    writeChunk(*png, "IHDR", header);
    writeChunk(*png, "IDAT", compressed);
    writeChunk(*png, "IEND", {});
    return png;
}

} // namespace

LarkCanvas* lark_canvas_create(LarkEngine* engine, const LarkRenderTarget* target) {
    (void)engine;
    if (target == nullptr || target->width <= 0 || target->height <= 0 ||
        target->width > 16384 || target->height > 16384) return nullptr;
    auto canvas = std::make_unique<LarkCanvas>();
    canvas->width = target->width;
    canvas->height = target->height;
    canvas->dpi = target->dpi > 0 ? target->dpi : 72.0f;
    canvas->bitmap = OH_Drawing_BitmapCreate();
    canvas->canvas = OH_Drawing_CanvasCreate();
    if (canvas->bitmap == nullptr || canvas->canvas == nullptr) {
        if (canvas->canvas != nullptr) OH_Drawing_CanvasDestroy(canvas->canvas);
        if (canvas->bitmap != nullptr) OH_Drawing_BitmapDestroy(canvas->bitmap);
        return nullptr;
    }
    OH_Drawing_BitmapFormat format = { COLOR_FORMAT_RGBA_8888, ALPHA_FORMAT_PREMUL };
    OH_Drawing_BitmapBuild(canvas->bitmap, canvas->width, canvas->height, &format);
    OH_Drawing_CanvasBind(canvas->canvas, canvas->bitmap);
    lark_canvas_clear(canvas.get(), target->background_color);
    copyPixels(canvas.get());
    return canvas.release();
}

void lark_canvas_destroy(LarkCanvas* canvas) {
    if (canvas == nullptr) return;
    if (canvas->canvas != nullptr) OH_Drawing_CanvasDestroy(canvas->canvas);
    if (canvas->bitmap != nullptr) OH_Drawing_BitmapDestroy(canvas->bitmap);
    delete canvas;
}

void lark_canvas_clear(LarkCanvas* canvas, uint32_t color) {
    if (canvas == nullptr || canvas->canvas == nullptr) return;
    OH_Drawing_CanvasDrawColor(canvas->canvas, color, BLEND_MODE_SRC);
}

void lark_canvas_draw_rect(LarkCanvas* canvas, const LarkRect* rect,
                           uint32_t fill_color, float stroke_width, uint32_t stroke_color) {
    if (canvas == nullptr || canvas->canvas == nullptr || rect == nullptr) return;
    OH_Drawing_Rect* nativeRect = OH_Drawing_RectCreate(rect->x, rect->y,
        rect->x + rect->width, rect->y + rect->height);
    if (nativeRect == nullptr) return;
    DrawingBrush brush(fill_color);
    if (brush.value != nullptr) {
        OH_Drawing_CanvasAttachBrush(canvas->canvas, brush.value);
        OH_Drawing_CanvasDrawRect(canvas->canvas, nativeRect);
        OH_Drawing_CanvasDetachBrush(canvas->canvas);
    }
    if (stroke_width > 0) {
        DrawingPen pen(stroke_color, stroke_width);
        if (pen.value != nullptr) {
            OH_Drawing_CanvasAttachPen(canvas->canvas, pen.value);
            OH_Drawing_CanvasDrawRect(canvas->canvas, nativeRect);
            OH_Drawing_CanvasDetachPen(canvas->canvas);
        }
    }
    OH_Drawing_RectDestroy(nativeRect);
    copyPixels(canvas);
}

void lark_canvas_draw_round_rect(LarkCanvas* canvas, const LarkRect* rect,
                                 float rx, float ry, uint32_t fill_color,
                                 float stroke_width, uint32_t stroke_color) {
    if (canvas == nullptr || canvas->canvas == nullptr || rect == nullptr) return;
    OH_Drawing_Rect* nativeRect = OH_Drawing_RectCreate(rect->x, rect->y,
        rect->x + rect->width, rect->y + rect->height);
    OH_Drawing_RoundRect* roundRect = nativeRect == nullptr ? nullptr :
        OH_Drawing_RoundRectCreate(nativeRect, std::max(0.0f, rx), std::max(0.0f, ry));
    if (roundRect == nullptr) {
        if (nativeRect != nullptr) OH_Drawing_RectDestroy(nativeRect);
        return;
    }
    DrawingBrush brush(fill_color);
    if (brush.value != nullptr) {
        OH_Drawing_CanvasAttachBrush(canvas->canvas, brush.value);
        OH_Drawing_CanvasDrawRoundRect(canvas->canvas, roundRect);
        OH_Drawing_CanvasDetachBrush(canvas->canvas);
    }
    if (stroke_width > 0) {
        DrawingPen pen(stroke_color, stroke_width);
        if (pen.value != nullptr) {
            OH_Drawing_CanvasAttachPen(canvas->canvas, pen.value);
            OH_Drawing_CanvasDrawRoundRect(canvas->canvas, roundRect);
            OH_Drawing_CanvasDetachPen(canvas->canvas);
        }
    }
    OH_Drawing_RoundRectDestroy(roundRect);
    OH_Drawing_RectDestroy(nativeRect);
    copyPixels(canvas);
}

void lark_canvas_draw_ellipse(LarkCanvas* canvas, const LarkRect* rect,
                              uint32_t fill_color, float stroke_width, uint32_t stroke_color) {
    if (canvas == nullptr || canvas->canvas == nullptr || rect == nullptr) return;
    OH_Drawing_Rect* nativeRect = OH_Drawing_RectCreate(rect->x, rect->y,
        rect->x + rect->width, rect->y + rect->height);
    if (nativeRect == nullptr) return;
    DrawingBrush brush(fill_color);
    if (brush.value != nullptr) {
        OH_Drawing_CanvasAttachBrush(canvas->canvas, brush.value);
        OH_Drawing_CanvasDrawOval(canvas->canvas, nativeRect);
        OH_Drawing_CanvasDetachBrush(canvas->canvas);
    }
    if (stroke_width > 0) {
        DrawingPen pen(stroke_color, stroke_width);
        if (pen.value != nullptr) {
            OH_Drawing_CanvasAttachPen(canvas->canvas, pen.value);
            OH_Drawing_CanvasDrawOval(canvas->canvas, nativeRect);
            OH_Drawing_CanvasDetachPen(canvas->canvas);
        }
    }
    OH_Drawing_RectDestroy(nativeRect);
    copyPixels(canvas);
}

void lark_canvas_draw_text(LarkCanvas* canvas, const char* text,
                           float x, float y, float size, uint32_t color,
                           LarkTypeface* typeface) {
    (void)typeface;
    if (canvas == nullptr || canvas->canvas == nullptr || text == nullptr || text[0] == '\0' || size <= 0) return;
    OH_Drawing_Font* font = OH_Drawing_FontCreate();
    if (font != nullptr) OH_Drawing_FontSetTextSize(font, size);
    OH_Drawing_TextBlob* blob = font == nullptr ? nullptr :
        OH_Drawing_TextBlobCreateFromString(text, font, TEXT_ENCODING_UTF8);
    DrawingBrush brush(color);
    if (blob != nullptr && brush.value != nullptr) {
        OH_Drawing_CanvasAttachBrush(canvas->canvas, brush.value);
        OH_Drawing_CanvasDrawTextBlob(canvas->canvas, blob, x, y);
        OH_Drawing_CanvasDetachBrush(canvas->canvas);
    }
    if (blob != nullptr) OH_Drawing_TextBlobDestroy(blob);
    if (font != nullptr) OH_Drawing_FontDestroy(font);
    copyPixels(canvas);
}

void lark_canvas_draw_image(LarkCanvas* canvas, LarkImage* image,
                            const LarkRect* rect, float opacity) {
    (void)canvas;
    (void)image;
    (void)rect;
    (void)opacity;
}

void lark_canvas_set_transform(LarkCanvas* canvas, const LarkMatrix* matrix) {
    if (canvas == nullptr || canvas->canvas == nullptr || matrix == nullptr) return;
    OH_Drawing_Matrix* nativeMatrix = OH_Drawing_MatrixCreate();
    if (nativeMatrix == nullptr) return;
    OH_Drawing_MatrixSetMatrix(nativeMatrix, matrix->scaleX, matrix->skewX, matrix->transX,
                               matrix->skewY, matrix->scaleY, matrix->transY, 0, 0, 1);
    OH_Drawing_CanvasSetMatrix(canvas->canvas, nativeMatrix);
    OH_Drawing_MatrixDestroy(nativeMatrix);
}

void lark_canvas_reset_transform(LarkCanvas* canvas) {
    if (canvas != nullptr && canvas->canvas != nullptr) OH_Drawing_CanvasResetMatrix(canvas->canvas);
}

void lark_canvas_save(LarkCanvas* canvas) {
    if (canvas != nullptr && canvas->canvas != nullptr) OH_Drawing_CanvasSave(canvas->canvas);
}

void lark_canvas_restore(LarkCanvas* canvas) {
    if (canvas != nullptr && canvas->canvas != nullptr) OH_Drawing_CanvasRestore(canvas->canvas);
}

const uint8_t* lark_canvas_pixels(LarkCanvas* canvas, size_t* out_len) {
    if (out_len != nullptr) *out_len = 0;
    if (canvas == nullptr) return nullptr;
    copyPixels(canvas);
    if (out_len != nullptr) *out_len = canvas->pixels.size();
    return canvas->pixels.empty() ? nullptr : canvas->pixels.data();
}

int32_t lark_canvas_width(const LarkCanvas* canvas) { return canvas == nullptr ? 0 : canvas->width; }
int32_t lark_canvas_height(const LarkCanvas* canvas) { return canvas == nullptr ? 0 : canvas->height; }

struct LarkEngine { uint32_t capabilities; };

LarkEngine* lark_engine_create(void) {
    auto* engine = new LarkEngine();
    engine->capabilities = LARK_CAP_SKIA_RENDER | LARK_CAP_NATIVE_DRAWING;
    return engine;
}

void lark_engine_destroy(LarkEngine* engine) { delete engine; }
uint32_t lark_engine_capabilities(LarkEngine* engine) { return engine == nullptr ? 0 : engine->capabilities; }
const char* lark_engine_version_string(void) { return "1.1.0-native-drawing"; }

struct LarkExportJob {
    LarkCanvas* canvas;
    LarkExportFormat format;
    int quality;
    std::shared_ptr<std::vector<uint8_t>> data;
};

LarkExportJob* lark_export_create(LarkEngine* engine, LarkCanvas* canvas,
                                  LarkExportFormat format, int32_t quality) {
    (void)engine;
    if (canvas == nullptr || format == LARK_FORMAT_PDF || format == LARK_FORMAT_SVG) return nullptr;
    auto* job = new LarkExportJob { canvas, format, std::clamp(quality, 1, 100), nullptr };
    return job;
}

bool lark_export_run(LarkExportJob* job, const char* output_path) {
    if (job == nullptr || output_path == nullptr || job->format != LARK_FORMAT_PNG) return false;
    size_t size = 0;
    const uint8_t* data = lark_export_buffer(job, &size);
    if (data == nullptr || size == 0) return false;
    FILE* file = std::fopen(output_path, "wb");
    if (file == nullptr) return false;
    const size_t written = std::fwrite(data, 1, size, file);
    const int closeResult = std::fclose(file);
    return written == size && closeResult == 0;
}

const uint8_t* lark_export_buffer(LarkExportJob* job, size_t* out_len) {
    if (out_len != nullptr) *out_len = 0;
    if (job == nullptr || job->canvas == nullptr || job->format != LARK_FORMAT_PNG) return nullptr;
    if (!job->data) job->data = encodePng(job->canvas);
    if (!job->data || job->data->empty()) return nullptr;
    if (out_len != nullptr) *out_len = job->data->size();
    return job->data->data();
}

void lark_export_destroy(LarkExportJob* job) { delete job; }
