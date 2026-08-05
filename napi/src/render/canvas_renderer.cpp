/**
 * canvas_renderer.cpp - Skia 画布渲染器实现
 *
 * 实现 lark_engine.h 中声明的 LarkCanvas 操作。
 * 使用 Skia 作为后端渲染引擎。
 */

#include "../include/lark_engine.h"
#include <memory>
#include <cstring>

// Skia 头文件（编译时需 -I$SKIA_DIR/include）
#include "include/core/SkCanvas.h"
#include "include/core/SkBitmap.h"
#include "include/core/SkPaint.h"
#include "include/core/SkRect.h"
#include "include/core/SkRRect.h"
#include "include/core/SkColor.h"
#include "include/core/SkFont.h"
#include "include/core/SkTypeface.h"
#include "include/core/SkImage.h"
#include "include/core/SkSurface.h"
#include "include/core/SkPixmap.h"
#include "include/encode/SkPngEncoder.h"
#include "include/encode/SkJpegEncoder.h"
#include "include/encode/SkWebpEncoder.h"

struct LarkCanvas {
    sk_sp<SkSurface> surface;
    SkCanvas* canvas;
    int width;
    int height;
    float dpi;
};

LarkCanvas* lark_canvas_create(LarkEngine* engine, const LarkRenderTarget* target) {
    auto c = new LarkCanvas();
    c->width = target->width;
    c->height = target->height;
    c->dpi = target->dpi;

    SkImageInfo info = SkImageInfo::Make(
        target->width, target->height,
        kN32_SkColorType, kPremul_SkAlphaType
    );
    c->surface = SkSurface::MakeRaster(info);
    if (!c->surface) {
        delete c;
        return nullptr;
    }
    c->canvas = c->surface->getCanvas();
    return c;
}

void lark_canvas_destroy(LarkCanvas* canvas) {
    delete canvas;
}

void lark_canvas_clear(LarkCanvas* canvas, uint32_t color) {
    canvas->canvas->clear(color);
}

void lark_canvas_draw_rect(LarkCanvas* canvas, const LarkRect* rect,
                           uint32_t fill_color, float stroke_width, uint32_t stroke_color) {
    SkPaint paint;
    paint.setColor(fill_color);
    paint.setAntiAlias(true);
    SkRect r = SkRect::MakeLTRB(rect->x, rect->y, rect->x + rect->width, rect->y + rect->height);
    canvas->canvas->drawRect(r, paint);

    if (stroke_width > 0) {
        SkPaint strokePaint;
        strokePaint.setColor(stroke_color);
        strokePaint.setStyle(SkPaint::kStroke_Style);
        strokePaint.setStrokeWidth(stroke_width);
        strokePaint.setAntiAlias(true);
        canvas->canvas->drawRect(r, strokePaint);
    }
}

void lark_canvas_draw_round_rect(LarkCanvas* canvas, const LarkRect* rect,
                                 float rx, float ry, uint32_t fill_color,
                                 float stroke_width, uint32_t stroke_color) {
    SkPaint paint;
    paint.setColor(fill_color);
    paint.setAntiAlias(true);
    SkRRect rrect = SkRRect::MakeRectXY(
        SkRect::MakeLTRB(rect->x, rect->y, rect->x + rect->width, rect->y + rect->height),
        rx, ry
    );
    canvas->canvas->drawRRect(rrect, paint);

    if (stroke_width > 0) {
        SkPaint strokePaint;
        strokePaint.setColor(stroke_color);
        strokePaint.setStyle(SkPaint::kStroke_Style);
        strokePaint.setStrokeWidth(stroke_width);
        strokePaint.setAntiAlias(true);
        canvas->canvas->drawRRect(rrect, strokePaint);
    }
}

void lark_canvas_draw_ellipse(LarkCanvas* canvas, const LarkRect* rect,
                              uint32_t fill_color, float stroke_width, uint32_t stroke_color) {
    SkPaint paint;
    paint.setColor(fill_color);
    paint.setAntiAlias(true);
    SkRect r = SkRect::MakeLTRB(rect->x, rect->y, rect->x + rect->width, rect->y + rect->height);
    canvas->canvas->drawOval(r, paint);

    if (stroke_width > 0) {
        SkPaint strokePaint;
        strokePaint.setColor(stroke_color);
        strokePaint.setStyle(SkPaint::kStroke_Style);
        strokePaint.setStrokeWidth(stroke_width);
        strokePaint.setAntiAlias(true);
        canvas->canvas->drawOval(r, strokePaint);
    }
}

void lark_canvas_draw_text(LarkCanvas* canvas, const char* text,
                           float x, float y, float size, uint32_t color,
                           LarkTypeface* typeface) {
    SkPaint paint;
    paint.setColor(color);
    paint.setAntiAlias(true);

    SkFont font;
    if (typeface) {
        // font.setTypeface(sk_ref_sp(static_cast<SkTypeface*>(typeface)));
    }
    font.setSize(size);

    canvas->canvas->drawString(SkString(text), x, y, font, paint);
}

void lark_canvas_draw_image(LarkCanvas* canvas, LarkImage* image,
                            const LarkRect* rect, float opacity) {
    SkPaint paint;
    paint.setAlpha((uint8_t)(opacity * 255));
    paint.setAntiAlias(true);
    paint.setFilterQuality(kHigh_SkFilterQuality);

    SkRect r = SkRect::MakeLTRB(rect->x, rect->y, rect->x + rect->width, rect->y + rect->height);
    auto skImage = static_cast<SkImage*>(image);
    canvas->canvas->drawImageRect(skImage, r, &paint);
}

void lark_canvas_set_transform(LarkCanvas* canvas, const LarkMatrix* matrix) {
    SkMatrix skMat;
    skMat.setAll(matrix->scaleX, matrix->skewX, matrix->transX,
                 matrix->skewY, matrix->scaleY, matrix->transY,
                 0, 0, 1);
    canvas->canvas->setMatrix(skMat);
}

void lark_canvas_reset_transform(LarkCanvas* canvas) {
    canvas->canvas->resetMatrix();
}

void lark_canvas_save(LarkCanvas* canvas) {
    canvas->canvas->save();
}

void lark_canvas_restore(LarkCanvas* canvas) {
    canvas->canvas->restore();
}

// ─── 引擎 ───

struct LarkEngine {
    uint32_t capabilities;
};

LarkEngine* lark_engine_create(void) {
    auto e = new LarkEngine();
    e->capabilities = LARK_CAP_SKIA_RENDER | LARK_CAP_LCMS2;
    return e;
}

void lark_engine_destroy(LarkEngine* engine) {
    delete engine;
}

uint32_t lark_engine_capabilities(LarkEngine* engine) {
    return engine->capabilities;
}

const char* lark_engine_version_string(void) {
    return "1.0.0";
}

// ─── 导出 ───

struct LarkExportJob {
    LarkCanvas* canvas;
    LarkExportFormat format;
    int quality;
    sk_sp<SkData> data;
};

LarkExportJob* lark_export_create(LarkEngine* engine, LarkCanvas* canvas,
                                  LarkExportFormat format, int32_t quality) {
    auto job = new LarkExportJob();
    job->canvas = canvas;
    job->format = format;
    job->quality = quality;
    return job;
}

bool lark_export_run(LarkExportJob* job, const char* output_path) {
    // TODO: 写入文件
    return false;
}

const uint8_t* lark_export_buffer(LarkExportJob* job, size_t* out_len) {
    if (!job->data) {
        sk_sp<SkImage> image = job->canvas->surface->makeImageSnapshot();
        if (!image) return nullptr;

        SkPixmap pixmap;
        if (!image->peekPixels(&pixmap)) return nullptr;

        switch (job->format) {
            case LARK_FORMAT_PNG:
                job->data = SkPngEncoder::Encode(nullptr, pixmap, {});
                break;
            case LARK_FORMAT_JPEG:
                job->data = SkJpegEncoder::Encode(nullptr, pixmap, { job->quality });
                break;
            case LARK_FORMAT_WEBP:
                job->data = SkWebpEncoder::Encode(nullptr, pixmap, { (SkWebpEncoder::Compression)job->quality });
                break;
            default:
                return nullptr;
        }
    }
    if (job->data) {
        *out_len = job->data->size();
        return (const uint8_t*)job->data->data();
    }
    return nullptr;
}

void lark_export_destroy(LarkExportJob* job) {
    delete job;
}
