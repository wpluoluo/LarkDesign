/**
 * scene_graph.cpp - 场景图桥接
 *
 * 将 Fusion DOM JSON 描述渲染为 Skia 绘制指令。
 * 不直接暴露 Skia 类型给上层的 ArkTS。
 */

#include "../include/lark_engine.h"
#include <string>
#include <vector>
#include <cstring>

// 简化的 JSON 解析（仅用于原型 demo）
// 生产环境应接入轻量 JSON 解析库（如 simdjson / yyjson）
struct JsonNode;

struct LarkSceneGraph {
    std::string json_source;
};

LarkSceneGraph* lark_scene_graph_create(LarkEngine* engine) {
    return new LarkSceneGraph();
}

void lark_scene_graph_destroy(LarkSceneGraph* sg) {
    delete sg;
}

bool lark_scene_graph_load_json(LarkSceneGraph* sg, const char* json) {
    sg->json_source = json;
    return true;
}

bool lark_scene_graph_render(LarkSceneGraph* sg, LarkCanvas* canvas) {
    // TODO: 解析 JSON 并调用 canvas 绘制 API
    // 这是 Fusion DOM 到 Skia 的核心映射逻辑
    // 格式：{ "objects": [ { "type": "rect", "x":..., "y":..., "fill":... } ] }
    return true;
}
