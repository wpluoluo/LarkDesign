/** ArkTS declaration for the stable NAPI surface exported by liblark_engine.so. */
declare module 'liblark_engine.so' {
  interface LarkEngineNativeModule {
    getVersion(): string
    getCapabilities(): number
    createCanvas(width: number, height: number): bigint
    destroyCanvas(canvas: bigint): void
    clearCanvas(canvas: bigint, color: number): void
    drawRect(canvas: bigint, x: number, y: number, width: number, height: number, fill: number, strokeWidth: number, stroke: number): void
    drawRoundRect(canvas: bigint, x: number, y: number, width: number, height: number, rx: number, ry: number, fill: number, strokeWidth: number, stroke: number): void
    drawEllipse(canvas: bigint, x: number, y: number, width: number, height: number, fill: number, strokeWidth: number, stroke: number): void
    drawText(canvas: bigint, text: string, x: number, y: number, size: number, color: number): void
    getPixels(canvas: bigint): ArrayBuffer
    exportPng(canvas: bigint): ArrayBuffer
  }

  const nativeEngine: LarkEngineNativeModule
  export default nativeEngine
}
