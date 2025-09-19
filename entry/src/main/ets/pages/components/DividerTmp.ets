// 导出一个名为 DividerTmp 的类
export class DividerTmp {
  // 定义类的成员属性，并提供默认值
  strokeWidth: Length = 1 // 分割线的粗细，默认为 1
  startMargin: Length = 10 // 分割线距离开始边的间距，默认为 10
  endMargin: Length = 10 // 分割线距离结束边的间距，默认为 10
  color: ResourceColor = '#ffe9f0f0' // 分割线的颜色，默认为一个浅灰色

  constructor(strokeWidth: Length, startMargin: Length, endMargin: Length, color: ResourceColor) {
    this.strokeWidth = strokeWidth
    this.startMargin = startMargin
    this.endMargin = endMargin
    this.color = color
  }
}