/**
 * LarkDesign - 设计Token（ArkUI 资源引用封装）
 *
 * 本文件统一管理所有 Token 的资源引用，组件只需引用此文件的常量，
 * 不直接拼接 $r() 字符串，便于后续维护和重构。
 */

/** 颜色 Token */
export class ColorToken {
  // 品牌色
  static readonly primary = $r('app.color.primary')
  static readonly primary_dark_900 = $r('app.color.primary_dark_900')
  static readonly primary_dark_700 = $r('app.color.primary_dark_700')
  static readonly primary_light_300 = $r('app.color.primary_light_300')
  static readonly primary_light_100 = $r('app.color.primary_light_100')

  // 功能色
  static readonly info = $r('app.color.info')
  static readonly success = $r('app.color.success')
  static readonly warning = $r('app.color.warning')
  static readonly error = $r('app.color.error')

  // 文字色
  static readonly title = $r('app.color.title')
  static readonly body = $r('app.color.body')
  static readonly secondary = $r('app.color.secondary')
  static readonly tertiary = $r('app.color.tertiary')
  static readonly muted = $r('app.color.muted')

  // 边框/背景色
  static readonly border = $r('app.color.border')
  static readonly border_light = $r('app.color.border_light')
  static readonly panel = $r('app.color.panel')
  static readonly bg = $r('app.color.bg')
  static readonly white = $r('app.color.white')
  static readonly surface = $r('app.color.surface')
  static readonly canvas_bg = $r('app.color.canvas_bg')
  static readonly hover_bg = $r('app.color.hover_bg')
  static readonly focus_ring = $r('app.color.focus_ring')
  static readonly page = $r('app.color.page')
  static readonly transparent = Color.Transparent

  // 标尺
  static readonly ruler_bg = $r('app.color.ruler_bg')
  static readonly ruler_border = $r('app.color.ruler_border')
  static readonly ruler_tick = $r('app.color.ruler_tick')
  static readonly ruler_text = $r('app.color.ruler_text')
  static readonly ruler_corner = $r('app.color.ruler_corner')
}

/** 间距 Token */
export class SpacingToken {
  static readonly s1 = $r('app.float.spacing_1') // 4vp
  static readonly s2 = $r('app.float.spacing_2') // 8vp
  static readonly s3 = $r('app.float.spacing_3') // 12vp
  static readonly s4 = $r('app.float.spacing_4') // 16vp
  static readonly s5 = $r('app.float.spacing_5') // 20vp
  static readonly s6 = $r('app.float.spacing_6') // 24vp
  static readonly s8 = $r('app.float.spacing_8') // 32vp
  static readonly s10 = $r('app.float.spacing_10') // 40vp
}

/** 圆角 Token */
export class RadiusToken {
  static readonly sm = $r('app.float.radius_sm') // 4vp
  static readonly md = $r('app.float.radius_md') // 6vp
  static readonly lg = $r('app.float.radius_lg') // 8vp
  static readonly xl = $r('app.float.radius_xl') // 10vp
  static readonly xxl = $r('app.float.radius_2xl') // 12vp
}

/** 字号 Token */
export class FontSizeToken {
  static readonly level1 = $r('app.float.font_size_1') // 10fp
  static readonly level2 = $r('app.float.font_size_2') // 11fp
  static readonly level3 = $r('app.float.font_size_3') // 12fp
  static readonly level4 = $r('app.float.font_size_4') // 13fp
  static readonly title = $r('app.float.font_size_title') // 16fp
}

/** 高度 Token */
export class HeightToken {
  static readonly xs = $r('app.float.height_xs') // 24vp
  static readonly sm = $r('app.float.height_sm') // 28vp
  static readonly md = $r('app.float.height_md') // 32vp
  static readonly lg = $r('app.float.height_lg') // 40vp
  static readonly xl = $r('app.float.height_xl') // 44vp
}

/** 图标尺寸 Token */
export class IconSizeToken {
  static readonly xs = $r('app.float.icon_size_xs') // 8vp
  static readonly sm = $r('app.float.icon_size_sm') // 9vp
  static readonly md = $r('app.float.icon_size_md') // 10vp
  static readonly lg = $r('app.float.icon_size_lg') // 11vp
  static readonly xl = $r('app.float.icon_size_xl') // 12vp
  static readonly xxl = $r('app.float.icon_size_2xl') // 14vp
}

/** 组件尺寸 Token */
export class LayoutToken {
  static readonly tool_rail_width = $r('app.float.tool_rail_width') // 48vp
  static readonly pages_panel_width = $r('app.float.pages_panel_width') // 200vp
  static readonly inspector_width = $r('app.float.inspector_width') // 300vp
  static readonly menubar_height = $r('app.float.menubar_height') // 32vp
  static readonly tool_options_bar_height = $r('app.float.tool_options_bar_height') // 40vp
  static readonly status_bar_height = $r('app.float.status_bar_height') // 28vp
}

/** 字重常量 */
export class FontWeightConstant {
  static readonly thin = 300
  static readonly regular = 400
  static readonly medium = 500
  static readonly semibold = 600
  static readonly bold = 700
  static readonly extrabold = 800
}

/** 阴影 Token（统一投影系统） */
export class ShadowToken {
  static readonly xs: ShadowOptions = { radius: 2, color: '#0F17220A', offsetX: 0, offsetY: 1 }
  static readonly sm: ShadowOptions = { radius: 4, color: '#0F17220F', offsetX: 0, offsetY: 1 }
  static readonly md: ShadowOptions = { radius: 8, color: '#0F17220F', offsetX: 0, offsetY: 2 }
  static readonly lg: ShadowOptions = { radius: 16, color: '#0F17221A', offsetX: 0, offsetY: 4 }
  static readonly xl: ShadowOptions = { radius: 20, color: '#0F17221F', offsetX: 0, offsetY: 8 }
  static readonly primary_sm: ShadowOptions = { radius: 6, color: '#3AC48747', offsetX: 0, offsetY: 2 }
  static readonly primary_md: ShadowOptions = { radius: 18, color: '#3AC48752', offsetX: 0, offsetY: 6 }
  static readonly primary_lg: ShadowOptions = { radius: 24, color: '#3AC48766', offsetX: 0, offsetY: 8 }
  static readonly none: ShadowOptions = { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 }
}

/** 动画时长 Token */
export class DurationToken {
  static readonly fast = 100   // 100ms hover
  static readonly base = 150   // 150ms 默认
  static readonly slow = 200   // 200ms 复杂过渡
  static readonly slower = 300 // 300ms 大型切换
}

/** 缓动函数 Token */
export class EaseToken {
  static readonly standard = Curve.EaseInOut
  static readonly in = Curve.EaseIn
  static readonly out = Curve.EaseOut
  static readonly in_out = Curve.EaseInOut
  static readonly smooth = Curve.Smooth
}

/** 层级 Token */
export class ZIndexToken {
  static readonly base = 1
  static readonly dropdown = 100
  static readonly sticky = 200
  static readonly fixed = 300
  static readonly modal_backdrop = 400
  static readonly modal = 500
  static readonly toast = 600
  static readonly tooltip = 700
}
