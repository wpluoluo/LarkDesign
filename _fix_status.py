with open(r'F:\LarkDesign\entry\src\main\ets\components\StatusBar.ets', 'r', encoding='utf-8') as f:
    content = f.read()

# Connect syncText to AppStorage
content = content.replace(
    "  @State syncText: string = '\u5df2\u540c\u6b65'",
    "  @StorageLink('hds_save_status') syncText: string = '\u5df2\u540c\u6b65'\n  @StorageLink('hds_last_saved') lastSaved: string = ''"
)

with open(r'F:\LarkDesign\entry\src\main\ets\components\StatusBar.ets', 'w', encoding='utf-8') as f:
    f.write(content)

print('StatusBar sync indicator updated')
