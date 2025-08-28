// 根据一个资源引用 (Resource)，获取其对应的颜色值，并将其转换成 UI 组件可以直接使用的十六进制颜色字符串（如 #FF0000）。
export class ResourceUtil {
  static getResourceColorString(component: Object, resource: Resource):string {
    let resString:string = '#' + getContext(component).resourceManager.getColorSync(resource).toString(16)
    return resString;
  }
}