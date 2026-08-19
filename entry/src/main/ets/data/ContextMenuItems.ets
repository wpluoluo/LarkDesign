import { ContextMenuItem } from '../domain/SceneTypes'

function mergeItems(a: ContextMenuItem[], b: ContextMenuItem[]): ContextMenuItem[] {
  const result: ContextMenuItem[] = []
  for (let i = 0; i < a.length; i++) {
    result.push(a[i])
  }
  for (let i = 0; i < b.length; i++) {
    result.push(b[i])
  }
  return result
}

const layerOrder: ContextMenuItem[] = [
  { label: '图层顺序', icon: 'fa-layer-group', disabled: true },
  { label: '移到顶层', icon: 'fa-arrow-up', shortcut: 'Ctrl+Shift+]', action: 'bringToFront' },
  { label: '上移一层', icon: 'fa-chevron-up', shortcut: 'Ctrl+]', action: 'bringForward' },
  { label: '下移一层', icon: 'fa-chevron-down', shortcut: 'Ctrl+[', action: 'sendBackward' },
  { label: '移到底层', icon: 'fa-arrow-down', shortcut: 'Ctrl+Shift+[', action: 'sendToBack' },
]

function buildCommonActions(): ContextMenuItem[] {
  let items: ContextMenuItem[] = []
  items.push({ label: '剪切', icon: 'fa-scissors', shortcut: 'Ctrl+X', action: 'cut' })
  items.push({ label: '复制', icon: 'fa-copy', shortcut: 'Ctrl+C', action: 'copy' })
  items.push({ label: '粘贴', icon: 'fa-paste', shortcut: 'Ctrl+V', action: 'paste' })
  items.push({ divider: true })
  items = mergeItems(items, layerOrder)
  items.push({ divider: true })
  items.push({ label: '编组', icon: 'fa-object-group', shortcut: 'Ctrl+G', action: 'group' })
  items.push({ label: '解组', icon: 'fa-object-ungroup', shortcut: 'Ctrl+Shift+G', action: 'ungroup' })
  items.push({ label: '锁定', icon: 'fa-lock', shortcut: 'Ctrl+L', action: 'lock' })
  items.push({ label: '解锁', icon: 'fa-lock-open', shortcut: 'Ctrl+Shift+L', action: 'unlock' })
  items.push({ label: '隐藏', icon: 'fa-eye-slash', shortcut: 'Ctrl+3', action: 'hide' })
  items.push({ divider: true })
  items.push({ label: '复制图层', icon: 'fa-copy', shortcut: 'Ctrl+J', action: 'duplicateLayer' })
  items.push({ label: '合并图层', icon: 'fa-layer-group', shortcut: 'Ctrl+E', action: 'mergeDown' })
  items.push({ divider: true })
  items.push({ label: '删除', icon: 'fa-trash', shortcut: 'Delete', action: 'delete', danger: true })
  return items
}

export const textCtxItems: ContextMenuItem[] = (() => {
  let items: ContextMenuItem[] = []
  items.push({ label: '编辑文字', icon: 'fa-font', action: 'editText' })
  items.push({ label: '复制文本', icon: 'fa-copy', shortcut: 'Ctrl+C', action: 'copyText' })
  items.push({ divider: true })
  items = mergeItems(items, buildCommonActions())
  items.push({ divider: true })
  items.push({ label: '字体设置', icon: 'fa-font', shortcut: 'Ctrl+T', action: 'fontSettings' })
  items.push({ label: '段落设置', icon: 'fa-paragraph', shortcut: 'Ctrl+Alt+T', action: 'paragraphSettings' })
  items.push({ label: '字符样式', icon: 'fa-pen', action: 'charStyle' })
  items.push({ label: '段落样式', icon: 'fa-align-left', action: 'paraStyle' })
  items.push({ divider: true })
  items.push({ label: '加粗', icon: 'fa-bold', shortcut: 'Ctrl+B', action: 'bold' })
  items.push({ label: '斜体', icon: 'fa-italic', shortcut: 'Ctrl+I', action: 'italic' })
  items.push({ label: '下划线', icon: 'fa-underline', shortcut: 'Ctrl+U', action: 'underline' })
  items.push({ label: '删除线', icon: 'fa-strikethrough', action: 'strikethrough' })
  items.push({ divider: true })
  items.push({ label: '增大字号', icon: 'fa-plus', shortcut: 'Ctrl+Shift+>', action: 'increaseFont' })
  items.push({ label: '减小字号', icon: 'fa-minus', shortcut: 'Ctrl+Shift+<', action: 'decreaseFont' })
  items.push({ label: '创建轮廓', icon: 'fa-vector-square', shortcut: 'Ctrl+Shift+O', action: 'createOutline' })
  items.push({ label: '适合标题', icon: 'fa-text-height', action: 'fitHeadline' })
  items.push({ label: 'OpenType 特性', icon: 'fa-gear', action: 'openType' })
  items.push({ label: '更改大小写', icon: 'fa-text-slash', action: 'changeCase' })
  items.push({ label: '路径文字', icon: 'fa-pen-nib', action: 'pathText' })
  return items
})()

export const imageCtxItems: ContextMenuItem[] = (() => {
  let items: ContextMenuItem[] = []
  items.push({ label: '替换图片', icon: 'fa-image', action: 'replaceImage' })
  items.push({ label: '编辑原件', icon: 'fa-pen', action: 'editOriginal' })
  items.push({ label: '调整图像', icon: 'fa-sliders', action: 'adjustImage' })
  items.push({ label: '裁剪', icon: 'fa-crop', shortcut: 'C', action: 'cropImage' })
  items.push({ label: '变换', icon: 'fa-up-right-and-down-left-from-center', shortcut: 'Ctrl+T', action: 'freeTransform' })
  items.push({ divider: true })
  items = mergeItems(items, buildCommonActions())
  items.push({ divider: true })
  items.push({ label: '添加图层蒙版', icon: 'fa-circle-half-stroke', action: 'addMask' })
  items.push({
    label: '调整...', icon: 'fa-sliders', action: 'adjustments', children: [
      { label: '色阶', icon: 'fa-chart-simple', action: 'levels' },
      { label: '曲线', icon: 'fa-chart-line', action: 'curves' },
      { label: '色相/饱和度', icon: 'fa-palette', action: 'hueSaturation' },
      { label: '亮度/对比度', icon: 'fa-sun', action: 'brightnessContrast' },
      { label: '色彩平衡', icon: 'fa-scale-balanced', action: 'colorBalance' },
      { label: '黑白', icon: 'fa-circle', action: 'blackWhite' },
    ],
  })
  items.push({
    label: '滤镜', icon: 'fa-wand-magic-sparkles', action: 'filters', children: [
      { label: '高斯模糊', icon: 'fa-droplet', action: 'gaussianBlur' },
      { label: '锐化', icon: 'fa-bolt', action: 'sharpen' },
      { label: '杂色', icon: 'fa-border-all', action: 'noise' },
      { label: '扭曲', icon: 'fa-wand-magic-sparkles', action: 'distort' },
    ],
  })
  items.push({ label: '转换为智能对象', icon: 'fa-brain', action: 'smartObject' })
  items.push({ label: '栅格化', icon: 'fa-border-all', action: 'rasterize' })
  items.push({ label: '导出为...', icon: 'fa-download', action: 'exportImage' })
  return items
})()

export const shapeCtxItems: ContextMenuItem[] = (() => {
  let items: ContextMenuItem[] = []
  items.push({ label: '编辑路径', icon: 'fa-pen-nib', action: 'editPath' })
  items.push({ label: '填充颜色', icon: 'fa-fill-drip', action: 'fillColor' })
  items.push({ label: '描边设置', icon: 'fa-pen', action: 'strokeSettings' })
  items.push({ label: '变换', icon: 'fa-up-right-and-down-left-from-center', shortcut: 'Ctrl+T', action: 'freeTransform' })
  items.push({ divider: true })
  items = mergeItems(items, buildCommonActions())
  items.push({ divider: true })
  items.push({
    label: '路径查找器', icon: 'fa-object-group', action: 'pathfinder', children: [
      { label: '合集', icon: 'fa-object-group', action: 'unite' },
      { label: '差集', icon: 'fa-object-ungroup', action: 'minusFront' },
      { label: '交集', icon: 'fa-vector-square', action: 'intersect' },
      { label: '排除', icon: 'fa-square', action: 'exclude' },
    ],
  })
  items.push({ label: '转换为曲线', icon: 'fa-bezier-curve', action: 'convertToCurve' })
  items.push({ label: '圆角设置', icon: 'fa-sliders', action: 'cornerRadius' })
  items.push({ label: '扩展外观', icon: 'fa-expand', action: 'expandAppearance' })
  items.push({
    label: '效果设置', icon: 'fa-wand-magic-sparkles', action: 'shapeEffects', children: [
      { label: '投影', icon: 'fa-layer-group', action: 'dropShadow' },
      { label: '内阴影', icon: 'fa-circle', action: 'innerShadow' },
      { label: '外发光', icon: 'fa-sun', action: 'outerGlow' },
      { label: '内发光', icon: 'fa-circle', action: 'innerGlow' },
      { label: '模糊', icon: 'fa-droplet', action: 'blur' },
    ],
  })
  items.push({ label: '渐变填充', icon: 'fa-fill-drip', action: 'gradientFill' })
  items.push({ label: '复制样式', icon: 'fa-copy', action: 'copyStyle' })
  items.push({ label: '粘贴样式', icon: 'fa-paste', action: 'pasteStyle' })
  return items
})()

export const pageCtxItems: ContextMenuItem[] = [
  { label: '粘贴', icon: 'fa-paste', shortcut: 'Ctrl+V', action: 'paste' },
  { label: '粘贴到前面', icon: 'fa-copy', shortcut: 'Ctrl+F', action: 'pasteInFront' },
  { label: '粘贴到后面', icon: 'fa-copy', shortcut: 'Ctrl+B', action: 'pasteInBack' },
  { label: '全选', icon: 'fa-object-group', shortcut: 'Ctrl+A', action: 'selectAll' },
  { label: '取消选择', icon: 'fa-xmark', shortcut: 'Ctrl+D', action: 'deselect' },
  { divider: true },
  { label: '页面设置', icon: 'fa-gear', action: 'pageSetup' },
  { label: '边距与分栏', icon: 'fa-table', action: 'marginsColumns' },
  { label: '出血设置', icon: 'fa-expand', action: 'bleedSettings' },
  { label: '网格设置', icon: 'fa-border-all', action: 'gridSettings' },
  {
    label: '参考线', icon: 'fa-plus', action: 'guideSettings', children: [
      { label: '锁定参考线', shortcut: 'Ctrl+Alt+;', icon: 'fa-lock', action: 'lockGuides' },
      { label: '清除参考线', icon: 'fa-trash', action: 'clearGuides' },
      { label: '新建参考线', icon: 'fa-plus', action: 'newGuide' },
    ],
  },
  { divider: true },
  { label: '色彩空间', icon: 'fa-palette', action: 'colorSpace' },
  { label: '文档设置', icon: 'fa-sliders', shortcut: 'Ctrl+Alt+P', action: 'docSettings' },
]

export const canvasCtxItems: ContextMenuItem[] = [
  { label: '粘贴', icon: 'fa-paste', shortcut: 'Ctrl+V', action: 'paste' },
  { label: '全选', icon: 'fa-object-group', shortcut: 'Ctrl+A', action: 'selectAll' },
  { divider: true },
  { label: '标尺', icon: 'fa-ruler', shortcut: 'Ctrl+R', action: 'toggleRuler' },
  { label: '网格', icon: 'fa-border-all', shortcut: 'Ctrl+"', action: 'toggleGrid' },
  {
    label: '参考线', icon: 'fa-plus', action: 'guideSettings', children: [
      { label: '锁定参考线', shortcut: 'Ctrl+Alt+;', icon: 'fa-lock', action: 'lockGuides' },
      { label: '清除参考线', icon: 'fa-trash', action: 'clearGuides' },
      { label: '新建参考线', icon: 'fa-plus', action: 'newGuide' },
    ],
  },
  { label: '吸附', icon: 'fa-magnet', shortcut: 'Ctrl+Shift+;', action: 'toggleSnap' },
  { divider: true },
  { label: '放大', icon: 'fa-magnifying-glass-plus', shortcut: 'Ctrl++', action: 'zoomIn' },
  { label: '缩小', icon: 'fa-magnifying-glass-minus', shortcut: 'Ctrl+-', action: 'zoomOut' },
  { label: '适配画布', icon: 'fa-expand', shortcut: 'Ctrl+0', action: 'fitCanvas' },
  { label: '实际像素', icon: 'fa-eye', shortcut: 'Ctrl+1', action: 'actualPixels' },
  { divider: true },
  {
    label: '显示设置', icon: 'fa-display', action: 'displaySettings', children: [
      { label: '画布颜色...', icon: 'fa-palette', action: 'canvasColor' },
      { label: '显示页面阴影', icon: 'fa-square', action: 'togglePageShadow' },
      { label: '显示页面边界', icon: 'fa-border-all', action: 'togglePageBorder' },
    ],
  },
  { label: '视图旋转', icon: 'fa-rotate', shortcut: 'R', action: 'rotateView' },
]

export const pageListItemCtxItems: ContextMenuItem[] = [
  { label: '新建页面', icon: 'fa-file', shortcut: 'Ctrl+Shift+P', action: 'new' },
  { label: '复制页面', icon: 'fa-copy', shortcut: 'Ctrl+J', action: 'duplicate' },
  { label: '重命名', icon: 'fa-pen', action: 'rename' },
  { divider: true },
  { label: '上移', icon: 'fa-chevron-up', shortcut: 'Ctrl+↑', action: 'moveUp' },
  { label: '下移', icon: 'fa-chevron-down', shortcut: 'Ctrl+↓', action: 'moveDown' },
  { divider: true },
  { label: '应用母版', icon: 'fa-layer-group', action: 'applyMaster' },
  { label: '页面设置', icon: 'fa-gear', action: 'settings' },
  {
    label: '导出页面', icon: 'fa-download', action: 'exportPage', children: [
      { label: '导出为 PNG', icon: 'fa-file-image', action: 'exportPng' },
      { label: '导出为 PDF', icon: 'fa-file-pdf', action: 'exportPdf' },
      { label: '导出为 JPG', icon: 'fa-file-image', action: 'exportJpg' },
    ],
  },
  { divider: true },
  { label: '删除页面', icon: 'fa-trash', action: 'delete', danger: true },
]

export function getCtxItemsByType(type: string): ContextMenuItem[] {
  if (type === 'text') {
    return textCtxItems
  }
  if (type === 'image') {
    return imageCtxItems
  }
  if (type === 'shape') {
    return shapeCtxItems
  }
  if (type === 'page') {
    return pageCtxItems
  }
  return canvasCtxItems
}
