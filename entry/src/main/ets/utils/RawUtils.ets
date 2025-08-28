import { BusinessError } from '@ohos.base';
import { util } from '@kit.ArkTS';
import { LogUtil } from './LogUtil';

export class RawUtils {

  static xorKey: number = 1618;

  // 函数功能：调用解码函数 将.txt 文件的原始、未加密时的文本内容 解密出来
  static readRawConfigData(difficulty: string, level: number): string | null {
    let filePath = difficulty + '_data/' + level + '.txt'
    try {
      let buffer = getContext().resourceManager.getRawFileContentSync(filePath);
      let content = RawUtils.decryptFile(buffer)
      return content
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      // LogUtil.error(`getRawFileContentSync failed, error code: ${code}, message: ${message}.`);
      return null
    }
	}


  // 解码函数
  static decryptFile(buffer: Uint8Array): string | null {
    LogUtil.debug("decryptFile " + buffer.length)
    try {
      // 4. 对每个字节进行异或解密

      // 5. 将解密后的字节数组转换为字符串
      let textDecoderOptions: util.TextDecoderOptions = {
        fatal: false,
        ignoreBOM : true
      }
      let decodeToStringOptions: util.DecodeToStringOptions = {
        stream: false
      }
      // 将字节数组转换为字符串
      let decoder = util.TextDecoder.create('utf-8', textDecoderOptions)
      let content:string = decoder.decodeToString(buffer, decodeToStringOptions);
      // 将字符串异或解密成新的字符串
      let decryptedContent = RawUtils.xorEncryptDecrypt(content, RawUtils.xorKey)
      // LogUtil.debug(" length = " +　decryptedContent.length)
      // LogUtil.debug("decryptFile " +　decryptedContent)
      return decryptedContent;  // 返回解密后的字符串
    } catch (error) {
      LogUtil.error("文件读取或解密失败:", error);
      return null;
    }
  }


  // 具体解码方法
  static  xorEncryptDecrypt(content: string, key: number): string {
    return content
      .split('')
      .map(char => String.fromCharCode(char.charCodeAt(0) ^ key))
      .join('');
  }

}