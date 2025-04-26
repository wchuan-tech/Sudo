import { CommonConstants } from "../../common/constants/CommonConstants"
import { LogUtil } from "../../utils/LogUtil"
import { ConfigurationConstant } from "@kit.AbilityKit"
import { PreferencesUtil } from "../../utils/PreferencesUtil"
import { DividerTmp } from "./DividerTmp"
import { StyleConstants } from "../../common/constants/StyleConstants"

@Preview
@Component
export struct DisplayModeSetting {
  @State curColorMode: ConfigurationConstant.ColorMode =
    AppStorage.get(CommonConstants.ColorMode) as ConfigurationConstant.ColorMode
  @State isDarkMode: boolean = this.curColorMode == 1 ? false : true
  @State followSystem: boolean = PreferencesUtil.getBooleanSync(CommonConstants.FollowSystem)
  @State daySelected: boolean = true
  // @State toDoData: ToDo[] = []
  @State isEditMode: boolean = false
  // @State selectedItems: Array[] = []
  private availableThings: string[] = ['普通模式', '深夜模式']
  @State egDivider: DividerTmp = new DividerTmp(1, CommonConstants.PADDING, CommonConstants.PADDING
    , getContext(this).resourceManager.getColorSync($r('app.color.divider_color')))


  aboutToAppear(): void {
    this.curColorMode = AppStorage.get(CommonConstants.ColorMode) as ConfigurationConstant.ColorMode
    LogUtil.debug("DisplayModeSetting aboutToAppear curColorMode = " + this.curColorMode)
    this.daySelected = PreferencesUtil.getBooleanSync(CommonConstants.UseDarkMode)
  }

  @Builder
  followSystemBuilder() {
    Row() {
      Column() {
        Text($r('app.string.message_follow_system'))
          .fontColor($r('app.color.item_name_color'))
          .fontSize($r('app.float.item_font_size'))
          .padding({ left: CommonConstants.PADDING_LEFT, top: CommonConstants.Rank_Padding })

        Text($r('app.string.message_follow_system_detail'))
          .opacity(0.58)
          .padding({ left: CommonConstants.PADDING_LEFT, top: CommonConstants.Rank_Padding })
          .fontColor($r('app.color.item_name_color'))
          .fontSize($r('app.float.sub_item_font_size'))

      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: CommonConstants.PADDING })

      Blank()

      Toggle({ type: ToggleType.Switch, isOn: this.followSystem })//isOn 属性值在有触发刷新页面的场景中，不要省略
        .onChange((isOn: boolean) => {
          LogUtil.debug('Toggle.onChange2： isOn : ' + isOn)
          this.followSystem = isOn
          PreferencesUtil.putSync(CommonConstants.FollowSystem, this.followSystem)
          if (this.followSystem) {
            LogUtil.debug("curColorMode = " + this.curColorMode)
            getContext(this).getApplicationContext().setColorMode(this.curColorMode)
          } else {
            this.daySelected = this.curColorMode == ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ? true : false
          }
        })
        .margin({ right: CommonConstants.PADDING_RIGHT })

    }
    .height(CommonConstants.Item_Height_V2)
    .width('100%')
  }

  @Builder
  itemGroupHead(text: Resource) {
    // 列表分组的头部组件，对应联系人分组A、B等位置的组件
    Text(text)
      .opacity(0.78)
      .fontSize($r('app.float.title_normal_size'))
      .backgroundColor(Color.Transparent)
      .width('100%')
      .padding({ left: CommonConstants.PADDING })
  }

  @Builder
  itemManualSetting() {
    ListItem() {
      Row() {
        Image($r('app.media.item_day'))
          .width(25)
          .height(25)
          .padding({ left: 0 })
        Text($r('app.string.item_day_txt'))
          .opacity(0.88)
          .padding({ left: CommonConstants.Rank_Padding })
          .fontColor($r('app.color.item_name_color'))
          .fontSize(16)
        Blank()
        Blank()
        Checkbox() {

        }
        .select(this.daySelected)
        .onChange((value: boolean) => {
          this.daySelected = value
          this.changeDisplayMode(this.daySelected)
        })
      }
      .width(StyleConstants.FULL_WIDTH)
      .padding({ left: CommonConstants.PADDING, right: CommonConstants.PADDING })
    }
    .height(CommonConstants.Item_Height)
    .width(StyleConstants.FULL_WIDTH)

    .backgroundColor($r('app.color.item_background'))

    ListItem() {
      Row() {
        Image($r('app.media.item_night'))
          .width(25)
          .height(25)
          .padding({ left: 0 })
        Text($r('app.string.item_night_txt'))
          .opacity(0.88)
          .padding({ left: CommonConstants.Rank_Padding })
          .fontColor($r('app.color.item_name_color'))
          .fontSize(16)
        Blank()
        Checkbox() {

        }
        .select(!this.daySelected)
        .onChange((value: boolean) => {
          this.daySelected = !value
          this.changeDisplayMode(this.daySelected)
        })
      }
      .width(StyleConstants.FULL_WIDTH)
      .padding({ left: CommonConstants.PADDING, right: CommonConstants.PADDING })
    }
    .height(CommonConstants.Item_Height)
    .width(StyleConstants.FULL_WIDTH)
    .backgroundColor($r('app.color.item_background'))
  }

  build() {

    NavDestination() {
      List() {
        ListItem() {
          this.followSystemBuilder()
        }
        .backgroundColor($r('app.color.item_background'))

        ListItemGroup({ header: this.itemGroupHead($r('app.string.display_mode_manual_setting')) }) {
          this.itemManualSetting()
        }
        .divider(this.egDivider)
        .margin({ top: CommonConstants.PADDING })
        .visibility(this.followSystem ? Visibility.Hidden : Visibility.Visible)
      }

    }
    .backgroundColor($r('app.color.view_background'))

  }

  changeDisplayMode(dayModeSelected: boolean) {
    let mode = dayModeSelected ? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT : ConfigurationConstant.ColorMode.COLOR_MODE_DARK
    getContext(this).getApplicationContext().setColorMode(mode)
    PreferencesUtil.putSync(CommonConstants.UseDarkMode, dayModeSelected)
  }
}

@Builder
export function DisplayModeSettingBuilder() {
  DisplayModeSetting()
}