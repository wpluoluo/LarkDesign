with open(r'F:\LarkDesign\entry\src\main\ets\components\Inspector.ets', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the import section to add FusionDocumentStore
for i, line in enumerate(lines):
    if "import { IconCharToken as Icon }" in line:
        lines.insert(i+1, "import { FusionDocumentStore } from '../stores/FusionDocumentStore'\n")
        break

# Find the last @State declaration
last_state_idx = -1
for i, line in enumerate(lines):
    if '@State' in line:
        last_state_idx = i

# Find the first method/field after the last @State
insert_idx = -1
for i in range(last_state_idx+1, len(lines)):
    stripped = lines[i].strip()
    if stripped.startswith('private ') or stripped.startswith('public ') or stripped.startswith('build()') or stripped == '}':
        insert_idx = i
        break

if insert_idx > 0:
    new_lines = [
        '  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()\n',
        '\n',
        '  aboutToAppear(): void {\n',
        '    this.syncSelection()\n',
        '  }\n',
        '\n',
        '  /** 同步选中对象属性 */\n',
        '  private syncSelection(): void {\n',
        '    const sel = this.fusionStore.getSelectedObjects()\n',
        '    if (sel.length > 0) {\n',
        '      const obj = sel[0]\n',
        '      this.transformX = obj.transform.x\n',
        '      this.transformY = obj.transform.y\n',
        '      this.transformW = obj.transform.width\n',
        '      this.transformH = obj.transform.height\n',
        '      this.transformRot = obj.transform.rotation\n',
        '      this.transformScale = obj.transform.scaleX * 100\n',
        '      this.selectedObjectName = obj.name\n',
        '    } else {\n',
        '      const frame = this.fusionStore.getCurrentFrame()\n',
        '      if (frame) {\n',
        '        this.frameName = frame.name\n',
        '        this.frameX = frame.x\n',
        '        this.frameY = frame.y\n',
        '        this.frameW = frame.width\n',
        '        this.frameH = frame.height\n',
        '        this.frameBackground = frame.background if frame.background else "#FFFFFF"\n',
        '      }\n',
        '    }\n',
        '  }\n',
        '\n',
        '  /** 更新变换属性到 Store */\n',
        '  private updateTransform(): void {\n',
        '    const sel = this.fusionStore.getSelectedObjects()\n',
        '    if (sel.length > 0) {\n',
        '      const obj = sel[0]\n',
        '      obj.transform.x = this.transformX\n',
        '      obj.transform.y = this.transformY\n',
        '      obj.transform.width = this.transformW\n',
        '      obj.transform.height = this.transformH\n',
        '      obj.transform.rotation = this.transformRot\n',
        '      obj.transform.scaleX = this.transformScale / 100\n',
        '      obj.transform.scaleY = this.transformScale / 100\n',
        '    }\n',
        '  }\n',
        '\n',
        '  /** 更新 Frame 属性到 Store */\n',
        '  private updateFrameProps(): void {\n',
        '    const frame = this.fusionStore.getCurrentFrame()\n',
        '    if (frame) {\n',
        '      this.fusionStore.updateFrameById(frame.id, this.frameX, this.frameY, this.frameW, this.frameH, this.frameName)\n',
        '    }\n',
        '  }\n',
        '\n',
    ]
    for idx, nl in enumerate(new_lines):
        lines.insert(insert_idx + idx, nl)

with open(r'F:\LarkDesign\entry\src\main\ets\components\Inspector.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Inspector.ets updated with bidirectional binding')
