/**
 * CanvasInteraction - 画布交互引擎
 *
 * 对应原型 src/composables/useCanvasInteraction.ts
 * 管理 Frame 内对象级别的交互：选中、拖拽、缩放、框选、绘制。
 * 当前为轻量代理，交互逻辑在 CanvasStage 中内联。
 */
export class CanvasInteraction {
  private static instance: CanvasInteraction

  private constructor() {}

  static getInstance(): CanvasInteraction {
    if (!CanvasInteraction.instance) {
      CanvasInteraction.instance = new CanvasInteraction()
    }
    return CanvasInteraction.instance
  }

  /** 处理选中 */
  handleSelect(): void {
    // 集成在 CanvasStage.ets 中
  }

  /** 处理拖拽 */
  handleDrag(): void {
    // 集成在 CanvasStage.ets 中
  }

  /** 处理缩放 */
  handleResize(): void {
    // 集成在 CanvasStage.ets 中
  }
}
