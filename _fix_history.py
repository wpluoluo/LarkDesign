with open(r'F:\LarkDesign\entry\src\main\ets\components\HistoryPanel.ets', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "import { IconCharToken as Icon } from '../tokens/IconToken'",
    "import { IconCharToken as Icon } from '../tokens/IconToken'\nimport { FusionDocumentStore } from '../stores/FusionDocumentStore'"
)

content = content.replace(
    '@Component\nexport struct HistoryPanel {',
    '@Component\nexport struct HistoryPanel {\n  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()'
)

content = content.replace(
    '  @State undoCount: number = 5\n  @State redoCount: number = 2',
    '  @State undoCount: number = 0\n  @State redoCount: number = 0'
)

content = content.replace(
    '  @State panelWidth: number = 200',
    '  @State panelWidth: number = 200\n\n  aboutToAppear(): void {\n    this.syncHistory()\n  }\n\n  private syncHistory(): void {\n    this.undoCount = this.fusionStore.getHistoryUndoCount()\n    this.redoCount = this.fusionStore.getHistoryRedoCount()\n  }'
)

with open(r'F:\LarkDesign\entry\src\main\ets\components\HistoryPanel.ets', 'w', encoding='utf-8') as f:
    f.write(content)

print('HistoryPanel fixed')
