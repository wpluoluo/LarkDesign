/**
 * InfiniteCanvas - 无限画布引擎
 *
 * 对应原型 src/composables/useInfiniteCanvas.ts
 * 管理画布视口：平移、缩放、适配视图、Frame 选择。
 * 当前为轻量代理，核心逻辑在 CanvasStage 中内联。
 */
export class InfiniteCanvas {
  private static instance: InfiniteCanvas

  private constructor() {}

  static getInstance(): InfiniteCanvas {
    if (!InfiniteCanvas.instance) {
      InfiniteCanvas.instance = new InfiniteCanvas()
    }
    return InfiniteCanvas.instance
  }

  /** 平移视口 */
  pan(dx: number, dy: number): void {
    // 集成在 CanvasStage.ets 中
  }

  /** 缩放视口 */
  zoomAt(zoom: number, cx: number, cy: number): void {
    // 集成在 CanvasStage.ets 中
  }

  /** 适配视图到所有 Frame */
  fitToFrames(): void {
    // 集成在 CanvasStage.ets 中
  }
}
