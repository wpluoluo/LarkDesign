/**
 * Fusion DOM Serializer Tests
 *
 * 真实测试 shared/fusion/serializer 模块的导出函数。
 * 使用实际 serialize / deserialize / deepClone / normalizeDocument / estimateSize。
 */
import { describe, it, expect } from 'vitest'
import { serialize, deserialize, deepClone, normalizeDocument, HDS_FORMAT_VERSION, estimateSize } from '../fusion/serializer'
import type { SerializableDocument } from '../fusion/serializer'

const testDoc: SerializableDocument = {
  version: '3.0',
  scene: {
    id: 'scene_root',
    name: 'Test.hds',
    canvasWidth: 595,
    canvasHeight: 842,
    unit: 'mm',
    dpi: 300,
    colorSpace: 'sRGB',
    background: '#FFFFFF',
    children: [],
    frames: [
      {
        id: 'frame_1',
        type: 'single',
        name: 'Frame 1',
        x: 100,
        y: 100,
        width: 400,
        height: 600,
        background: '#FFFFFF',
        children: [{
          id: 'layer_1',
          name: 'Layer 1',
          visible: true,
          locked: false,
          objects: [{
            id: 'rect_1',
            type: 'shape',
            name: 'Rectangle',
            shape: 'rectangle',
            fill: '#3AC487',
            transform: { x: 50, y: 50, width: 100, height: 80, rotation: 0, scaleX: 1, scaleY: 1, flipH: false, flipV: false, opacity: 100 }
          }]
        }],
        hidden: false,
        createdAt: '2026-01-01T00:00:00.000Z',
        showPageNumber: false,
        pageNumberFormat: 'P{n}'
      }
    ],
    selectedFrameId: 'frame_1'
  },
  metadata: { createdAt: '2026-01-01T00:00:00.000Z', modifiedAt: '2026-01-01T00:00:00.000Z' }
}

describe('Fusion DOM Serializer', () => {
  it('serialize round-trip', () => {
    const json = serialize(testDoc)
    const parsed = deserialize(json)
    expect(parsed.version).toBe('3.0')
    expect((parsed.scene as Record<string, unknown>).frames).toBeDefined()
  })

  it('preserves object properties', () => {
    const json = serialize(testDoc)
    const parsed = deserialize(json)
    const scene = parsed.scene as Record<string, unknown>
    const frames = scene.frames as Array<Record<string, unknown>>
    const children = frames[0].children as Array<Record<string, unknown>>
    const objects = children[0].objects as Array<Record<string, unknown>>
    const obj = objects[0]
    expect(obj.shape).toBe('rectangle')
    expect(obj.fill).toBe('#3AC487')
    const t = obj.transform as Record<string, unknown>
    expect(t.width).toBe(100)
  })

  it('deep clone isolation', () => {
    const copy = deepClone(testDoc)
    const copyScene = copy.scene as Record<string, unknown>
    const copyFrames = copyScene.frames as Array<Record<string, unknown>>
    copyFrames[0].name = 'Modified'
    const origScene = testDoc.scene as Record<string, unknown>
    const origFrames = origScene.frames as Array<Record<string, unknown>>
    expect(origFrames[0].name).toBe('Frame 1')
  })

  it('empty document', () => {
    const empty: SerializableDocument = {
      version: '3.0',
      scene: { id: 'scene_root', name: 'Untitled.hds', canvasWidth: 595, canvasHeight: 842, unit: 'mm', dpi: 300, colorSpace: 'sRGB', background: '#FFFFFF', children: [] },
      metadata: { createdAt: '', modifiedAt: '' }
    }
    const json = serialize(empty)
    const parsed = deserialize(json)
    const s = parsed.scene as Record<string, unknown>
    expect(s.children).toEqual([])
    expect(s.canvasWidth).toBe(595)
  })

  it('version compatibility: old doc fill defaults', () => {
    // 旧版文档缺少字段，normalizeDocument 应填充默认值
    const oldJson = JSON.stringify({ version: '2.0', scene: { id: 'old' }, metadata: {} })
    const parsed = deserialize(oldJson)
    expect(parsed.version).toBe('2.0')
    const s = parsed.scene as Record<string, unknown>
    expect(s.canvasWidth).toBe(595)
    expect(s.unit).toBe('mm')
  })

  it('throws on invalid document', () => {
    expect(() => deserialize('{}')).toThrow()
    expect(() => deserialize('{"foo":"bar"}')).toThrow()
    expect(() => normalizeDocument(null)).toThrow()
    expect(() => normalizeDocument('string' as unknown as object)).toThrow()
  })

  it('estimate size', () => {
    const json = serialize(testDoc)
    const kb = estimateSize(json)
    expect(kb).toBeGreaterThan(0)
  })
})
