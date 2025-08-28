import { SegmentButtonItemTuple, SegmentButtonOptions, SegmentButton } from "@kit.ArkUI"
import { CommonConstants } from "../../common/constants/CommonConstants"
import { StyleConstants } from "../../common/constants/StyleConstants"
import LevelInfoApi from "../../common/database/LevelInfoApi"
import { Difficulty } from "../../common/normal/Difficulty"
import { LevelInfo } from "../../data/Levelnfo"
import { LogUtil } from "../../utils/LogUtil"
import { DividerTmp } from "./DividerTmp"

@Builder
export function RankViewBuilder() {
  RankView()
}

// 从本地数据库中查询已完成的游戏记录，并根据不同的难度等级进行筛选和展示。
// 同时，提供按通关时间排序的功能，让玩家可以查看自己在不同难度下的战绩排名。
@Preview
@Component
export struct RankView {
  @State
  levelInfos: LevelInfo[] = []
  @State
  @Watch('onSegmentChange')
  segSelectedIndexes: number[] = [0]
  @State
  curDifficulty: Difficulty = Difficulty.Newbie
  difficultyArray: Difficulty[] =
    [Difficulty.Newbie, Difficulty.Easy, Difficulty.Middle, Difficulty.Hard, Difficulty.Hell]
  @State singleSelectCapsuleOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: $r('app.string.difficulty_newbie') }, { text: $r('app.string.difficulty_easy') },
      { text: $r('app.string.difficulty_middle') }, { text: $r('app.string.difficulty_hard') },
      { text: $r('app.string.difficulty_hell') }] as SegmentButtonItemTuple,
    multiply: false,
    fontSize: $r('app.float.title_normal_size'),
    selectedFontSize: $r('app.float.title_normal_size'),
    selectedBackgroundColor: $r('app.color.segment_select_color'),
    backgroundColor: $r('app.color.segment_background'),
    backgroundBlurStyle: BlurStyle.BACKGROUND_THICK
  })

  @State egDivider: DividerTmp = new DividerTmp(1, CommonConstants.PADDING, CommonConstants.PADDING
    , getContext(this).resourceManager.getColorSync($r('app.color.divider_color')))

  @State selected: boolean = false

  @Builder
  buildRankItem(levelInfo: LevelInfo) {
    Row() {
      Column() {
        Row() {
          Image($r('app.media.item_sudoku_logo'))
            .width(40)
            .height(40)
          Text(`第 ${levelInfo.level} 关`)
            .fontColor($r('app.color.item_name_color'))
            .fontSize(16)
            .padding({ left: CommonConstants.Rank_Padding })
        }

        Row() {
            Image($r('app.media.item_rank_red'))
              .width(25)
              .height(25)
              .padding({ left: 0 })
            Text(`${levelInfo.errorCount}`)
              .opacity(0.38)
              .padding({ left: CommonConstants.Rank_Padding })
              .fontColor($r('app.color.item_name_color'))
              .fontSize(16)


          // Blank()/
            Image($r('app.media.item_rank_hint'))
              .width(16)
              .height(16)
              .margin({left: CommonConstants.PADDING})
            Text(`${levelInfo.hintCount}`)
              .opacity(0.38)
              .padding({ left: CommonConstants.Rank_Padding })
              .fontColor($r('app.color.item_name_color'))
              .fontSize(16)

        }
        .width('50%')

        // .padding({top: CommonConstants.PADDING})
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: CommonConstants.PADDING })

      Blank()
      Text(this.formatTime(levelInfo.cumulativeTime))
        .padding({ right: CommonConstants.PADDING })
        .height('50%')
    }
    .height(CommonConstants.Rank_Item_Height)
    .width('100%')
  }

  build() {
    NavDestination() {
      Column() {
        SegmentButton({
          options: this.singleSelectCapsuleOptions,
          selectedIndexes: this.segSelectedIndexes
        })
          .id("segment_difficulty")
          .margin({ left: CommonConstants.PADDING_LEFT, right: CommonConstants.PADDING_RIGHT, top: CommonConstants.PADDING })
        if (this.levelInfos.length <= 0) {
          Text($r('app.string.tip_no_game_data')) {

          }
          .padding({top: CommonConstants.PADDING})
          .textAlign(TextAlign.Center)
          .margin({top: CommonConstants.PADDING})
          .fontSize($r('app.float.title_font_size'))
        } else {
          Flex({ justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
            Checkbox({ name: 'checkbox2', group: 'checkboxGroup' })
              .selectedColor(0x39a2db)
              .select(this.selected)
              .shape(CheckBoxShape.CIRCLE)
              .onChange((value: boolean) => {
                console.info('Checkbox2 change is' + value)
                this.selected = value
                this.selected ? this.levelInfos.sort((a: LevelInfo, b: LevelInfo) => a.cumulativeTime - b.cumulativeTime)
                  : this.levelInfos.sort((a: LevelInfo, b: LevelInfo) => a.level - b.level)
              })
              .width(20)
              .height(20)
            Text($r('app.string.rank_sort')).fontSize($r('app.float.tip_font_size'))
          }
          .margin({top: CommonConstants.PADDING, right: CommonConstants.PADDING_RIGHT})
          List() {
            ForEach(this.levelInfos, (info: LevelInfo) => {
              ListItem() {
                this.buildRankItem(info)
              }
              .clickEffect({level:ClickEffectLevel.LIGHT})
            })
          }
          .margin({top: CommonConstants.PADDING})
          .divider(this.egDivider)
          Row() {
          }
          .alignItems(VerticalAlign.Top)
        }

      }
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .onReady((context) => {
      this.initData(this.curDifficulty)
    })
  }

  onSegmentChange(changedPropertyName: string) {
    LogUtil.debug((`选中按钮索引 -- ${this.segSelectedIndexes}`))
    this.curDifficulty = this.difficultyArray[this.segSelectedIndexes[0]]
    this.initData(this.curDifficulty)
  }

  initData(difficulty: string) {
    LevelInfoApi.queryCompletedList(difficulty, true, (result: LevelInfo[]) => {
      this.levelInfos = result
    })
  }

  /**
   * 把累计的时间(秒)转化成hh:mm:ss 格式的时间
   * @returns hh:mm:ss 格式的时间
   */
  formatTime(cumulativeTime: number): string {
    let hour = Math.floor(cumulativeTime / 3600)
    const minutes = Math.floor((cumulativeTime % 3600) / 60); // 计算分钟
    const seconds = cumulativeTime % 60; // 计算秒数
    let formatHour = String(hour).padStart(2, '0')
    let formatMinutes = String(minutes).padStart(2, '0')
    let formatSeconds = String(seconds).padStart(2, '0')
    if (hour > 0) {
      return `${formatHour}:${formatMinutes}:${formatSeconds}`
    }
    let formatTime: string =
      hour > 0 ? `${formatHour}:${formatMinutes}:${formatSeconds}` : `${formatMinutes}:${formatSeconds}`
    return formatTime
  }
}