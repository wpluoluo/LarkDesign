/**
 * InspectorExportTab - 导出设置面板
 *
 * 对应原型 src/components/Inspector.vue 的 Export Tab 部分
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontWeightConstant, ShadowToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { Exporter, ExportFormat } from '../utils/Exporter'

/** 导出格式选项 */
interface ExportFormatOption {
  id: string
  name: string
}

@Component
export struct InspectorExportTab {
  @State exportFormat: string = 'png'
  @State exportQuality: number = 92
  @State exportScale: number = 100
  @State exportConstrain: boolean = true
  @State exportTransparent: boolean = true
  @State exportColorSpace: string = 'sRGB'
  @State exportEmbedICC: boolean = true
  @State exportPreset: string = 'PNG-24 透明'
  @State secExportBasic: boolean = false
  @State secExportSize: boolean = false
  @State secExportFormatOpt: boolean = false
  @State secExportColor: boolean = false
  @State secExportPresets: boolean = false
  @State pngMode: string = 'PNG-24'
  @State pngInterlace: boolean = false
  @State jpegProgressive: boolean = false
  @State jpegOptimize: boolean = true
  @State svgInline: boolean = true
  @State svgMinify: boolean = true
  @State svgResponsive: boolean = true
  @State pdfStandard: string = 'PDF/X-1a'
  @State pdfCropMarks: boolean = true
  @State pdfBleedMarks: boolean = true
  @State pdfColorBars: boolean = false
  @State hdsMode: string = '标准'
  @State hdsEmbedFonts: boolean = true
  @State hdsEmbedImages: boolean = true
  @State embedFonts: boolean = true
  @State embedImages: boolean = true
  @State hoveredExportFormat: string = ''
  @State hoveredExportPreset: string = ''
  @State hoveredExportColorSpace: string = ''
  @State hoveredExportSection: string = ''
  @State exportStatus: string = ''

  private exporter: Exporter = Exporter.getInstance()

  private async exportCurrent(): Promise<void> {
    const format: ExportFormat = this.exportFormat === 'jpg' ? 'jpeg' : this.exportFormat as ExportFormat
    const result = await this.exporter.export({
      format,
      quality: this.exportQuality / 100,
      dpi: 72,
    })
    this.exportStatus = result.ok
      ? `${result.message} · ${result.bytes ?? 0} bytes`
      : result.message
  }

  build(): void {
    Scroll() {
      Column() {
        Row() {
          Text('导出设置')
            .fontSize(13)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.body)
          Blank()
          Text('1 个图层')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
        .alignItems(VerticalAlign.Center)

        Column() {
          Text('格式')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
            .margin({ bottom: 4 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.exportFormats, (fmt: ExportFormatOption) => {
              Text(fmt.name)
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(this.exportFormat === fmt.id ? ColorToken.primary_dark_700 : ColorToken.secondary)
                .height(28)
                .padding({ left: 8, right: 8 })
                .borderRadius(4)
                .backgroundColor(this.exportFormat === fmt.id ? ColorToken.hover_bg : Color.Transparent)
                .border({ width: 1, color: this.exportFormat === fmt.id ? ColorToken.primary : ColorToken.border })
                .margin({ right: 4, bottom: 4 })
                .onClick(() => { this.exportFormat = fmt.id })
            })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })

        this.exportSection('basic', '基本', this.secExportBasic, (v: boolean) => { this.secExportBasic = v })
        this.exportSection('size', '尺寸', this.secExportSize, (v: boolean) => { this.secExportSize = v })
        this.exportSection('formatOpt', this.formatOptionLabel(), this.secExportFormatOpt, (v: boolean) => { this.secExportFormatOpt = v })
        this.exportSection('color', '色彩与元数据', this.secExportColor, (v: boolean) => { this.secExportColor = v })
        this.exportSection('presets', '预设方案', this.secExportPresets, (v: boolean) => { this.secExportPresets = v })

        Column() {
          Row() {
            Text('预估大小')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.muted)
            Blank()
            Text(this.estimatedSize())
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
          }
          .width('100%')
          .height(24)
          .padding({ left: 8, right: 8 })
          .borderRadius(4)
          .backgroundColor(ColorToken.panel)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 6 })

          Row() {
            Row() {
              Text(Icon.download)
                .fontSize(10)
                .fontColor(ColorToken.white)
                .margin({ right: 6 })
              Text('导出当前')
                .fontSize(10)
                .fontWeight(FontWeightConstant.bold)
                .fontColor(ColorToken.white)
            }
            .layoutWeight(1)
            .height(32)
            .borderRadius(6)
            .backgroundColor(ColorToken.primary_dark_700)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .onClick(() => { void this.exportCurrent() })

            Column() {
              Text(Icon.layers)
                .fontSize(10)
                .fontColor(ColorToken.secondary)
            }
            .width(30)
            .height(32)
            .borderRadius(6)
            .border({ width: 1, color: ColorToken.border })
            .backgroundColor(ColorToken.white)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 8 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (this.exportStatus.length > 0) {
            Text(this.exportStatus)
              .fontSize(9)
              .fontColor(ColorToken.muted)
              .maxLines(2)
              .margin({ top: 6 })
          }
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  exportSection(id: string, title: string, expanded: boolean, toggle: (v: boolean) => void): void {
    Column() {
      Row() {
        Text(title)
          .fontSize(13)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.body)
        Blank()
        Text(expanded ? Icon.chevron_down : Icon.chevron_up)
          .fontSize(8)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(this.hoveredExportSection === id ? ColorToken.panel : Color.Transparent)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { toggle(!expanded) })
      .onHover((isHover: boolean) => { this.hoveredExportSection = isHover ? id : '' })

      if (!expanded) {
        if (id === 'basic') {
          this.exportBasicContent()
        } else if (id === 'size') {
          this.exportSizeContent()
        } else if (id === 'formatOpt') {
          this.exportFormatOptContent()
        } else if (id === 'color') {
          this.exportColorContent()
        } else if (id === 'presets') {
          this.exportPresetsContent()
        }
      }
    }
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }

  @Builder
  exportBasicContent(): void {
    Column() {
      Column() {
        Row() {
          Text('品质')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
          Blank()
          Text(`${this.exportQuality}%`)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 2 })

        Row() {
          Row()
            .width(`${this.exportQuality}%`)
            .height('100%')
            .backgroundColor(ColorToken.primary)
            .borderRadius(2)
        }
        .width('100%')
        .height(4)
        .backgroundColor(ColorToken.border)
        .borderRadius(2)
        .gesture(
          PanGesture()
            .onActionUpdate((e: GestureEvent) => {
              const w = 236
              const pct = Math.max(1, Math.min(100, Math.round((e.offsetX / w) * 100)))
              this.exportQuality = pct
            })
        )

        Row() {
          Text('低')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('中')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('高')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('最佳')
            .fontSize(10)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 2, right: 2 })
        .alignItems(VerticalAlign.Center)
        .margin({ top: 1 })
      }
      .width('100%')
      .margin({ bottom: 6 })

      Column() {
        Row() {
          Text('缩放')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
          Blank()
          Text(`${this.exportScale}%`)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 2 })

        Row() {
          Row()
            .width(`${this.exportScale / 4}%`)
            .height('100%')
            .backgroundColor(ColorToken.primary)
            .borderRadius(2)
        }
        .width('100%')
        .height(4)
        .backgroundColor(ColorToken.border)
        .borderRadius(2)
        .gesture(
          PanGesture()
            .onActionUpdate((e: GestureEvent) => {
              const w = 236
              const pct = Math.max(10, Math.min(400, Math.round((e.offsetX / w) * 400)))
              this.exportScale = pct
            })
        )

        Row() {
          Text('10%')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('100%')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('400%')
            .fontSize(10)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 2, right: 2 })
        .alignItems(VerticalAlign.Center)
        .margin({ top: 1 })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  @Builder
  exportSizeContent(): void {
    Column() {
      Row() {
        Row() {
          Text('宽度')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
          Blank()
          Text('420 px')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .layoutWeight(1)
        .height(24)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.panel)
        .alignItems(VerticalAlign.Center)

        Row() {
          Text('高度')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
          Blank()
          Text('600 px')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .layoutWeight(1)
        .height(24)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.panel)
        .alignItems(VerticalAlign.Center)
        .margin({ left: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 4 })

      Row() {
        Row() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(ColorToken.white)
              .position({ x: this.exportConstrain ? 9 : 1, y: 2 })
          }
          .width(16)
          .height(10)
          .borderRadius(5)
          .backgroundColor(this.exportConstrain ? ColorToken.primary : ColorToken.border)
          .onClick(() => { this.exportConstrain = !this.exportConstrain })

          Text('约束比例')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        Row() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(ColorToken.white)
              .position({ x: this.exportTransparent ? 9 : 1, y: 2 })
          }
          .width(16)
          .height(10)
          .borderRadius(5)
          .backgroundColor(this.exportTransparent ? ColorToken.primary : ColorToken.border)
          .onClick(() => { this.exportTransparent = !this.exportTransparent })

          Text('透明')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  @Builder
  exportFormatOptContent(): void {
    Column() {
      if (this.exportFormat === 'png') {
        Row() {
          Row() {
            Text('PNG-24')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.pngMode === 'PNG-24' ? ColorToken.primary_dark_700 : ColorToken.muted)
          }
          .layoutWeight(1)
          .height(24)
          .borderRadius(3)
          .border({ width: 1, color: this.pngMode === 'PNG-24' ? ColorToken.primary : ColorToken.border })
          .backgroundColor(this.pngMode === 'PNG-24' ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.pngMode = 'PNG-24' })

          Row() {
            Text('PNG-8')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.pngMode === 'PNG-8' ? ColorToken.primary_dark_700 : ColorToken.muted)
          }
          .layoutWeight(1)
          .height(24)
          .borderRadius(3)
          .border({ width: 1, color: this.pngMode === 'PNG-8' ? ColorToken.primary : ColorToken.border })
          .backgroundColor(this.pngMode === 'PNG-8' ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .margin({ left: 4 })
          .onClick(() => { this.pngMode = 'PNG-8' })
        }
        .width('100%')
        .margin({ bottom: 4 })

        Row() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(ColorToken.white)
              .position({ x: this.pngInterlace ? 9 : 1, y: 2 })
          }
          .width(16)
          .height(10)
          .borderRadius(5)
          .backgroundColor(this.pngInterlace ? ColorToken.primary : ColorToken.border)
          .onClick(() => { this.pngInterlace = !this.pngInterlace })
          Text('交错')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)
      }

      if (this.exportFormat === 'jpg' || this.exportFormat === 'webp') {
        Row() {
          Row() {
            Text('渐进式')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.jpegProgressive ? ColorToken.primary_dark_700 : ColorToken.muted)
          }
          .layoutWeight(1)
          .height(24)
          .borderRadius(3)
          .border({ width: 1, color: this.jpegProgressive ? ColorToken.primary : ColorToken.border })
          .backgroundColor(this.jpegProgressive ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.jpegProgressive = !this.jpegProgressive })

          Row() {
            Text('优化')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.jpegOptimize ? ColorToken.primary_dark_700 : ColorToken.muted)
          }
          .layoutWeight(1)
          .height(24)
          .borderRadius(3)
          .border({ width: 1, color: this.jpegOptimize ? ColorToken.primary : ColorToken.border })
          .backgroundColor(this.jpegOptimize ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .margin({ left: 4 })
          .onClick(() => { this.jpegOptimize = !this.jpegOptimize })
        }
        .width('100%')
        .margin({ bottom: 4 })

        Row() {
          Text('子采样')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
          Blank()
          Text('4:4:4')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .width('100%')
        .height(24)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.panel)
        .alignItems(VerticalAlign.Center)
      }

      if (this.exportFormat === 'svg') {
        Column() {
          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.svgInline ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.svgInline ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.svgInline = !this.svgInline })
            Text('内联样式')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 3 })

          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.svgMinify ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.svgMinify ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.svgMinify = !this.svgMinify })
            Text('压缩精简')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 3 })

          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.svgResponsive ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.svgResponsive ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.svgResponsive = !this.svgResponsive })
            Text('响应式 viewBox')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }

      if (this.exportFormat === 'pdf') {
        Column() {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.pdfStandards, (std: string) => {
              Text(std)
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(this.pdfStandard === std ? ColorToken.primary_dark_700 : ColorToken.muted)
                .height(24)
                .padding({ left: 6, right: 6 })
                .borderRadius(3)
                .border({ width: 1, color: this.pdfStandard === std ? ColorToken.primary : ColorToken.border })
                .backgroundColor(this.pdfStandard === std ? ColorToken.hover_bg : Color.Transparent)
                .margin({ right: 4, bottom: 4 })
                .onClick(() => { this.pdfStandard = std })
            })
          }
          .width('100%')
          .margin({ bottom: 4 })

          Row() {
            Row() {
              Text('压缩')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
              Blank()
              Text('JPEG 最大')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
            }
            .layoutWeight(1)
            .height(24)
            .padding({ left: 6, right: 6 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .alignItems(VerticalAlign.Center)

            Row() {
              Text('嵌入字体')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
              Blank()
              Text('全部')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
            }
            .layoutWeight(1)
            .height(24)
            .padding({ left: 6, right: 6 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .alignItems(VerticalAlign.Center)
            .margin({ left: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 4 })

          Row() {
            Row() {
              Row() {
                Column()
                  .width(4)
                  .height(4)
                  .borderRadius(2)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.pdfCropMarks ? 7 : 1, y: 2 })
              }
              .width(12)
              .height(8)
              .borderRadius(3)
              .backgroundColor(this.pdfCropMarks ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.pdfCropMarks = !this.pdfCropMarks })
              Text('裁切')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)

            Blank()

            Row() {
              Row() {
                Column()
                  .width(4)
                  .height(4)
                  .borderRadius(2)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.pdfBleedMarks ? 7 : 1, y: 2 })
              }
              .width(12)
              .height(8)
              .borderRadius(3)
              .backgroundColor(this.pdfBleedMarks ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.pdfBleedMarks = !this.pdfBleedMarks })
              Text('出血')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)

            Blank()

            Row() {
              Row() {
                Column()
                  .width(4)
                  .height(4)
                  .borderRadius(2)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.pdfColorBars ? 7 : 1, y: 2 })
              }
              .width(12)
              .height(8)
              .borderRadius(3)
              .backgroundColor(this.pdfColorBars ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.pdfColorBars = !this.pdfColorBars })
              Text('色标')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }

      if (this.exportFormat === 'eps' || this.exportFormat === 'cdr') {
        Column() {
          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.embedFonts ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.embedFonts ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.embedFonts = !this.embedFonts })
            Text('嵌入字体')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 3 })

          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.embedImages ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.embedImages ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.embedImages = !this.embedImages })
            Text('嵌入图片')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }

      if (this.exportFormat === 'hds') {
        Column() {
          Row() {
            ForEach(['标准', '精简', '兼容'], (m: string) => {
              Text(m)
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(this.hdsMode === m ? ColorToken.primary_dark_700 : ColorToken.muted)
                .height(24)
                .padding({ left: 8, right: 8 })
                .borderRadius(3)
                .border({ width: 1, color: this.hdsMode === m ? ColorToken.primary : ColorToken.border })
                .backgroundColor(this.hdsMode === m ? ColorToken.hover_bg : Color.Transparent)
                .margin({ right: 4 })
                .onClick(() => { this.hdsMode = m })
            })
          }
          .width('100%')
          .margin({ bottom: 4 })

          Row() {
            Row() {
              Text('版本')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
              Blank()
              Text('v3.0')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
            }
            .layoutWeight(1)
            .height(24)
            .padding({ left: 6, right: 6 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .alignItems(VerticalAlign.Center)

            Row() {
              Text('压缩')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
              Blank()
              Text('无损')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
            }
            .layoutWeight(1)
            .height(24)
            .padding({ left: 6, right: 6 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .alignItems(VerticalAlign.Center)
            .margin({ left: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 4 })

          Row() {
            Row() {
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.hdsEmbedFonts ? 9 : 1, y: 2 })
              }
              .width(16)
              .height(10)
              .borderRadius(5)
              .backgroundColor(this.hdsEmbedFonts ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.hdsEmbedFonts = !this.hdsEmbedFonts })
              Text('嵌入字体')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
            .margin({ right: 8 })

            Row() {
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.hdsEmbedImages ? 9 : 1, y: 2 })
              }
              .width(16)
              .height(10)
              .borderRadius(5)
              .backgroundColor(this.hdsEmbedImages ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.hdsEmbedImages = !this.hdsEmbedImages })
              Text('嵌入图片')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  @Builder
  exportColorContent(): void {
    Column() {
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.exportColorSpaces, (cs: string) => {
          Text(cs)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(this.exportColorSpace === cs ? ColorToken.primary_dark_700 : ColorToken.muted)
            .height(24)
            .padding({ left: 8, right: 8 })
            .borderRadius(3)
            .border({ width: 1, color: this.exportColorSpace === cs ? ColorToken.primary : ColorToken.border })
            .backgroundColor(this.exportColorSpace === cs ? ColorToken.hover_bg : Color.Transparent)
            .margin({ right: 4, bottom: 4 })
            .onClick(() => { this.exportColorSpace = cs })
        })
      }
      .width('100%')
      .margin({ bottom: 4 })

      Row() {
        Row() {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(ColorToken.white)
            .position({ x: this.exportEmbedICC ? 9 : 1, y: 2 })
        }
        .width(16)
        .height(10)
        .borderRadius(5)
        .backgroundColor(this.exportEmbedICC ? ColorToken.primary : ColorToken.border)
        .onClick(() => { this.exportEmbedICC = !this.exportEmbedICC })
        Text('嵌入 ICC 配置文件')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
          .margin({ left: 4 })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  @Builder
  exportPresetsContent(): void {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.exportPresets, (preset: string) => {
        Row() {
          if (this.exportPreset === preset) {
            Text('✓')
              .fontSize(10)
              .fontColor(ColorToken.primary_dark_700)
              .margin({ right: 3 })
          }
          Text(preset)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(this.exportPreset === preset ? ColorToken.primary_dark_700 : ColorToken.muted)
        }
        .height(24)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .border({ width: 1, color: this.exportPreset === preset ? ColorToken.primary : ColorToken.border })
        .backgroundColor(this.exportPreset === preset ? ColorToken.hover_bg : Color.Transparent)
        .margin({ right: 4, bottom: 4 })
        .onClick(() => { this.exportPreset = preset })
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  private formatOptionLabel(): string {
    if (this.exportFormat === 'png') return 'PNG 选项'
    if (this.exportFormat === 'jpg') return 'JPEG 选项'
    if (this.exportFormat === 'webp') return 'WebP 选项'
    if (this.exportFormat === 'svg') return 'SVG 选项'
    if (this.exportFormat === 'pdf') return 'PDF 选项'
    if (this.exportFormat === 'eps') return 'EPS 选项'
    if (this.exportFormat === 'cdr') return 'CDR 选项'
    if (this.exportFormat === 'hds') return 'HDS 选项'
    return '格式选项'
  }

  private estimatedSize(): string {
    const base = 420 * 600 * 3
    const qualityFactor = this.exportQuality / 100
    const sizeKb = Math.round(base * qualityFactor * 0.1 * Math.pow(this.exportScale / 100, 2) / 1024)
    if (sizeKb < 1024) return `${Math.max(4, sizeKb)} KB`
    return `${(sizeKb / 1024).toFixed(1)} MB`
  }

  private exportFormats: ExportFormatOption[] = [
    { id: 'png', name: 'PNG' },
    { id: 'jpg', name: 'JPEG' },
    { id: 'webp', name: 'WebP' },
    { id: 'svg', name: 'SVG' },
    { id: 'pdf', name: 'PDF' },
    { id: 'eps', name: 'EPS' },
    { id: 'cdr', name: 'CDR' },
    { id: 'hds', name: 'HDS' },
  ]

  private exportColorSpaces: string[] = ['sRGB', 'Adobe RGB', 'Display P3', 'CMYK']

  private pdfStandards: string[] = ['PDF/X-1a', 'PDF/X-3', 'PDF/X-4', 'PDF/A-1b', 'PDF/A-2b', 'PDF 2.0']

  private exportPresets: string[] = [
    'PNG-24 透明', 'PNG-8 256色', 'JPEG 最大质量', 'JPEG 网页中等',
    'WebP 无损', 'WebP 有损 80%', 'SVG 压缩', 'PDF 打印高质',
    'PDF 网页最小', 'EPS 印刷', 'CDR 兼容', 'HDS 标准归档',
  ]
}
