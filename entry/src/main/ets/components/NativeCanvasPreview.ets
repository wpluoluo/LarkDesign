/** 正式画布的 NativeDrawing/Skia 像素预览。编辑手柄仍由 ArkUI 覆盖层负责。 */
import { Frame } from '../types/SceneTypes'
import { NativeEngine } from '../native/NativeEngine'

@Component
export struct NativeCanvasPreview {
  @Prop @Watch('onFrameChanged') frame: Frame
  @State pixelMap: PixelMap | null = null
  @State renderError: string = ''

  aboutToAppear(): void {
    void this.render()
  }

  private onFrameChanged(): void {
    void this.render()
  }

  private async render(): Promise<void> {
    try {
      this.pixelMap = await NativeEngine.renderFrame(this.frame)
      this.renderError = ''
    } catch (error) {
      this.pixelMap = null
      this.renderError = String(error)
      console.error('NativeCanvasPreview', 'render failed: ' + this.renderError)
    }
  }

  build(): void {
    if (this.pixelMap !== null) {
      Image(this.pixelMap)
        .width(this.frame.width)
        .height(this.frame.height)
        .objectFit(ImageFit.Fill)
        .hitTestBehavior(HitTestMode.None)
    } else if (this.renderError.length > 0) {
      Text('Native 渲染失败')
        .fontSize(10)
        .fontColor('#D14343')
        .width(this.frame.width)
        .height(this.frame.height)
        .textAlign(TextAlign.Center)
    } else {
      Blank()
        .width(this.frame.width)
        .height(this.frame.height)
    }
  }
}
