import { LengthMetrics, promptAction } from "@kit.ArkUI"; // 1. 确保 promptAction 已导入
import { StyleConstants } from "../../constants/StyleConstants";

@Component
export struct Header {

  @Link currentBreakpoint: string;

  build() {
    Column() {

      // --- AppName (保持不变) ---
      Text($r("app.string.AppName"))
        .id("app")
        .textAlign(TextAlign.Center)
        .fontSize($r('app.float.title_font_size'))
        .width(StyleConstants.FULL_WIDTH)
        .fontColor($r('app.color.title_font_color'));

      // --- 游戏规则与介绍 (核心修改) ---
      Text("点击查看游戏规则与介绍") // 2. 更新文本内容，引导用户点击
        .fontSize($r('app.float.description_font_size'))
        .fontColor($r('app.color.bar_selected_color')) // 3. 建议使用主题色，使其看起来像一个链接
        .textAlign(TextAlign.Center) // 居中对齐
        .margin({ top: 10 }) // 与上下增加一些间距
        .padding({ top: 8, bottom: 8 }) // 增加点击区域
          // 4. 【核心】添加 onClick 事件
        .onClick(() => {
          promptAction.showToast({
            message: $r("app.string.AppDescribe"),
            duration: 5000 // 设置持续时间为5秒，以便用户能读完
          });
        });
    }
  }
}