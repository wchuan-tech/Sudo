import { LengthMetrics } from "@kit.ArkUI"
import { StyleConstants } from "../../common/constants/StyleConstants";

@Component
export struct Header {

  @Link currentBreakpoint: string

  build() {
    Column() {
      Text($r("app.string.AppName")) {
      }
      .id("app")
      .textAlign(TextAlign.Center)
      .fontSize($r('app.float.title_font_size'))
      .width(StyleConstants.FULL_WIDTH)
      .fontColor($r('app.color.title_font_color'))

      Text($r("app.string.AppDescribe")) {
      }
      .id("describe")
      .opacity(0.58)
      .margin({ top: 10, left: 5, right: 5 })
      .fontSize($r('app.float.description_font_size'))
      .lineSpacing(LengthMetrics.fp(18))
      .fontColor($r('app.color.normal_font_color'))
      .width(StyleConstants.FULL_WIDTH)

    }
  }
}