/**
 * lark_engine.h - LarkDesign 引擎 C ABI
 *
 * 稳定 ABI 接口，供 ArkTS 通过 NAPI 调用。
 * 原则：
 *   - 所有参数和返回值使用基本 C 类型或稳定 DTO
 *   - 不暴露 Skia / lcms2 等第三方库类型
 *   - 句柄（Handle）是不透明指针，引擎内部管理生命周期
 */

#ifndef LARK_ENGINE_H
#define LARK_ENGINE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ═══════════════ 版本与元信息 ═══════════════ */

#define LARK_ENGINE_VERSION_MAJOR 1
#define LARK_ENGINE_VERSION_MINOR 0
#define LARK_ENGINE_VERSION_PATCH 0

/** 引擎能力位掩码 */
#define LARK_CAP_SKIA_RENDER   (1u << 0)
#define LARK_CAP_LCMS2         (1u << 1)
#define LARK_CAP_PDF_EXPORT    (1u << 2)
#define LARK_CAP_SVG_IMPORT    (1u << 3)

/* ═══════════════ 基础类型 ═══════════════ */

typedef struct { float x, y; } LarkPoint;
typedef struct { float x, y, width, height; } LarkRect;
typedef struct { uint8_t r, g, b, a; } LarkColor;

/** 变换矩阵（2D affine，6 个参数） */
typedef struct {
    float scaleX, skewX, transX;
    float skewY, scaleY, transY;
} LarkMatrix;

/** 渲染目标配置 */
typedef struct {
    int32_t width;
    int32_t height;
    float dpi;
    uint32_t background_color;  // 0xAARRGGBB
} LarkRenderTarget;

/** 导出格式 */
typedef enum {
    LARK_FORMAT_PNG = 0,
    LARK_FORMAT_JPEG,
    LARK_FORMAT_WEBP,
    LARK_FORMAT_SVG,
    LARK_FORMAT_PDF,
} LarkExportFormat;

/* ═══════════════ 句柄类型 ═══════════════ */

typedef struct LarkEngine      LarkEngine;       // 引擎实例
typedef struct LarkCanvas      LarkCanvas;       // 画布渲染上下文
typedef struct LarkSceneGraph  LarkSceneGraph;   // 场景图
typedef struct LarkPath        LarkPath;         // 矢量路径
typedef struct LarkTypeface    LarkTypeface;     // 字体
typedef struct LarkImage       LarkImage;        // 位图
typedef struct LarkExportJob   LarkExportJob;    // 导出任务

/* ═══════════════ 引擎生命周期 ═══════════════ */

/** 创建引擎实例 */
LarkEngine* lark_engine_create(void);

/** 销毁引擎实例 */
void lark_engine_destroy(LarkEngine* engine);

/** 查询引擎能力位掩码 */
uint32_t lark_engine_capabilities(LarkEngine* engine);

/** 查询引擎版本字符串（静态，无需 engine） */
const char* lark_engine_version_string(void);

/* ═══════════════ 画布渲染 ═══════════════ */

/** 创建渲染目标画布 */
LarkCanvas* lark_canvas_create(LarkEngine* engine, const LarkRenderTarget* target);

/** 销毁画布 */
void lark_canvas_destroy(LarkCanvas* canvas);

/** 清空画布（填充背景色） */
void lark_canvas_clear(LarkCanvas* canvas, uint32_t color);

/** 绘制矩形 */
void lark_canvas_draw_rect(LarkCanvas* canvas, const LarkRect* rect, uint32_t fill_color, float stroke_width, uint32_t stroke_color);

/** 绘制圆角矩形 */
void lark_canvas_draw_round_rect(LarkCanvas* canvas, const LarkRect* rect, float rx, float ry, uint32_t fill_color, float stroke_width, uint32_t stroke_color);

/** 绘制椭圆 */
void lark_canvas_draw_ellipse(LarkCanvas* canvas, const LarkRect* rect, uint32_t fill_color, float stroke_width, uint32_t stroke_color);

/** 绘制文本 */
void lark_canvas_draw_text(LarkCanvas* canvas, const char* text, float x, float y, float size, uint32_t color, LarkTypeface* typeface);

/** 绘制位图 */
void lark_canvas_draw_image(LarkCanvas* canvas, LarkImage* image, const LarkRect* rect, float opacity);

/** 应用变换矩阵 */
void lark_canvas_set_transform(LarkCanvas* canvas, const LarkMatrix* matrix);

/** 重置变换为单位矩阵 */
void lark_canvas_reset_transform(LarkCanvas* canvas);

/** 保存当前画布状态（push） */
void lark_canvas_save(LarkCanvas* canvas);

/** 恢复画布状态（pop） */
void lark_canvas_restore(LarkCanvas* canvas);

/* ═══════════════ 场景图 ═══════════════ */

/** 创建场景图 */
LarkSceneGraph* lark_scene_graph_create(LarkEngine* engine);

/** 销毁场景图 */
void lark_scene_graph_destroy(LarkSceneGraph* sg);

/** 从 JSON 描述加载场景图 */
bool lark_scene_graph_load_json(LarkSceneGraph* sg, const char* json);

/** 渲染场景图到画布 */
bool lark_scene_graph_render(LarkSceneGraph* sg, LarkCanvas* canvas);

/* ═══════════════ 位图 ═══════════════ */

/** 从内存加载位图（PNG/JPEG/WebP 自动检测） */
LarkImage* lark_image_decode(LarkEngine* engine, const uint8_t* data, size_t len);

/** 从文件加载位图 */
LarkImage* lark_image_load(LarkEngine* engine, const char* path);

/** 销毁位图 */
void lark_image_destroy(LarkImage* image);

/** 获取位图尺寸 */
LarkRect lark_image_bounds(LarkImage* image);

/* ═══════════════ 导出 ═══════════════ */

/** 创建导出任务 */
LarkExportJob* lark_export_create(LarkEngine* engine, LarkCanvas* canvas, LarkExportFormat format, int32_t quality);

/** 执行导出（写入文件） */
bool lark_export_run(LarkExportJob* job, const char* output_path);

/** 执行导出（获取内存缓冲区） */
const uint8_t* lark_export_buffer(LarkExportJob* job, size_t* out_len);

/** 销毁导出任务 */
void lark_export_destroy(LarkExportJob* job);

/* ═══════════════ 字体 ═══════════════ */

/** 从文件加载字体 */
LarkTypeface* lark_typeface_load(LarkEngine* engine, const char* path);

/** 通过系统字体名加载字体 */
LarkTypeface* lark_typeface_from_name(LarkEngine* engine, const char* family_name);

/** 销毁字体 */
void lark_typeface_destroy(LarkTypeface* typeface);

#ifdef __cplusplus
}
#endif

#endif /* LARK_ENGINE_H */
