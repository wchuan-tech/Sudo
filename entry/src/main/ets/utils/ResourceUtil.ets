export class ResourceUtil {
  static getResourceColorString(component: Object, resource: Resource):string {
    let resString:string = '#' + getContext(component).resourceManager.getColorSync(resource).toString(16)
    return resString;
  }
}