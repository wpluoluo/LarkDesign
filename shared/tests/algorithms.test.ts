/**
 * Shared Algorithms Tests
 *
 * 真实测试 shared/algorithms 模块的导出函数。
 * 不内联重实现，保证测试覆盖生产代码路径。
 */
import { describe, it, expect } from 'vitest'
import { alignObjects, distributeObjects } from '../algorithms/alignment'
import { hitTestPoint, rectIntersectsObject } from '../algorithms/hitTest'
import { screenToCanvas, canvasToScreen, zoomAtPoint } from '../algorithms/coordinate'
import type { SceneObject } from '../types/scene'

/** 构造一个简单 SceneObject 用于测试 */
function makeObj(x: number, y: number, w: number, h: number, overrides: Partial<SceneObject> = {}): SceneObject {
  return {
    id: 'test',
    type: 'shape',
    name: 'Test',
    transform: { x, y, width: w, height: h, rotation: 0, scaleX: 1, scaleY: 1, flipH: false, flipV: false, opacity: 100 },
    blendMode: 'normal',
    visible: true,
    locked: false,
    shape: 'rectangle',
    fill: '#000',
    stroke: '',
    strokeWidth: 0,
    ...overrides,
  } as SceneObject
}

describe('Alignment Algorithms', () => {
  it('align left: sets all x to min x', () => {
    const objects = [makeObj(100, 100, 50, 50), makeObj(200, 150, 80, 60), makeObj(300, 200, 100, 70)]
    alignObjects(objects, 'left')
    objects.forEach(o => expect(o.transform.x).toBe(100))
  })

  it('align center-h: sets x to bbox center - width/2', () => {
    const objects = [makeObj(0, 0, 100, 50), makeObj(50, 50, 80, 60)]
    alignObjects(objects, 'center-h')
    // bbox: minX=0, maxX=130, centerX=65
    // obj0: 65 - 50 = 15, obj1: 65 - 40 = 25
    expect(objects[0].transform.x).toBe(15)
    expect(objects[1].transform.x).toBe(25)
  })

  it('align right: sets x to bbox.maxX - width', () => {
    const objects = [makeObj(0, 0, 100, 50), makeObj(50, 50, 80, 60)]
    alignObjects(objects, 'right')
    // bbox: maxX=130
    expect(objects[0].transform.x).toBe(30)  // 130 - 100
    expect(objects[1].transform.x).toBe(50)  // 130 - 80
  })

  it('distribute horizontal: equal spacing', () => {
    const objects = [makeObj(0, 0, 50, 50), makeObj(100, 0, 50, 50), makeObj(200, 0, 50, 50)]
    distributeObjects(objects, 'horizontal')
    // totalWidth = (200+50) - 0 = 250, sumObjWidth = 150, gapCount = 2
    // gap = (250 - 150) / 2 = 50
    // obj0: x=0, obj1: 0+50+50=100, obj2: 100+50+50=200
    expect(objects[0].transform.x).toBe(0)
    expect(objects[2].transform.x).toBe(200)
  })

  it('distribute vertical: equal spacing', () => {
    const objects = [makeObj(0, 0, 50, 50), makeObj(0, 100, 50, 50), makeObj(0, 200, 50, 50)]
    distributeObjects(objects, 'vertical')
    expect(objects[0].transform.y).toBe(0)
    expect(objects[2].transform.y).toBe(200)
  })

  it('distribute: no-op for < 3 objects', () => {
    const objects = [makeObj(0, 0, 50, 50), makeObj(100, 0, 50, 50)]
    distributeObjects(objects, 'horizontal')
    expect(objects[0].transform.x).toBe(0)
    expect(objects[1].transform.x).toBe(100)
  })
})

describe('HitTest Algorithms', () => {
  it('point inside rectangle (inclusive)', () => {
    const obj = makeObj(10, 10, 100, 100)
    expect(hitTestPoint(obj, 50, 50)).toBe(true)
    expect(hitTestPoint(obj, 10, 10)).toBe(true)   // edge: inclusive
    expect(hitTestPoint(obj, 110, 110)).toBe(true) // edge: inclusive
    expect(hitTestPoint(obj, 9, 9)).toBe(false)    // outside
    expect(hitTestPoint(obj, 111, 111)).toBe(false) // outside
  })

  it('rectangle intersection', () => {
    const a = makeObj(0, 0, 100, 100)
    const b = makeObj(50, 50, 100, 100)
    const c = makeObj(200, 200, 50, 50)
    expect(rectIntersectsObject(a, b.transform.x, b.transform.y, b.transform.width, b.transform.height)).toBe(true)
    expect(rectIntersectsObject(a, c.transform.x, c.transform.y, c.transform.width, c.transform.height)).toBe(false)
  })
})

describe('Coordinate Algorithms', () => {
  it('screen to canvas conversion', () => {
    // screenToCanvas(sx, sy, viewportX, viewportY, zoom, viewportWidth, viewportHeight)
    // 当 viewportX=0, viewportY=0, zoom=1, viewportWidth=160, viewportHeight=100
    // sx=280, sy=250 => canvasX = (280 - 160/2)/1 + 0 = 200, canvasY = (250 - 100/2)/1 + 0 = 200
    const result = screenToCanvas(280, 250, 0, 0, 1, 160, 100)
    expect(result.x).toBe(200)
    expect(result.y).toBe(200)
  })

  it('canvas to screen conversion', () => {
    const result = canvasToScreen(200, 200, 0, 0, 1, 160, 100)
    expect(result.x).toBe(280)
    expect(result.y).toBe(250)
  })

  it('zoom at point preserves anchor', () => {
    // zoomAtPoint 应保证锚点屏幕坐标不变
    const result = zoomAtPoint(280, 250, 2, 1, 0, 0, 160, 100)
    // 锚点画布坐标 (200, 200)
    // 新 viewport = 200 - (280 - 80)/2 = 200 - 100 = 100
    expect(result.zoom).toBe(2)
    expect(result.viewportX).toBe(100)
    expect(result.viewportY).toBe(100)
  })
})
