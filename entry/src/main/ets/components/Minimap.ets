/**
 * Minimap - 鸟瞰图
 *
 * 对应原型 src/components/Minimap.vue
 * 精准还原：右下角浮动卡片 + 标题栏（可收起） + SVG Frame 矩形 + 视口矩形
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontSizeToken, SpacingToken, RadiusToken, FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

interface MiniFrame {
  id: string
  x: number
  y: number
  w: number
  h: number
  selected: boolean
}

interface ViewportRect {
  x: number
  y: number
  w: number
  h: number
}

@Component
export struct Minimap {
  @State expanded: boolean = true
  @State frames: MiniFrame[] = []
  @State viewportRect: ViewportRect | null = null
  @State hovered: boolean = false
  // Frames 模式开关（非 Frames 模式或无 Frame 时不显示）
  @State isFramesMode: boolean = true
  // chevron 旋转角度（展开=0，收起=180）
  @State chevronAngle: number = 0

  aboutToAppear(): void {
    // 模拟数据：2 个 Frame
    const f1: MiniFrame = { id: 'f1', x: 20, y: 30, w: 60, h: 80, selected: true }
    const f2: MiniFrame = { id: 'f2', x: 95, y: 35, w: 40, h: 56, selected: false }
    this.frames = [f1, f2]
    const vp: ViewportRect = { x: 10, y: 20, w: 80, h: 60 }
    this.viewportRect = vp
  }

  /** 生成数字范围数组 */
  private range(n: number): number[] {
    const arr: number[] = []
    for (let i = 0; i < n; i++) {
      arr.push(i)
    }
    return arr
  }

  /** 切换展开/收起，带过渡动画 */
  private toggleExpand(): void {
    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
      this.expanded = !this.expanded
      this.chevronAngle = this.expanded ? 0 : 180
    })
  }

  build(): void {
    // 原型：v-if="fusion.isFramesMode && fusion.frames.length > 0"
    if (this.isFramesMode && this.frames.length > 0) {
      if (this.expanded) {
        Column() {
          // 标题栏
          Row() {
            Row() {
              Text(Icon.map)
                .fontSize(9)
                .fontColor(ColorToken.primary)
              Text('鸟瞰图')
                .fontSize(10)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.body)
                .margin({ left: 6 })
            }
            .layoutWeight(1)

            // chevron 旋转动画（原型：transition-transform duration-150）
            Text(Icon.chevron_down)
              .fontSize(8)
              .fontColor(ColorToken.muted)
              .rotate({ x: 0, y: 0, z: 1, angle: this.chevronAngle })
          }
          .width('100%')
          .height(26)
          .padding({ left: 8, right: 8 })
          .alignItems(VerticalAlign.Center)
          .backgroundColor(this.hovered ? ColorToken.hover_bg : Color.Transparent)
          .onHover((isHover: boolean) => { this.hovered = isHover })
          .onClick(() => { this.toggleExpand() })

          // 鸟瞰图主体（180x120，点击平移视口）
          Stack({ alignContent: Alignment.TopStart }) {
            // 白底
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor(ColorToken.white)

            // Frame 矩形（用 Column 模拟，无法用 SVG）
            ForEach(this.frames, (f: MiniFrame) => {
              Column()
                .width(f.w)
                .height(f.h)
                .backgroundColor(f.selected ? ColorToken.primary_light_100 : ColorToken.white)
                .border({
                  width: f.selected ? 1.5 : 0.8,
                  color: f.selected ? ColorToken.primary : ColorToken.border,
                })
                .borderRadius(1)
                .position({ x: f.x, y: f.y })
            })

            // 视口矩形（原型：stroke-dasharray="3 2" 虚线）
            // 用 4 条边的 Row/Column 拼接小段模拟虚线
            Stack({ alignContent: Alignment.TopStart }) {
              // 填充层
              Column()
                .width('100%')
                .height('100%')
                .backgroundColor('#3AC4871A')

              // 上边虚线
              Row() {
                ForEach(this.range(Math.max(1, Math.floor(this.viewportRect!.w / 5))), (i: number) => {
                  Column()
                    .width(3)
                    .height(1.2)
                    .backgroundColor(ColorToken.primary)
                    .margin({ left: i === 0 ? 0 : 2 })
                })
              }
              .width('100%')
              .height(1.2)
              .alignItems(VerticalAlign.Center)

              // 下边虚线
              Row() {
                ForEach(this.range(Math.max(1, Math.floor(this.viewportRect!.w / 5))), (i: number) => {
                  Column()
                    .width(3)
                    .height(1.2)
                    .backgroundColor(ColorToken.primary)
                    .margin({ left: i === 0 ? 0 : 2 })
                })
              }
              .width('100%')
              .height(1.2)
              .alignItems(VerticalAlign.Center)
              .position({ x: 0, y: this.viewportRect!.h - 1.2 })

              // 左边虚线
              Column() {
                ForEach(this.range(Math.max(1, Math.floor(this.viewportRect!.h / 5))), (i: number) => {
                  Row()
                    .width(1.2)
                    .height(3)
                    .backgroundColor(ColorToken.primary)
                    .margin({ top: i === 0 ? 0 : 2 })
                })
              }
              .width(1.2)
              .height('100%')
              .alignItems(HorizontalAlign.Center)

              // 右边虚线
              Column() {
                ForEach(this.range(Math.max(1, Math.floor(this.viewportRect!.h / 5))), (i: number) => {
                  Row()
                    .width(1.2)
                    .height(3)
                    .backgroundColor(ColorToken.primary)
                    .margin({ top: i === 0 ? 0 : 2 })
                })
              }
              .width(1.2)
              .height('100%')
              .alignItems(HorizontalAlign.Center)
              .position({ x: this.viewportRect!.w - 1.2, y: 0 })
            }
            .width(this.viewportRect!.w)
            .height(this.viewportRect!.h)
            .position({ x: this.viewportRect!.x, y: this.viewportRect!.y })
            .clip(true)
          }
          .width(180)
          .height(120)
          .backgroundColor(ColorToken.white)
          // 点击鸟瞰图：平移视口到点击位置（原型 onMinimapClick）
          .onClick((event: GestureEvent) => {
            // 简化：点击时将视口中心移到点击位置（模拟）
            if (this.viewportRect) {
              const offsetX = event.fingerList[0].localX - 90
              const offsetY = event.fingerList[0].localY - 60
              this.viewportRect = {
                x: Math.max(0, Math.min(180 - this.viewportRect.w, offsetX + this.viewportRect.w / 2)),
                y: Math.max(0, Math.min(120 - this.viewportRect.h, offsetY + this.viewportRect.h / 2)),
                w: this.viewportRect.w,
                h: this.viewportRect.h,
              }
            }
          })
        }
        .width(180)
        .borderRadius(RadiusToken.lg)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: ColorToken.border_light })
        .shadow({ radius: 16, color: '#0F172A1A', offsetX: 0, offsetY: 4 })
        .clip(true)
        .position({ x: '100%', y: '100%' })
        .markAnchor({ x: '100%', y: '100%' })
        .offset({ x: -12, y: -48 })
        .zIndex(20)
      } else {
        // 收起态（原型：保持标题栏样式，仅无主体）
        Row() {
          Row() {
            Text(Icon.map)
              .fontSize(9)
              .fontColor(ColorToken.primary)
            Text('鸟瞰图')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.body)
              .margin({ left: 6 })
          }
          .layoutWeight(1)

          // chevron 旋转动画
          Text(Icon.chevron_down)
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .rotate({ x: 0, y: 0, z: 1, angle: this.chevronAngle })
        }
        .height(26)
        .padding({ left: 8, right: 8 })
        .borderRadius(RadiusToken.lg)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: ColorToken.border_light })
        .shadow({ radius: 16, color: '#0F17221A', offsetX: 0, offsetY: 4 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => { this.toggleExpand() })
        .position({ x: '100%', y: '100%' })
        .markAnchor({ x: '100%', y: '100%' })
        .offset({ x: -12, y: -48 })
      }
    }
  }
}
