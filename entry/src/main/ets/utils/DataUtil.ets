import { JSON } from '@kit.ArkTS';


export class DataUtil {
  static jsonParseMap(jsonStr: string) {

    let jsonObj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>

    let newMap: Map<string, object> = new Map<string, object>(Object.entries(jsonObj));
    return newMap;
  }

  static jsonString2Map<K, V>(jsonStr: string) {

    let data: [K, V][] = JSON.parse(jsonStr) as [K, V][]

    const newMap = new Map<K, V>();
    for (let i = 0; i < data.length; i++) {
      const key = data[i][0];      // 元组的第一个元素作为 key
      const value = data[i][1];    // 元组的第二个元素作为 value
      newMap.set(key, value);         // 将键值对添加到 Map 中
    }
    return newMap;
  }

  //map转为json字符串
  static mapParseJson(map: Map<string, Object>): string {
    let obj: Record<string, Object> = {};
    map.forEach((value, key) => {
      if (key != undefined && key != null) {
        obj[key] = value;
      }
    })
    let jsonStr = JSON.stringify(obj)
    return jsonStr
  }

  static mapParseJsonNumber(map: Map<number, Object>): string {
    let obj: Record<string, Object> = {};
    map.forEach((value, key) => {
      if (key != undefined && key != null) {
        obj[key] = value;
      }
    })
    let jsonStr = JSON.stringify(obj)
    return jsonStr
  }

  static map2JsonString<K, V>(map: Map<K, V>): string {
    let arr = Array.from(map.entries())
    let jsonString = JSON.stringify(arr)
    return jsonString
  }
}