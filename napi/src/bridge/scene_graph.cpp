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
    if (!sg || !json || std::strlen(json) == 0) return false;
    sg->json_source = json;
    // 解析器尚未接入，不能仅凭首字符宣称场景有效。
    return false;
}

bool lark_scene_graph_render(LarkSceneGraph* sg, LarkCanvas* canvas) {
    // 场景节点解析尚未接入；明确失败，禁止向上层伪造成功。
    (void)sg;
    (void)canvas;
    return false;
}
