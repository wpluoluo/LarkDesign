import { describe, it, expect } from '@ohos/hypium'
import {
  textChecksum,
  readOk,
  readFailed,
  writeOk,
  writeFailed,
} from '../main/ets/platform/PersistenceTypes'

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
  })
}
