import { describe, it, expect } from '@ohos/hypium'
import {
  textChecksum,
  readOk,
  readFailed,
  writeOk,
  writeFailed,
  PNG_MAGIC,
  JPEG_MAGIC,
  asciiMagic,
  copyBytes,
  matchesMagic,
  verifyImageStructure,
  verifyJsonText,
  verifyPdfStructure,
  verifySvgText,
} from '../main/ets/platform/PersistenceTypes'
import { HdsDocument } from '../main/ets/domain/SceneTypes'
import { createScene, createShapeObject } from '../main/ets/domain/FusionFactory'
import { addFrame, addLayer, addObjectToLayer, getFramesBoundingBox } from '../main/ets/domain/FusionOps'
import { deserialize, serialize } from '../main/ets/domain/FusionSerializer'
import { FusionDocumentStore } from '../main/ets/domain/FusionDocumentStore'
import { FusionDocumentStoreInfo } from '../main/ets/domain/FusionDocumentStoreInfo'
import { DocumentStore } from '../main/ets/domain/DocumentStore'
import { LayerStore } from '../main/ets/domain/LayerStore'
import { LayerBlendStore, getBlendModeLabel } from '../main/ets/domain/LayerBlendStore'
import { ToolStore } from '../main/ets/features/canvas/state/ToolStore'
import { ColorStore } from '../main/ets/features/color/state/ColorStore'
import { ThemeStore } from '../main/ets/features/workspace/state/ThemeStore'
import { ToastStore } from '../main/ets/features/common/state/ToastStore'
import { BYOKStore } from '../main/ets/features/ai/state/BYOKStore'

function asciiBytes(text: string): number[] {
  const result: number[] = []
  for (let i = 0; i < text.length; i++) {
    result.push(text.charCodeAt(i))
  }
  return result
}

function toArrayBuffer(values: number[]): ArrayBuffer {
  const source = new Uint8Array(values)
  const target = new ArrayBuffer(source.length)
  new Uint8Array(target).set(source)
  return target
}

export default function localUnitTest() {
  describe('PersistenceTypesTest', () => {
    it('checksumIsDeterministic', 0, () => {
      const a = textChecksum('{"version":"3.0","scene":{"frames":[]}}')
      const b = textChecksum('{"version":"3.0","scene":{"frames":[]}}')
      expect(a).assertEqual(b)
    })
    it('checksumDistinguishesInput', 0, () => {
      const a = textChecksum('{"frames":[1]}')
      const b = textChecksum('{"frames":[2]}')
      expect(a === b).assertFalse()
    })
    it('checksumFormatIsStable', 0, () => {
      const empty = textChecksum('')
      const unicode = textChecksum('画布文档-恢复')
      expect(empty.length).assertEqual(16)
      expect(unicode.length).assertEqual(16)
      expect(/^[0-9a-f]{16}$/.test(empty)).assertTrue()
      expect(/^[0-9a-f]{16}$/.test(unicode)).assertTrue()
    })
    it('copyBytesCopiesOnlyTheRequestedView', 0, () => {
      const source = new ArrayBuffer(6)
      const view = new Uint8Array(source, 1, 4)
      view[0] = 0x50
      view[1] = 0x44
      view[2] = 0x46
      view[3] = 0x21
      const copied = copyBytes(view)
      expect(copied.byteLength).assertEqual(4)
      expect(matchesMagic(copied, asciiMagic('PDF!'), 0)).assertTrue()
    })
    it('readResultShapes', 0, () => {
      const ok = readOk('{"a":1}', '/data/eldoc.json')
      expect(ok.ok).assertTrue()
      expect(ok.json).assertEqual('{"a":1}')
      expect(ok.code).assertNull()
      const failed = readFailed('not-found', 'document file does not exist', '/data/eldoc.json')
      expect(failed.ok).assertFalse()
      expect(failed.code).assertEqual('not-found')
      expect(failed.json).assertNull()
    })
    it('writeResultShapes', 0, () => {
      const ok = writeOk('/data/eldoc.json', 128, '0123456789abcdef')
      expect(ok.ok).assertTrue()
      expect(ok.bytes).assertEqual(128)
      expect(ok.checksum).assertEqual('0123456789abcdef')
      const failed = writeFailed('short-write', 'written=3 expected=5', '/data/eldoc.json')
      expect(failed.ok).assertFalse()
      expect(failed.code).assertEqual('short-write')
      expect(failed.bytes).assertEqual(0)
      expect(failed.checksum).assertEqual('')
    })
    it('imageStructureRejectsMismatchedMagic', 0, () => {
      const png = toArrayBuffer([...PNG_MAGIC, 0x00])
      const jpeg = toArrayBuffer([...JPEG_MAGIC, 0x00])
      const webp = toArrayBuffer([...asciiBytes('RIFF'), 0x00, 0x00, 0x00, 0x00, ...asciiBytes('WEBP')])
      const pngCheck = verifyImageStructure(png, 'png')
      const jpegCheck = verifyImageStructure(jpeg, 'jpeg')
      const webpCheck = verifyImageStructure(webp, 'webp')
      const mismatchedCheck = verifyImageStructure(png, 'jpeg')
      const invalidPngCheck = verifyImageStructure(toArrayBuffer([0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50]), 'png')
      expect(pngCheck.ok).assertTrue()
      expect(jpegCheck.ok).assertTrue()
      expect(webpCheck.ok).assertTrue()
      expect(mismatchedCheck.ok).assertFalse()
      expect(invalidPngCheck.ok).assertFalse()
    })
    it('jsonTextStructureRejectsMalformedText', 0, () => {
      const validCheck = verifyJsonText('{"version":"3.0","scene":{}}')
      const invalidCheck = verifyJsonText('{"version":')
      expect(validCheck.ok).assertTrue()
      expect(invalidCheck.ok).assertFalse()
    })
    it('svgTextStructureRequiresEnvelope', 0, () => {
      const validCheck = verifySvgText('<?xml version="1.0" encoding="UTF-8"?>\n<svg></svg>')
      const missingDeclaration = verifySvgText('<svg></svg>')
      const missingEndTag = verifySvgText('<?xml version="1.0"?><svg>')
      expect(validCheck.ok).assertTrue()
      expect(missingDeclaration.ok).assertFalse()
      expect(missingEndTag.ok).assertFalse()
    })
    it('pdfStructureRequiresValidCrossReferenceOffset', 0, () => {
      const validPdf = '%PDF-1.4\n1 0 obj\n<< /Type /Page >>\nendobj\nxref\n0 2\n0000000000 65535 f \n0000000009 00000 n \ntrailer\n<< /Size 2 >>\nstartxref\n42\n%%EOF\n'
      const validBytes = toArrayBuffer(asciiBytes(validPdf))
      const validCheck = verifyPdfStructure(validBytes)
      expect(validCheck.ok).assertTrue()
      const invalidPdf = validPdf.replace('startxref\n42', 'startxref\n43')
      const invalidCheck = verifyPdfStructure(toArrayBuffer(asciiBytes(invalidPdf)))
      expect(invalidCheck.ok).assertFalse()
    })
  })

  describe('DomainPublicEntryTest', () => {
    it('domainEntriesRoundTripDocumentContent', 0, () => {
      const doc: HdsDocument = {
        version: '3.0',
        scene: createScene({ name: '迁移验证文档' }),
        metadata: {
          createdAt: '2026-08-19T00:00:00.000Z',
          modifiedAt: '2026-08-19T00:00:00.000Z',
        },
      }
      const layer = addLayer(doc, '正文')
      const shape = createShapeObject({ name: '矩形', x: 12, y: 24, width: 80, height: 40 })
      expect(addObjectToLayer(doc, layer.id, shape)).assertTrue()

      const restored = deserialize(serialize(doc))
      expect(restored.scene.name).assertEqual('迁移验证文档')
      expect(restored.scene.children[0].name).assertEqual('正文')
      expect(restored.scene.children[0].objects[0].name).assertEqual('矩形')
      expect(restored.scene.children[0].objects[0].transform.x).assertEqual(12)
    })

    it('domainOperationsCalculateFrameBoundsAndPlacement', 0, () => {
      const doc: HdsDocument = {
        version: '3.0',
        scene: createScene(),
        metadata: {
          createdAt: '2026-08-19T00:00:00.000Z',
          modifiedAt: '2026-08-19T00:00:00.000Z',
        },
      }
      const first = addFrame(doc, 'single', '首页', 10, 20)
      const second = addFrame(doc, 'single', '第二页')
      const bounds = getFramesBoundingBox(doc)

      expect(second.x).assertEqual(first.x + first.width + 80)
      expect(second.y).assertEqual(first.y)
      expect(bounds?.minX).assertEqual(10)
      expect(bounds?.maxX).assertEqual(second.x + second.width)
    })
  })

  describe('StoreVerticalSliceTest', () => {
    it('featureStateEntriesExposeAndMutateMemoryState', 0, () => {
      const tools = ToolStore.getInstance()
      tools.selectTool('shape', '矩形')
      expect(tools.activeToolName).assertEqual('矩形')

      const colors = ColorStore.getInstance()
      colors.addFavorite('#aabbcc')
      expect(colors.favoriteColors.includes('#AABBCC')).assertTrue()

      const theme = ThemeStore.getInstance()
      expect(theme.currentTheme.id).assertEqual(theme.currentThemeId)
    })

    it('domainStoreEntriesExposeTheDocumentFacade', 0, () => {
      const fusion = FusionDocumentStore.getInstance()
      const document = DocumentStore.getInstance()
      const info: FusionDocumentStoreInfo = fusion.getSceneInfo()

      expect(document.docName).assertEqual(fusion.getScene().name)
      expect(info.layerCount >= 0).assertTrue()
      expect(info.objectCount >= 0).assertTrue()
    })

    it('domainLayerEntriesExposeSelectionAndBlendOperations', 0, () => {
      const layers = LayerStore.getInstance()
      const blends = LayerBlendStore.getInstance()

      expect(layers.getSelectedLayerId()).assertEqual('')
      expect(blends !== undefined).assertTrue()
      expect(getBlendModeLabel('multiply')).assertEqual('正片叠底')
    })

    it('commonAndAiStateEntriesConstructWithoutInitialization', 0, () => {
      const toasts = ToastStore.getInstance()
      const byok = BYOKStore.getInstance()

      expect(toasts.toasts.length).assertEqual(0)
      expect(byok.config.provider).assertEqual('deepseek')
    })
  })
}
