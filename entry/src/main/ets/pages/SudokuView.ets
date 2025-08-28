import { BoardView } from './views/BoardView';
import { AlertDialog, ButtonOptions, display, LengthMetrics, promptAction, router } from '@kit.ArkUI';
import { LogUtil } from '../utils/LogUtil';
import map from '@hms.core.map.map';
import { Cell } from '../data/Cell';
import { DataUtil } from '../utils/DataUtil';
import { GameData } from '../data/GameData';
import { preferences } from '@kit.ArkData';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { RawUtils } from '../utils/RawUtils';
import { LevelInfo } from '../data/Levelnfo';
import LevelInfoApi from '../common/database/LevelInfoApi';
import { GridConstants } from '../common/constants/GridConstants';
import { StyleConstants } from '../common/constants/StyleConstants';
import { Difficulty } from '../common/normal/Difficulty';


@Builder
export function SudokuBuilder() {
  SudokuView()
}

@Entry
@Component
struct SudokuView {
  //
  // @Consumer("NavPathStack")
  // pathStack:NavPathStack = new NavPathStack()

  @Consume('navPathStack')
  pathStack: NavPathStack

  private boardSideLength = display.getDefaultDisplaySync().width * 0.9 - vp2px(5) * 2;

  percent = display.getDefaultDisplaySync().width / display.getDefaultDisplaySync().height

  @State
  cumulativeTime: number = 0;

  @State
  @Watch("updateValue")
  // 传递值到子组件BoardView中
  inputValue: string = "Z";

  @State operate_buttons: string[] = ["undo", "erase", "edit", "hint"]

  @State values: string[] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
  @State remainCount: number[] = [16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16]

  @State valueCountMap: Map<string, number> = new Map<string, number>();

  @State isPlaying: boolean = true

  @State buttonIcon:Resource = this.isPlaying ? $r('app.media.pause') : $r('app.media.play')


  @State elapsedTime: number = 0
  @State timerId: number = 1;

  @State editBadgeOn: boolean = false
  @State
  editOn: boolean = false

  @State editBadgeColor: Resource = this.editBadgeOn ? $r('app.color.operate_edit_on') : $r('app.color.operate_edit_off')

  @State hintClicked: boolean = false

  @State
  @Watch("undoCallback")
  undid:boolean = false

  @State
  // @Watch("eraseCallback")
  erased:boolean = false

  @State
  hpStates: boolean[] = [true, true, true, true, true]

  textTimerController: TextTimerController = new TextTimerController()

  @State
  @Watch("listenerError")
  gotError: boolean = false

  @State
  @Watch("listenerCorrect")
  gotCorrectValue: string = "Z"

  @State
  @Watch("listenerRestart")
  restarted: boolean = false

  @State
  @Watch("gameDataChange")
  cells: Map<number, Cell> = new Map<number, Cell>();

  @State
  data:string = ""

  @State
  errorCount: number = 5

  @State
  hintCount: number = 5

  @State
  curLevelInfo: LevelInfo = new LevelInfo(0, "newbie", 1, 5, 5, true, false, "", 0)

  difficulty: string = ""
  levelName: string = ""
  level: number = 0

  @State paddingStart: LengthMetrics = LengthMetrics.vp(0);
  // 初始化标题栏结束端内间距
  @State paddingEnd: LengthMetrics = LengthMetrics.vp(0);

  dialogControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: '提示',
      content: '想要重新开始该关卡吗？',
      primaryButton: {
        value: '否',
        action: () => {
          // 启动计时器
          this.togglePlayPause()
        },
      },
      secondaryButton: {
        value: '是',
        role: ButtonRole.ERROR,
        action: () => {
          this.doRestart()
        }
      },
    })
  })

  gameOverDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.game_over_title'),
      content: $r('app.string.game_over_tips'),
      primaryButton: {
        value: $r('app.string.game_over_return_home'),
        action: () => {
          // 返回主页
          this.savaGameData()
        },
      },
      secondaryButton: {
        value: $r('app.string.game_over_restart_game'),
        role: ButtonRole.ERROR,
        action: () => {
          this.doRestart()
        }
      },
    })
  })

  gameOverSucDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.game_over_title'),
      content: $r('app.string.game_over_suc'),
      primaryButton: {
        value: $r('app.string.game_over_return_home'),
        action: () => {
          // 返回主页
          // this.savaGameData()
          this.backToMainView()
        },
      },
    })
  })

  backToMainView() {
    // this.pathStack.popToName("Main", true)
    LogUtil.debug("backToMainView")
    this.pathStack.pop(this.curLevelInfo, true)
  }

  doRestart() {
    // 状态重新赋值
    LogUtil.debug("SudokuView doRestart")
    this.cumulativeTime = 0
    this.timerId = 0

    this.isPlaying = true
    this.buttonIcon = this.isPlaying ? $r('app.media.pause') : $r('app.media.play')
    this.remainCount = [16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16]
    // this.hpStates = [true, true, true, true, true]
    this.hintCount = 5
    this.errorCount = 5
    this.reInitGameData()


    this.initHp(this.errorCount)
    this.initRemainCount()
    this.startTimer()
    this.curLevelInfo.errorCount = this.errorCount
    this.curLevelInfo.hintCount = this.hintCount
    this.curLevelInfo.data = DataUtil.map2JsonString(this.cells)
    this.savaGameData()
    this.initCellMap(this.curLevelInfo.data)
    // this.savaGameData()
    // 传递restart 状态，是BoardView调用 redraw
    this.restarted = true

  }

  reInitGameData() {
    this.cells.forEach((cell, index) => {
      cell._value = cell._initialValue
      cell._error = false
      cell._noted = false
      if (cell._value == "Z") {
        cell._locked = false
      } else {
        cell._locked = true
      }
    })
  }

  aboutToDisappear(): void {
    LogUtil.debug("aboutToDisappear")
    this.savaGameData()
  }


  onPageShow(): void {
    LogUtil.debug('SudoBoard onPageShow')
    this.startTimer()
  }

  /**
   * 开启计时器
   */
  startTimer() {
    this.timerId =setInterval(() => {
      this.cumulativeTime++
    }, 1000)
  }

  /**
   * 停止计时器
   */
  stopTimer() {
    clearInterval(this.timerId)
  }


  build() {
    NavDestination(){
      RelativeContainer() {
        Text("1") {
          Span("2")
        }
        Button({ type: ButtonType.Circle, stateEffect: true }){
          Row() {
            Image($r('app.media.back'))
              .align(Alignment.Center)
              .width('40%')
          }
        }
        .alignRules({
          top: {anchor: "__container__", align: VerticalAlign.Top},
          left: {anchor: "__container__", align: HorizontalAlign.Start}
        })
        .id('back')
        .width('10%')
        .height('5%')
        .buttonStyle(ButtonStyleMode.NORMAL)
        .clickEffect({level:ClickEffectLevel.LIGHT})
        .margin({top: $r('app.float.column_padding_top'), left: $r('app.float.column_padding_left')})
        .onClick((event) => {
          // this.pathStack.popToName("Index")
          this.savaGameData()
          this.backToMainView()
        })


        Button({ type: ButtonType.Circle, stateEffect: true }){
          Row() {
            Image($r('app.media.replay'))
              .align(Alignment.Center)
              .width('40%')
          }
        }
        .id('restart')
        .buttonStyle(ButtonStyleMode.NORMAL)
        .clickEffect({level:ClickEffectLevel.LIGHT})
        .alignRules({
          top: {anchor: '__container__', align: VerticalAlign.Top},
          right: {anchor: '__container__', align: HorizontalAlign.End}
        })
        .width('10%')
        .height('5%')
        .margin({top: $r('app.float.column_padding_top'), right: $r('app.float.column_padding_right')})
        .onClick(event => {
          this.togglePlayPause()
          this.dialogControllerConfirm.open()
        })

        Button({ type: ButtonType.Circle, stateEffect: true }){
          Row() {
            Image(this.buttonIcon)
              .align(Alignment.Center)
              .width('40%')
          }
        }
        .id('pause')
        .buttonStyle(ButtonStyleMode.NORMAL)
        .alignRules({right: {anchor: 'restart', align: HorizontalAlign.Start}})
        .width('10%')
        .height('5%')
        .clickEffect({level:ClickEffectLevel.LIGHT})
        .margin({top: $r('app.float.column_padding_top'), right: $r('app.float.column_padding_right')})
        .onClick(() => {
          this.togglePlayPause();
        });

        Text(this.difficulty)
          .id('difficulty')
          .width('25%')
          .alignRules({
            top: {anchor: "back", align: VerticalAlign.Bottom},
            left: {anchor: "__container__", align: HorizontalAlign.Start}
          })
          .fontSize($r('app.float.title_normal_size'))
          .textAlign(TextAlign.Start)
          .margin({top : $r('app.float.column_padding_top'), left: $r('app.float.column_padding_left')})

        Text(this.levelName)
          .id('level_name')
          .width('25%')
          .alignRules({
            top: {anchor: "back", align: VerticalAlign.Bottom},
            middle:{anchor: "__container__", align: HorizontalAlign.Center}
          })
          .fontSize($r('app.float.title_normal_size'))
          .textAlign(TextAlign.Center)
          .margin({top : 15})

        Text(this.formatTime()) {

        }
        .alignRules({
          top: {anchor: "back", align: VerticalAlign.Bottom},
          right:{anchor: "__container__", align: HorizontalAlign.End}
        })
        .fontSize($r('app.float.title_normal_size'))
        .margin({top: $r('app.float.column_padding_top'), right: $r('app.float.column_padding_right')})

        BoardView({inputValue: this.inputValue, hintClicked: this.hintClicked,
          editOn: this.editOn, undid: this.undid, erased: this.erased, gotError: this.gotError,
          restarted: this.restarted, gotCorrectValue: this.gotCorrectValue, cells: this.cells})
          .id("sudoku_board")
          .alignRules({top:  {anchor: 'difficulty', align: VerticalAlign.Bottom},
            middle: {anchor: 'level_name', align: HorizontalAlign.Center}})
          .border({width:2, color: Color.Black})
          .borderRadius(5)
          .margin({top: 15})
          .height(px2vp(this.boardSideLength))
          .width(px2vp(this.boardSideLength))
          .enabled(this.isPlaying ? true : false)
          .backgroundColor($r('app.color.sudoku_board_background'))


        Row() {
          this.hpBarBuilder()
        }
        .id("hp_bar")
        .width('100%')
        .alignRules({top:  {anchor: 'sudoku_board', align: VerticalAlign.Bottom}})
        .margin({top: $r('app.float.column_padding_top'),
          left: $r('app.float.column_padding_left'),
          right: $r('app.float.column_padding_right')})


        GridRow({
          columns: 8,
          gutter: {x: 5, y: 20},
          direction: GridRowDirection.Row
        }) {
          ForEach(this.values, (value: string) => {
            GridCol() {
              Badge({count: this.remainCount[parseInt(value, 16)],
                style: {badgeColor: $r('app.color.badge_remain_count') ,
                  borderWidth: 0,
                  color:Color.White},
                position: BadgePosition.RightTop,
              }){
                Button(value, {type: ButtonType.Capsule,  stateEffect: true})
                  .fontSize($r('app.float.input_value_font'))
                  .buttonStyle(ButtonStyleMode.NORMAL)
                  .fontColor($r('app.color.text_color_keys'))
                  .clickEffect({level:ClickEffectLevel.LIGHT})
                  .onClick(() => {
                    this.inputValue = value
                  })
              }
            }
          })
        }
        .id('keys')
        .alignRules({top: {anchor: "hp_bar", align: VerticalAlign.Bottom}})
        .margin({left: $r('app.float.column_padding_left'), right: $r('app.float.column_padding_right'), top: $r('app.float.column_padding_top')})
        .enabled(this.isPlaying ? true : false)

        GridRow({
          columns: 4,
          gutter: {x: 10, y: 10},
          direction: GridRowDirection.Row
        }) {
          ForEach(this.operate_buttons, (operate: string) => {
            GridCol() {
              Button({type: ButtonType.Capsule,  stateEffect: true}){
                this.operateBuild(operate)
              }
              .id(operate)
              .fontColor(Color.Black)
              .fontSize(18)
              .buttonStyle(ButtonStyleMode.NORMAL)
              .width('100%')
              .clickEffect({level:ClickEffectLevel.LIGHT})
              .onClick((event) => {
                switch (operate) {
                  case "undo":
                    this.clickUndoButton()
                    break
                  case "hint":
                    this.clickHintButton()
                    break
                  case "edit":
                    this.clickEditButton()
                    break
                  case "erase":
                    this.clickEraseButton()
                    break
                }
              })
            }
          })
        }
        .id('operate_button')
        .alignRules({top: {anchor: "keys", align: VerticalAlign.Bottom}})
        .margin({left: $r('app.float.column_padding_left'), right: $r('app.float.column_padding_right'), top: $r('app.float.column_padding_top')})
        .enabled(this.isPlaying ? true : false)
      }
      .backgroundColor($r('app.color.view_background'))
      .width('100%')
      .height('100%')
    }
    .backgroundColor($r('app.color.view_background'))
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.onInit(context)
    })

  }


  onInit(context: NavDestinationContext) {
    this.pathStack = context.pathStack
    this.curLevelInfo = this.pathStack.getParamByName('PageSudoku')[0] as LevelInfo
    // let param:GameData = this.pathStack.getParamByName('PageSudoku')[0] as GameData
    let stringDifficulty = `app.string.difficulty_${this.curLevelInfo.difficulty}`
    LogUtil.debug("stringDifficulty = " + stringDifficulty)
    LogUtil.debug("this.curLevelInfo.data = " + this.curLevelInfo.data)
    // this.difficulty = getContext(this).resourceManager.getStringSync($r(stringDifficulty))
    this.cumulativeTime = this.curLevelInfo.cumulativeTime
    this.level = this.curLevelInfo.level
    this.levelName = `第${this.curLevelInfo.level}关`
    this.hintCount = this.curLevelInfo.hintCount
    this.initTextDifficulty(this.curLevelInfo.difficulty)
    this.initCellMap(this.curLevelInfo.data)
    this.initRemainCount();
    this.initHp(this.curLevelInfo.errorCount)
    this.startTimer()
  }

  initTextDifficulty(difficulty: string) {
    let str: string = ""
    switch (difficulty) {
      case Difficulty.Newbie:
        this.difficulty = getContext(this).resourceManager.getStringSync($r('app.string.difficulty_newbie'))
        break
      case Difficulty.Easy:
        this.difficulty = getContext(this).resourceManager.getStringSync($r('app.string.difficulty_easy'))
        break
      case Difficulty.Middle:
        this.difficulty = getContext(this).resourceManager.getStringSync($r('app.string.difficulty_middle'))
        break
      case Difficulty.Hard:
        this.difficulty = getContext(this).resourceManager.getStringSync($r('app.string.difficulty_hard'))
        break
      case Difficulty.Hell:
        this.difficulty = getContext(this).resourceManager.getStringSync($r('app.string.difficulty_hell'))
        break
    }
  }

  @Builder operateBuild(operate: string) {
    Column() {
      if (operate === "hint") {
        Row() {
          Badge({
            count: this.hintCount,
            style: {badgeColor: this.hintCount > 0 ? $r('app.color.operate_badge_hint') : $r('app.color.operate_badge_hint_not_enough') ,
              borderWidth: 0, color:Color.White},
            position: BadgePosition.RightTop,
          }) {
            Image($r(`app.media.${operate}`))
              .width('30%')
              .alignRules({top: {anchor:'__container', align: VerticalAlign.Top},
              bottom:{anchor:"__container__", align: VerticalAlign.Bottom}})
              .margin({top: 5, bottom: 5})
          }
        }
      } else if(operate == "edit") {
        Row() {
          Badge({
            value: this.editBadgeOn ? 'ON' : 'OFF',
            style: {badgeColor: this.editBadgeColor, borderWidth: 0, color:Color.White},
            position: BadgePosition.RightTop,
          }) {
            Image($r(`app.media.${operate}`))
              .width('30%')
              .alignRules({top: {anchor:'__container', align: VerticalAlign.Top},
                bottom:{anchor:"__container__", align: VerticalAlign.Bottom}})
              .margin({top: 5, bottom: 5})
          }
          .borderWidth(0)

        }
      }else {
        Row() {
          Image($r(`app.media.${operate}`))
            .width('30%')
            .alignRules({top: {anchor:'__container', align: VerticalAlign.Top},
              bottom:{anchor:"__container__", align: VerticalAlign.Bottom}})
            .margin({top: 5, bottom: 5})
        }
      }
    }
  }

  @Builder hpBarBuilder() {
    Text($r('app.string.error_count'))
      .fontSize($r('app.float.title_normal_size'))
    GridRow({
      columns: 5,
      gutter: {y: 5},
      direction: GridRowDirection.Row
    }) {
      ForEach(this.hpStates,(state: boolean) => {
        GridCol() {
          Image(state ? $r('app.media.hp_red') : $r('app.media.hp_null'))
            .width('40%')
          }
      })
    }
    .width('80%')
  }


  clickUndoButton() {
    LogUtil.debug("click undo undid : " + this.undid)
    this.undid = true
  }

  clickHintButton() {
    LogUtil.debug("click hint")
    if (this.hintCount <= 0) {
      promptAction.showToast({
        message: $r('app.string.hint_count_no_enough'),
        duration: 2000
      });
    } else {
      this.hintClicked = true
      this.hintCount--
      this.curLevelInfo.hintCount = this.hintCount
      this.savaGameData()
    }
  }

  clickEditButton() {
    LogUtil.debug("click edit " + this.editOn)
    this.editOn = !this.editOn
    LogUtil.debug("click edit2 " + this.editOn)
    this.editBadgeOn = !this.editBadgeOn
    this.editBadgeColor = this.editBadgeOn ? $r('app.color.operate_edit_on') : $r('app.color.operate_edit_off')
  }

  clickEraseButton() {
    LogUtil.debug("click erase")
    this.erased = true
  }


  /**
   * 暂停按钮
   */
  togglePlayPause() {
    this.isPlaying ? this.stopTimer() : this.startTimer()
    this.isPlaying = !this.isPlaying
    if (!this.isPlaying) {
      this.savaGameData()
    }
    this.buttonIcon = this.isPlaying ? $r('app.media.pause') : $r('app.media.play')
    LogUtil.debug(this.isPlaying ? "Playing" : "Paused");
  }

  updateValue() {
    console.log("收到子view 更新 inputValue", this.inputValue)
    // this.inputValue = value
  }

  /**
   * 把累计的时间(秒)转化成hh:mm:ss 格式的时间
   * @returns hh:mm:ss 格式的时间
   */
  formatTime():string {
    let hour = Math.floor(this.cumulativeTime / 3600)
    const minutes = Math.floor((this.cumulativeTime % 3600) / 60);  // 计算分钟
    const seconds = this.cumulativeTime % 60;  // 计算秒数
    let formatHour = String(hour).padStart(2, '0')
    let formatMinutes = String(minutes).padStart(2, '0')
    let formatSeconds = String(seconds).padStart(2, '0')
    if (hour > 0) {
      return `${formatHour}:${formatMinutes}:${formatSeconds}`
    }
    let formatTime:string = hour > 0 ? `${formatHour}:${formatMinutes}:${formatSeconds}` : `${formatMinutes}:${formatSeconds}`
    return formatTime
  }

  undoCallback(changedPropertyName: string) {
    LogUtil.debug("undoCallBack this.undid : " + this.undid)
  }

  eraseCallback(changedPropertyName: string) {
    LogUtil.debug("eraseCallback this.erased : " + this.erased)
  }

  listenerError(changedPropertyName: string) {
    LogUtil.debug("输入错误的值 gotError : " + this.gotError)
    if (this.gotError) {
      for (let i = this.hpStates.length - 1; i >=0; i --) {
        if (this.hpStates[i]) {
          LogUtil.debug("修改hp bar,错误次数足够")
          this.hpStates[i] = false
          this.errorCount--
          this.curLevelInfo.errorCount = this.errorCount
          this.savaGameData()
          return
        }
      }
      // 错误次数不够，弹窗
      this.gameOverDialog.open()
    }
  }

  initHp(errorCount: number) {
    for (let index = this.hpStates.length - 1; index > errorCount; index--) {
      this.hpStates[index] = false
    }
  }

  initRemainCount() {
    for (let index = 0; index < this.values.length; index++) {
      this.valueCountMap.set(this.values[index], 16)
    }
    this.cells.forEach((cell: Cell, key: number) => {
      let value = cell._value
      if (value != "Z") {
        this.remainCount[parseInt(value, 16)]--
      }
    })
  }

  initCellMap(mapString: string) {
    LogUtil.debug("initCellMap mapString " + mapString)
    this.cells = DataUtil.jsonString2Map<number, Cell>(mapString)
    // this.cells.forEach((value: Cell, key: number) => {
    //   LogUtil.debug(`number " ${key} , value : ${value._value}`)
    // })
  }

  listenerCorrect(changedPropertyName: string) {
    LogUtil.debug("listenerCorrect this.gotCorrectValue : " + this.gotCorrectValue)
    let gameOverSuc:boolean = true
    if (this.gotCorrectValue != "Z") {
      this.remainCount[parseInt(this.gotCorrectValue, 16)]--
    } else {
      return
    }
    for (let index = 0; index < this.remainCount.length; index++) {
      let count = this.remainCount[index];
      if (count > 0) {
        gameOverSuc = false
        // 说明游戏未结束，直接返回
        // this.curLevelInfo.data =
        return
      }
    }
    // 游戏结束，通过关卡，进行弹窗
    if (gameOverSuc) {
      this.curLevelInfo.completed = true
      this.savaGameData()
      this.gameOverSucDialog.open()
    }

  }

  gameDataChange(changedPropertyName: string) {
    LogUtil.debug("gameDataChange")
    let data = DataUtil.map2JsonString(this.cells)
    this.curLevelInfo.data = data
    LogUtil.debug("更新 this.curLevelInfo.data : " + this.curLevelInfo.data)
  }

  savaGameData() {
    // PreferencesUtil.putSync("ErrorCount", this.errorCount)
    // PreferencesUtil.putSync("HintCount", this.hintCount)
    // PreferencesUtil.putSync("Level", this.level)
    // PreferencesUtil.putSync("Difficulty", this.difficulty)
    // let dataString = DataUtil.map2JsonString(this.cells)
    // LogUtil.debug("dataString : " + dataString)
    // PreferencesUtil.putSync("Data", dataString)
    this.curLevelInfo.cumulativeTime = this.cumulativeTime
    LogUtil.debug("savaGameData time : " + this.curLevelInfo.cumulativeTime)
    LevelInfoApi.updateData(this.curLevelInfo, (result: number) => {
      LogUtil.debug("saveGameData callback result : " + result)
    })
    LevelInfoApi.query(this.curLevelInfo.difficulty, this.curLevelInfo.level, (result: LevelInfo, count: number) => {
      LogUtil.debug("saveGameData query number : " + count + " cumulativeTime = " + result.cumulativeTime)
    })
  }

  listenerRestart(changedPropertyName: string) {
    LogUtil.debug("listenerRestart " + this.restarted)
  }
}



