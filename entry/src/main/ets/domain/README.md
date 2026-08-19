# Domain 边界

只放纯数据模型、文档操作、序列化、文档状态门面和端口接口。不得依赖 ArkUI 组件、网络实现或 NAPI 具体模块。

`FusionDocumentStore`、`DocumentStore`、`LayerStore` 与 `LayerBlendStore` 属于文档领域入口；它们可以通过 `platform/` 的持久化端口保存文档，但不得反向依赖 `features/`。
