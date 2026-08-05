/**
 * LarkDesign - 鸿蒙原生图标 Token
 *
 * 使用 SymbolGlyph + 系统符号字体（HarmonyOS Symbol Library）
 * 统一管理所有图标名称，便于后续维护和查找。
 *
 * 注：若设备不支持某些符号字体，SymbolGlyph 会降级显示。
 * 这里同时提供 Unicode 字符作为后备，供 Text 使用。
 */

/** 鸿蒙原生符号 Token */
export class SymbolToken {
  // 通用
  static readonly plus = 0xF0472     // sys.symbol.plus
  static readonly minus = 0xF0378    // sys.symbol.minus
  static readonly check = 0xF02C6    // sys.symbol.checkmark
  static readonly xmark = 0xF0389    // sys.symbol.xmark
  static readonly chevron_down = 0xF02F0
  static readonly chevron_right = 0xF02F6
  static readonly chevron_left = 0xF02F1
  static readonly chevron_up = 0xF02F2

  // 文件/编辑
  static readonly file_new = 0xF04A1
  static readonly file_recent = 0xF04AD
  static readonly file_template = 0xF04B9
  static readonly folder = 0xF04C6
  static readonly save = 0xF06C5
  static readonly export = 0xF041F
  static readonly import = 0xF0425
  static readonly undo = 0xF0398
  static readonly redo = 0xF0354

  // 工具
  static readonly cursor = 0xF0341
  static readonly hand = 0xF04B6
  static readonly rect = 0xF0618
  static readonly circle = 0xF02DA
  static readonly line = 0xF05DE
  static readonly pen = 0xF0501
  static readonly text = 0xF0758
  static readonly image = 0xF0465
  static readonly eyedropper = 0xF03F2
  static readonly zoom_in = 0xF0814
  static readonly zoom_out = 0xF0815
  static readonly zoom_fit = 0xF0813

  // UI 操作
  static readonly gear = 0xF04B0
  static readonly moon = 0xF03A4
  static readonly sun = 0xF06C8
  static readonly palette = 0xF04D3
  static readonly layers = 0xF05B6
  static readonly grid = 0xF04B5
  static readonly list = 0xF05F3
  static readonly grid_view = 0xF04B7
  static readonly eye = 0xF03F4
  static readonly eye_off = 0xF03F5
  static readonly lock = 0xF05C7
  static readonly unlock = 0xF0397
  static readonly trash = 0xF0784
  static readonly copy = 0xF0331
  static readonly paste = 0xF04F6
  static readonly cut = 0xF0372

  // 状态
  static readonly info = 0xF047E
  static readonly warning = 0xF07F1
  static readonly error = 0xF03ED
  static readonly success = 0xF06C0
  static readonly loading = 0xF05C1

  // 画布
  static readonly group = 0xF04B4
  static readonly ungroup = 0xF0796
  static readonly align_left = 0xF015A
  static readonly align_center = 0xF015B
  static readonly align_right = 0xF015C
  static readonly align_top = 0xF015D
  static readonly align_middle = 0xF015E
  static readonly align_bottom = 0xF015F
  static readonly distribute_h = 0xF03C7
  static readonly distribute_v = 0xF03C8

  // 导航
  static readonly arrow_right = 0xF01C2
  static readonly arrow_left = 0xF01C1
  static readonly arrow_up = 0xF01C3
  static readonly arrow_down = 0xF01C4
  static readonly refresh = 0xF05A6
  static readonly search = 0xF0654
  static readonly filter = 0xF04A3
  static readonly close = 0xF02F3

  // 历史与快照
  static readonly history = 0xF04B1     // sys.symbol.clock_arrow_2_circlepath
  static readonly camera = 0xF0290     // sys.symbol.camera
  static readonly snapshot = 0xF06D9   // sys.symbol.camera_viewfinder
  static readonly backward = 0xF02A3   // sys.symbol.backward_fill
  static readonly forward = 0xF04A4    // sys.symbol.forward_fill
  static readonly timer = 0xF078B      // sys.symbol.timer

  // 品牌与图标
  static readonly bezier = 0xF0274     // sys.symbol.bezier
  static readonly house = 0xF04B0      // sys.symbol.house
  static readonly sync = 0xF0725      // sys.symbol.arrow_2_circlepath

  // 排列与层级
  static readonly bring_forward = 0xF0761   // 上移一层
  static readonly send_backward = 0xF0760   // 下移一层
  static readonly bring_front = 0xF0763     // 移到顶层
  static readonly send_back = 0xF0762       // 移到底层
  static readonly pen_nib = 0xF0422         // 钢笔尖
  static readonly anchor = 0xF0274          // 锚点
  static readonly anchor_corner = 0xF0225   // 角点
  static readonly anchor_smooth = 0xF0226   // 平滑点
  static readonly convert_anchor = 0xF0274  // 转换锚点
  static readonly stroke_dash = 0xF04A1     // 虚线
  static readonly stroke_dot = 0xF04A2      // 点线
  static readonly map = 0xF0587             // 地图/鸟瞰
  static readonly expand = 0xF04A4          // 适配视图
  static readonly square = 0xF0420          // 方形（窗口最大化）
  static readonly book = 0xF0421            // 书籍
  static readonly star = 0xF04A3            // 星标
  static readonly layout = 0xF0495         // 布局
  static readonly ellipsis = 0xF0490       // 省略号
  static readonly file = 0xF0422            // 文件
  static readonly cloud = 0xF0423          // 云
  static readonly book_open = 0xF0421       // 打开的书（跨页）

  // 形状与编辑
  static readonly compress = 0xF04A4       // 压缩/简化（复用 expand 反义）
  static readonly hexagon = 0xF0420       // 六边形
  static readonly play = 0xF04A4           // 三角形（播放）
  static readonly stop = 0xF0420           // 八边形（停止）
  static readonly diamond = 0xF04A3       // 菱形
  static readonly wand = 0xF04B2          // 魔法棒（AI智能）
  static readonly sliders = 0xF04D8       // 滑块/自定义设置
}

/** Unicode 字符 Token（用于 Text 后备显示） */
export class IconCharToken {
  // 通用
  static readonly plus = '+'
  static readonly minus = '−'
  static readonly check = '✓'
  static readonly xmark = '✕'
  static readonly chevron_down = '▾'
  static readonly chevron_right = '▶'
  static readonly chevron_left = '◀'
  static readonly chevron_up = '▴'
  static readonly link = '🔗'

  // 文件/编辑
  static readonly file_new = '◉'
  static readonly file_recent = '◷'
  static readonly file_template = '▦'
  static readonly folder = '▤'
  static readonly save = '⤓'
  static readonly export = '⤴'
  static readonly import = '⤓'
  static readonly undo = '↶'
  static readonly redo = '↷'

  // 工具
  static readonly cursor = '◀'
  static readonly hand = '✋'
  static readonly rect = '▭'
  static readonly circle = '○'
  static readonly line = '─'
  static readonly pen = '✎'
  static readonly text = 'T'
  static readonly image = '▦'
  static readonly eyedropper = '💧'
  static readonly zoom_in = '⊞'
  static readonly zoom_out = '⊟'
  static readonly zoom_fit = '⤢'

  // UI 操作
  static readonly gear = '⚙'
  static readonly moon = '☾'
  static readonly sun = '☀'
  static readonly palette = '◐'
  static readonly layers = '▤'
  static readonly grid = '▦'
  static readonly list = '☰'
  static readonly grid_view = '☷'
  static readonly eye = '👁'
  static readonly eye_off = '⊘'
  static readonly lock = '🔒'
  static readonly unlock = '🔓'
  static readonly trash = '⌫'
  static readonly copy = '⎘'
  static readonly paste = '📋'
  static readonly cut = '✂'

  // 状态
  static readonly info = 'ℹ'
  static readonly warning = '⚠'
  static readonly error = '✕'
  static readonly success = '✓'
  static readonly loading = '◌'

  // 画布
  static readonly group = '⬕'
  static readonly ungroup = '⬗'
  static readonly align_left = '⌈'
  static readonly align_center = '⌶'
  static readonly align_right = '⌉'
  static readonly align_top = '⌈'
  static readonly align_middle = '⌶'
  static readonly align_bottom = '⌋'
  static readonly distribute_h = '⇿'
  static readonly distribute_v = '⇕'

  // 导航
  static readonly arrow_right = '→'
  static readonly arrow_left = '←'
  static readonly arrow_up = '↑'
  static readonly arrow_down = '↓'
  static readonly refresh = '⟳'
  static readonly search = '🔍'
  static readonly filter = '▽'
  static readonly close = '✕'

  // 旋转/翻转
  static readonly rotate = '↻'
  static readonly flip_h = '⇄'
  static readonly flip_v = '⇅'
  static readonly scale = '⤧'

  // 布尔
  static readonly union = '∪'
  static readonly subtract = '∖'
  static readonly intersect = '∩'
  static readonly exclude = '⊕'

  // 历史与快照
  static readonly history = '⌛'
  static readonly camera = '⦿'
  static readonly snapshot = '⌖'
  static readonly backward = '⏮'
  static readonly forward = '⏭'
  static readonly timer = '◷'

  // 品牌与图标
  static readonly bezier = '∿'
  static readonly house = '⌂'
  static readonly sync = '⟳'

  // 排列与层级
  static readonly bring_forward = '↑'
  static readonly send_backward = '↓'
  static readonly bring_front = '⤒'
  static readonly send_back = '⤓'
  static readonly pen_nib = '✎'
  static readonly anchor = '⚓'
  static readonly anchor_corner = '◧'
  static readonly anchor_smooth = '○'
  static readonly convert_anchor = '⇄'
  static readonly stroke_dash = '---'
  static readonly stroke_dot = '···'
  static readonly map = '▦'
  static readonly expand = '⤢'
  static readonly book = '▤'
  static readonly star = '★'
  static readonly layout = '▦'
  static readonly ellipsis = '⋯'
  static readonly file = '📄'
  static readonly cloud = '☁'
  static readonly book_open = '📖'   // 打开的书（跨页）

  // 形状与编辑
  static readonly compress = '⤓'
  static readonly hexagon = '⬡'
  static readonly play = '▶'
  static readonly stop = '■'
  static readonly diamond = '◆'
  static readonly wand = '✦'
  static readonly sliders = '☰'
  static readonly bolt = '⚡'        // 闪电
  static readonly check_square = '☑'  // 勾选方形（fx 启用状态）
  static readonly download = '⤓'    // 下载（导出）
  static readonly tower_broadcast = '📡'  // MCP 协议
  static readonly microchip = '▦'    // 模型配置
  static readonly robot = '⚙'        // 智能体技能
  static readonly info_circle = 'ℹ'   // 系统信息
  static readonly plug = '⚡'         // 测试连接
  static readonly tag = '🏷'          // 模型 ID
  static readonly key = '🔑'         // API 令牌
  static readonly user = '👤'        // 用户头像
  static readonly scissors = '✂'    // 剪切/剪刀
  static readonly crop = '⌗'        // 裁剪
  static readonly droplet = '💧'     // 水滴（模糊效果）
  static readonly shadow = '▨'      // 阴影
  static readonly folder_open = '▤'  // 打开的文件夹
  static readonly cube = '▦'         // 立方体
  static readonly code = '⌗'         // 代码（SVG 滤镜/脚本）
  static readonly square = '▣'       // 方形（窗口最大化）
}

/** 图标资源常量（统一资源引用入口） */
export class IconResource {
  /** 通过 SymbolGlyph 使用 */
  static symbolFontFamily = 'HarmonyOS Symbol'

  /** 标准图标颜色 */
  static readonly primary = $r('app.color.primary')
  static readonly secondary = $r('app.color.secondary')
  static readonly tertiary = $r('app.color.tertiary')
  static readonly muted = $r('app.color.muted')
  static readonly body = $r('app.color.body')
  static readonly title = $r('app.color.title')
  static readonly white = $r('app.color.white')
  static readonly error = $r('app.color.error')
  static readonly success = $r('app.color.success')
  static readonly warning = $r('app.color.warning')
}
