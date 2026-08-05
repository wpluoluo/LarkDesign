# LarkDesign 交互流程规范

> 冻结时间：2026-07-28
> 作为鸿蒙端 ArkTS 事件绑定的逻辑源

## 一、画布交互

### 1.1 视口导航

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 平移视口 | 空白处中键拖拽 / Space+左键拖拽 / 工具=抓手时左键拖拽 | 视口移动 | `canvas.viewportX/Y` 更新 |
| 缩放视口 | Ctrl+滚轮 / 触控板捏合 | 以鼠标为中心缩放 | `canvas.zoom` 更新，viewport 调整 |
| 适配视图 | 点击"适配视图"按钮 / Ctrl+0 / Ctrl+Shift+0 | 视口居中所有Frame | `fitViewportToFrames()` |
| 缩放按钮 | 点击+/-按钮 | 以视口中心缩放 | `zoom *= 1.2` 或 `/= 1.2` |

**坐标转换公式**（屏幕→画布）：
```
canvasX = (screenX - viewportWidth/2) / zoom + viewportX
canvasY = (screenY - viewportHeight/2) / zoom + viewportY
```

### 1.2 Frame 选择

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 单击 Frame | 左键单击 Frame 边框 | 边框高亮 | `selectedFrameId` = frame.id |
| 加选 Frame | Shift+左键单击 Frame | 多选高亮 | 加入 `selectedFrameIds` |
| 取消选择 | 单击空白处 | 边框取消高亮 | `selectedFrameId` = null |

### 1.3 Frame 移动

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 拖拽 Frame | 左键按下 Frame 边框并移动 | Frame 跟随鼠标 | `frame.x/y` 更新（实时） |
| 完成拖拽 | 鼠标抬起 | - | `pushHistory()` |

### 1.4 Frame 调整尺寸

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 拖拽 handle | 左键按下 8 个 handle 之一并移动 | 边框跟随调整 | `frame.width/height/x/y` 更新 |
| 完成调整 | 鼠标抬起 | - | `pushHistory()` |

handle 位置：nw, n, ne, e, se, s, sw, w（共8个）

### 1.5 进入 Frame 编辑

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 进入编辑 | 双击 Frame | Frame 高亮，进入编辑模式 | `editingFrameId` = frame.id |
| 退出编辑 | 双击空白处 / Esc | Frame 取消高亮 | `editingFrameId` = null |
| 退出编辑 | 单击其他 Frame | 切换到其他 Frame | `editingFrameId` = null, `selectedFrameId` = new |

### 1.6 Frame 内对象操作（编辑模式下）

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 单击对象 | 左键单击对象 | 选中边框 + 8 handle | `selectedLayerId` / `selectedObjectIds` |
| 加选对象 | Shift+左键单击对象 | 多选边框 | 加入 `selectedObjectIds` |
| 框选对象 | 在 Frame 内空白处拖拽矩形 | 矩形预览，松开时选中框内对象 | `selectedObjectIds` 批量更新 |
| 拖拽对象 | 左键按下选中对象并移动 | 对象跟随鼠标 | `object.transform.x/y` 更新 |
| 调整尺寸 | 拖拽 handle | 对象边框调整 | `object.transform.width/height` 更新 |
| 旋转对象 | 拖拽旋转 handle | 对象旋转 | `object.transform.rotation` 更新 |

### 1.7 双击 Frame 空白处

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 创建 Frame | 在画布空白处双击 | 在双击位置创建默认 Frame | `addFrame()` 并切换到新 Frame |

## 二、工具栏交互

### 2.1 工具切换

| 工具 | 快捷键 | 光标 | 行为 |
|------|--------|------|------|
| 选择 | V | default | 选中/拖拽对象 |
| 矩形 | R | crosshair | 拖拽创建矩形 |
| 椭圆 | O | crosshair | 拖拽创建椭圆 |
| 文字 | T | text | 单击创建文字对象 |
| 吸管 | I | crosshair | 单击取色 |
| 抓手 | H | grab/grabbing | 拖拽平移视口 |
| 缩放 | Z | zoom-in | 单击放大，Alt+单击缩小 |

### 2.2 形状绘制

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 开始绘制 | 形状工具下左键按下 | 显示预览矩形 | 记录起点 |
| 绘制中 | 鼠标移动 | 预览矩形跟随鼠标 | 实时更新预览尺寸 |
| 完成绘制 | 鼠标抬起 | 创建对象，切回选择工具 | `newObject()` + `pushHistory()` |
| 等比例 | Shift+拖拽 | 1:1 等比例 | width = height |
| 从中心绘制 | Alt+拖拽 | 以起点为中心向外扩展 | x/y/width/height 调整 |

### 2.3 吸管取色

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 取色 | 吸管工具下单击 | 光标处取色 | `colorStore.currentHex` 更新 |
| 跨域降级 | getImageData 失败 | 从对象 fill/color 取 | - |

## 三、Inspector 面板交互

### 3.1 双向绑定规则

| 输入框 | 触发时机 | 反馈 | 数据变化 |
|--------|---------|------|----------|
| 数字输入框 | change（失焦/Enter） | 对象属性更新 | `updateObject()` + `pushHistory()` |
| 数字输入框 | focus | 记录初始值 | 进入编辑状态 |
| 文本输入框 | input（实时） | 对象属性实时更新 | `updateObject(skipHistory=true)` |
| 颜色输入框 | change | 对象颜色更新 | `updateObject()` + `pushHistory()` |

### 3.2 Typography 面板

| 控件 | 触发 | 数据变化 |
|------|------|----------|
| 文本内容输入框 | input | `object.props.text` |
| 字体选择 | change | `object.props.fontFamily` |
| 字号/行距/字距 | change | `object.props.fontSize/lineHeight/letterSpacing` |
| 字重按钮 | click | `object.props.fontWeight` |
| B/I/U 按钮 | click | `object.props.fontWeight/fontStyle/textDecoration` |
| 对齐按钮 | click | `object.props.textAlign` |
| 文字颜色 | change | `object.props.color` |

### 3.3 对齐与分布

| 控件 | 触发条件 | 算法 | 数据变化 |
|------|---------|------|----------|
| 左对齐 | 点击 + 选中2+对象 | 所有对象 x = min(x) | `updateObject(skipHistory=true)` 批量 |
| 水平居中 | 点击 + 选中2+对象 | 所有对象 x = bbox中心 - width/2 | 同上 |
| 右对齐 | 点击 + 选中2+对象 | 所有对象 x = max(x+w) - w | 同上 |
| 顶/中/底对齐 | 同上 | y 方向 | 同上 |
| 水平分布 | 点击 + 选中3+对象 | 按x排序，均匀间距 | 同上 |
| 垂直分布 | 同上 | y 方向 | 同上 |

完成后调用一次 `pushHistory()`。

## 四、图层管理

### 4.1 图层操作

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 选中图层 | 单击图层项 | 高亮 | `selectedLayerId` |
| 重命名 | 双击图层名 | 进入编辑模式 | `renamingLayerId` |
| 删除 | Delete/Backspace | 移除图层 | `removeLayer()` + `pushHistory()` |
| 复制 | Ctrl+D | 创建副本 | `duplicateLayer()` + `pushHistory()` |
| 显隐切换 | 点击眼睛图标 | 图标切换 | `layer.visible` |
| 锁定切换 | 点击锁图标 | 图标切换 | `layer.locked` |
| 拖拽排序 | 拖拽图层项 | 位置移动 | `reorderLayer()` + `pushHistory()` |

## 五、Frame 管理

### 5.1 Frame 操作

| 交互 | 触发条件 | 反馈 | 数据变化 |
|------|---------|------|----------|
| 新建 Frame | 点击+按钮 | 创建默认 Frame | `addFrame()` + `pushHistory()` |
| 复制 Frame | 点击复制按钮 | 创建副本 | `duplicateFrame()` + `pushHistory()` |
| 删除 Frame | 点击删除按钮 | 移除 Frame | `removeFrame()` + `pushHistory()` |
| 重命名 Frame | 双击 Frame 名 | 进入编辑模式 | `renamingFrameId` |
| 上移/下移 | 点击箭头按钮 | 位置交换 | `moveFrame()` + `pushHistory()` |
| 切换 Frame | 单击 Frame 项 | 高亮切换 | `selectedFrameId` |
| 显隐切换 | 点击眼睛图标 | 图标切换 | `frame.hidden` |
| 拖拽排序 | 拖拽 Frame 项 | 位置移动 | `reorderFrame()` + `pushHistory()` |

## 六、键盘快捷键

### 6.1 全局

| 快捷键 | 行为 |
|--------|------|
| Ctrl+Z | 撤销 |
| Ctrl+Y / Ctrl+Shift+Z | 重做 |
| Ctrl+C | 复制选中对象 |
| Ctrl+V | 粘贴 |
| Ctrl+X | 剪切 |
| Ctrl+D | 复制选中对象（原地） |
| Ctrl+A | 全选当前Frame内对象 |
| Delete / Backspace | 删除选中对象 |
| Esc | 退出编辑/取消选择 |
| Space（按住） | 临时切换抓手工具 |

### 6.2 工具切换

| 快捷键 | 工具 |
|--------|------|
| V | 选择 |
| R | 矩形 |
| O | 椭圆 |
| T | 文字 |
| I | 吸管 |
| H | 抓手 |
| Z | 缩放 |

### 6.3 视图

| 快捷键 | 行为 |
|--------|------|
| Ctrl+0 | 适配视图 |
| Ctrl+1 | 100% 缩放 |
| Ctrl+= | 放大 |
| Ctrl+- | 缩小 |
| Ctrl+Shift+0 | 适配所有 Frame |

### 6.4 对象微调

| 快捷键 | 行为 |
|--------|------|
| ←/→/↑/↓ | 移动 1px |
| Shift+方向键 | 移动 10px |
| Ctrl+方向键 | 微调 0.1px |

## 七、右键菜单

### 7.1 画布右键

菜单项：粘贴 / 全选 / 适配视图 / 在此创建 Frame

### 7.2 对象右键

菜单项：复制 / 剪切 / 删除 / 置于顶层 / 置于底层 / 上移一层 / 下移一层 / 编组 / 取消编组

### 7.3 Frame 右键

菜单项：进入编辑 / 复制 / 删除 / 重命名 / 切换显隐

### 7.4 图层右键

菜单项：复制 / 删除 / 重命名 / 切换显隐 / 切换锁定

## 八、Toast 提示规则

- **单条显示**：新消息替换旧消息
- **显示时长**：3秒后自动消失
- **位置**：屏幕底部居中
- **类型**：success / info / warning
- **图标**：根据类型自动选择
- **过渡**：淡入淡出 200ms

## 九、主题切换规则

| 主题 | 切换条件 | 范围 |
|------|---------|------|
| 明亮 | 用户选择 | 全局 |
| 温暖暗色 | 用户选择 / 系统暗色 | 全局 |
| 专业暗黑 | 用户选择 | 全局 |
| 石板灰 | 用户选择 | 全局 |
| 暖纸阅读 | 用户选择 | 全局 |

主题切换通过动态注入 CSS 变量实现，鸿蒙端对应 `color.json` 资源切换。

## 十、文档持久化

| 时机 | 行为 |
|------|------|
| 首次加载 | 从 localStorage 恢复或创建默认文档 |
| 修改后 | 自动保存到 localStorage（防抖 500ms） |
| 手动保存 | Ctrl+S 保存到 localStorage |
| 导出 | PNG/JPG/SVG 导出 |

## 十一、ArkUI 事件映射参考

| Vue 事件 | ArkUI 事件 |
|---------|-----------|
| `@mousedown` | `onTouch` / `TapGesture` |
| `@mousemove` | `PanGesture` |
| `@mouseup` | `PanGesture` end |
| `@dblclick` | `TapGesture` count=2 |
| `@wheel` | `onAxis` / 手势缩放 |
| `@keydown` | `onKeyEvent` |
| `@contextmenu` | 长按 `LongPressGesture` |
| `@dragstart/dragover/drop` | `PanGesture` + 自定义 |
| `ResizeObserver` | `onAreaChange` |
| `watch/computed` | `@Watch` / build 内计算 |
