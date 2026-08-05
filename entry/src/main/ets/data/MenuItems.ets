/**
 * MenuItems - 菜单数据定义（ArkUI 版）
 *
 * 对应原型 src/data/menuItems.ts
 * 完整多级菜单数据
 */

export interface SubMenuItem {
  label?: string
  shortcut?: string
  icon?: string
  divider?: boolean
  disabled?: boolean
  children?: SubMenuItem[]
}

export interface MenuBarItem {
  label: string
  children: SubMenuItem[]
}

export const MENU_ITEMS: MenuBarItem[] = [
  {
    label: '文件',
    children: [
      { label: '新建', shortcut: 'Ctrl+N', children: [
        { label: '默认文档' },
        { label: '单页海报' },
        { label: '画册' },
        { label: '社交媒体' },
        { label: '自定义尺寸' },
        { label: '从模板...' },
      ]},
      { label: '打开', shortcut: 'Ctrl+O' },
      { label: '关闭', shortcut: 'Ctrl+W' },
      { divider: true },
      { label: '保存', shortcut: 'Ctrl+S' },
      { label: '另存为', shortcut: 'Ctrl+Shift+S' },
      { divider: true },
      { label: '导出', shortcut: 'Ctrl+E', children: [
        { label: '导出为 PNG' },
        { label: '导出为 PDF' },
        { label: '导出为 SVG' },
      ]},
      { divider: true },
      { label: '打印', shortcut: 'Ctrl+P' },
      { label: '退出', shortcut: 'Ctrl+Q' },
    ],
  },
  {
    label: '编辑',
    children: [
      { label: '撤销', shortcut: 'Ctrl+Z' },
      { label: '重做', shortcut: 'Ctrl+Shift+Z' },
      { divider: true },
      { label: '剪切', shortcut: 'Ctrl+X' },
      { label: '复制', shortcut: 'Ctrl+C' },
      { label: '粘贴', shortcut: 'Ctrl+V' },
      { label: '清除', shortcut: 'Delete' },
      { divider: true },
      { label: '自由变换', shortcut: 'Ctrl+T' },
      { label: '变换', children: [
        { label: '缩放' },
        { label: '旋转' },
        { label: '斜切' },
      ]},
      { divider: true },
      { label: '偏好设置', shortcut: 'Ctrl+K' },
    ],
  },
  {
    label: '对象',
    children: [
      { label: '编组', shortcut: 'Ctrl+G' },
      { label: '解组', shortcut: 'Ctrl+Shift+G' },
      { divider: true },
      { label: '锁定', shortcut: 'Ctrl+L' },
      { label: '解锁全部', shortcut: 'Ctrl+Shift+L' },
      { divider: true },
      { label: '排列', children: [
        { label: '上移一层', shortcut: 'Ctrl+]' },
        { label: '下移一层', shortcut: 'Ctrl+[' },
        { label: '移到顶层', shortcut: 'Ctrl+Shift+]' },
        { label: '移到底层', shortcut: 'Ctrl+Shift+[' },
      ]},
      { label: '对齐', children: [
        { label: '左对齐' },
        { label: '水平居中' },
        { label: '右对齐' },
        { label: '顶对齐' },
        { label: '垂直居中' },
        { label: '底对齐' },
      ]},
      { label: '分布', children: [
        { label: '水平分布' },
        { label: '垂直分布' },
      ]},
    ],
  },
  {
    label: '文字',
    children: [
      { label: '字符面板', shortcut: 'Ctrl+T' },
      { label: '段落面板', shortcut: 'Ctrl+Alt+T' },
      { divider: true },
      { label: '加粗', shortcut: 'Ctrl+B' },
      { label: '斜体', shortcut: 'Ctrl+I' },
      { label: '下划线', shortcut: 'Ctrl+U' },
      { divider: true },
      { label: '增大字号', shortcut: 'Ctrl+Shift+>' },
      { label: '减小字号', shortcut: 'Ctrl+Shift+<' },
      { label: '创建轮廓', shortcut: 'Ctrl+Shift+O' },
    ],
  },
  {
    label: '选择',
    children: [
      { label: '全部', shortcut: 'Ctrl+A' },
      { label: '取消选择', shortcut: 'Ctrl+D' },
      { label: '反选', shortcut: 'Ctrl+Shift+I' },
      { divider: true },
      { label: '相同', children: [
        { label: '图层类型' },
        { label: '颜色' },
        { label: '样式' },
      ]},
    ],
  },
  {
    label: '页面',
    children: [
      { label: '新建页面', shortcut: 'Ctrl+Shift+P' },
      { label: '删除页面' },
      { divider: true },
      { label: '单页显示' },
      { label: '双页显示' },
      { label: '显示跨页' },
      { divider: true },
      { label: '布局调整' },
      { label: '网格设置' },
    ],
  },
  {
    label: '效果',
    children: [
      { label: '效果画廊...', shortcut: 'Ctrl+Shift+E' },
      { divider: true },
      { label: '投影' },
      { label: '内阴影' },
      { label: '外发光' },
      { label: '内发光' },
      { label: '颜色叠加' },
      { divider: true },
      { label: '模糊', shortcut: 'Ctrl+Alt+F' },
      { label: '锐化' },
      { label: '扭曲' },
      { divider: true },
      { label: '清除效果' },
    ],
  },
  {
    label: '视图',
    children: [
      { label: '放大', shortcut: 'Ctrl++' },
      { label: '缩小', shortcut: 'Ctrl+-' },
      { label: '适配画布', shortcut: 'Ctrl+0' },
      { label: '实际像素', shortcut: 'Ctrl+1' },
      { divider: true },
      { label: '标尺', shortcut: 'Ctrl+R' },
      { label: '网格', shortcut: 'Ctrl+"' },
      { label: '参考线', shortcut: 'Ctrl+;' },
      { divider: true },
      { label: '隐藏面板', shortcut: 'Tab' },
      { label: '全屏', shortcut: 'F' },
    ],
  },
  {
    label: '窗口',
    children: [
      { label: '检查器' },
      { label: '图层' },
      { label: '色板' },
      { label: '颜色' },
      { label: '历史记录' },
      { divider: true },
      { label: '重置窗口布局' },
    ],
  },
  {
    label: '帮助',
    children: [
      { label: '搜索帮助', shortcut: 'F1' },
      { label: '用户手册', shortcut: 'Ctrl+F1' },
      { label: '键盘快捷键', shortcut: 'Ctrl+/' },
      { divider: true },
      { label: '关于 Harmony Design' },
      { label: '版本更新' },
      { label: '发送反馈' },
    ],
  },
]
