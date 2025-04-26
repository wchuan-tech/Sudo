import { CommonConstants } from "../../common/constants/CommonConstants"
import { StyleConstants } from "../../common/constants/StyleConstants"
import { DividerTmp } from "./DividerTmp"

@Preview
@Component
export struct MineView {

  @State egDivider: DividerTmp = new DividerTmp(1, CommonConstants.PADDING, CommonConstants.PADDING
    , getContext(this).resourceManager.getColorSync($r('app.color.divider_color')))

  @Consume('navPathStack')
  pathStack: NavPathStack

  @Builder
  darkMode() {
    Row() {
      Image($r('app.media.item_dark'))
        .height('100%')
        .padding({left: $r('app.float.column_padding_left')})
      Text($r('app.string.item_dark'))
        .padding({left: $r('app.float.column_padding_left')})
        .fontSize($r('app.float.description_font_size'))
        .fontColor($r('app.color.item_name_color'))
      Blank()
      Image($r("app.media.item_list_more"))
        .padding({right: CommonConstants.PADDING})
        .height('50%')
    }
    .width('100%')
    .height(CommonConstants.Item_Height)
    .onClick(() => {
      // this.pathStack.pushPath();
      this.pathStack.pushPath({name: 'PageDisplayModeSetting'})
    })
  }


  @Builder
  historyItem() {
    Row() {
      Image($r('app.media.item_rank'))
        .height('100%')
        .padding({left: $r('app.float.column_padding_left')})
      Text($r('app.string.item_statistics'))
        .padding({left: $r('app.float.column_padding_left')})
        .fontSize($r('app.float.description_font_size'))
        .fontColor($r('app.color.item_name_color'))
      Blank()
      Image($r("app.media.item_list_more"))
        .padding({right: CommonConstants.PADDING})
        .height('50%')
    }
    .width('100%')
    .height(CommonConstants.Item_Height)
    .onClick(() => {
      // this.pathStack.pushPath();
      this.pathStack.pushPath({name: 'PageRank'})
    })
  }

  @Builder
  aboutItem() {
    Row() {
      Image($r('app.media.item_about'))
        .height('100%')
        .padding({left: $r('app.float.column_padding_left')})
      Text($r('app.string.item_about'))
        .padding({left: $r('app.float.column_padding_left')})
        .fontSize($r('app.float.description_font_size'))
        .fontColor($r('app.color.item_name_color'))
      Blank()
      Image($r("app.media.item_list_more"))
        .padding({right: CommonConstants.PADDING})
        .height('50%')
    }
    .width('100%')
    .height(CommonConstants.Item_Height)
  }

  @Builder
  buildListItem(itemIcon: Resource, itemName: Resource) {
    Row() {
      Image(itemIcon)
      Text(itemName)

    }
    .width('90%')
    .height(40)
  }

  build() {
    Column() {
      Text('用户中心') {

      }
      .padding({top: $r('app.float.column_padding_top'), left: $r('app.float.column_padding_left')})
      .fontSize($r('app.float.title_font_size'))
      .textAlign(TextAlign.Center)
      .width(StyleConstants.FULL_WIDTH)
      .fontColor($r('app.color.title_color'))

      List({ space: 10 }) {
        ListItem() {
          this.darkMode()
        }
        .clickEffect({level:ClickEffectLevel.LIGHT})

        ListItem() {
          this.historyItem()
        }
        .clickEffect({level:ClickEffectLevel.LIGHT})

        // ListItem() {
        //   this.aboutItem()
        // }
        // .clickEffect({level:ClickEffectLevel.LIGHT})

      }
      .listDirection(Axis.Vertical)
      .divider(this.egDivider)
      .padding({top: $r('app.float.column_padding_top')})
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
  }
}



//
// @Builder
// export function MineViewBuilder() {
//   MineView()
// }