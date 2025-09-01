import { SudokuData } from '../data/SudokuModels';
import { LevelInfo } from '../data/Levelnfo';
import { LogUtil } from '../utils/LogUtil';
import LevelInfoApi from '../common/database/LevelInfoApi';
import { AlertDialog, display,promptAction } from '@kit.ArkUI';
import { gameRecordRepository } from '../common/database/GameRecordRepository';

interface CellPosition {
  row: number;
  col: number;
}

@Builder
export function OnlineGamePageBuilder() {
  OnlineGamePage()
}

@Entry
@Component
struct OnlineGamePage {

  @Consume('navPathStack')
  pathStack: NavPathStack

  private boardSideLength = display.getDefaultDisplaySync().width * 0.9 - vp2px(5) * 2;

  // 难度
  @State
  difficulty: string = "Loading..."; // 初始显示 "Loading..."
  PK: string = "PK"


  // 组件
  // 暂停/开始按钮
  @State isPlaying: boolean = true  // 判断是否要暂停
  @State buttonIcon:Resource = this.isPlaying ? $r('app.media.pause') : $r('app.media.play')
  @State elapsedTime: number = 0
  @State timerId: number = 1;
  // 传递值到子组件BoardView中
  @State
  @Watch("updateValue")
  inputValue: string = "Z";

  // Data life time...
  @State
  cumulativeTime: number = 0;
  @State
  curLevelInfo: LevelInfo = new LevelInfo(0, "newbie", 1, 5, 5, true, false, "", 0)
  @State
  hintCount: number = 5

  // 生命值
  @State
  hpStates: boolean[] = [true, true, true, true, true]
  @State
  errorCount: number = 5

  // 数字以及各类游戏操作
  @State
  values: string[] = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
  keypadNumbers: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  @State
  private highlightedNumber: number = 0; // 0 表示没有数字被高亮


  @State
  private errorBoard: boolean[][] = [];


  @State
  operate_buttons: string[] = ["undo", "erase", "edit", "hint"]
  @State
  editBadgeOn: boolean = false // 提示按钮的badge
  // 提示能否编辑
  @State
  editBadgeColor: Resource = this.editBadgeOn ? $r('app.color.operate_edit_on') : $r('app.color.operate_edit_off')

  // 是否能提示
  @State
  hintClicked: boolean = false


  // 撤回
  @State
  @Watch("undoCallback")
  undid:boolean = false

  // 笔记
  @State
  editOn: boolean = false

  @State
  // 擦除
  // @Watch("eraseCallback")
  erased:boolean = false

  @State
  remainCount: number[] = [9, 9, 9, 9, 9, 9, 9, 9, 9]

  @State private puzzle: number[][] = [];
  @State private solution: number[][] = [];
  // 专门用于玩家操作的棋盘，是 puzzle 的一个深拷贝
  @State private playerBoard: number[][] = [];
  // 记录当前选中的单元格
  @State private selectedCell: CellPosition | null = null;

  @State private finalBestTimeMessage: string = "正在计算...";

  build() {
    NavDestination(){
      RelativeContainer(){
        Text("1") {
          Span("2")
        }
        // 后退按钮
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
          this.backToMainView() // 回到主菜单
        })



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

        Text(this.PK)
          .id('PK')
          .width('25%')
          .alignRules({
            top: {anchor: "back", align: VerticalAlign.Bottom},
            middle:{anchor: "__container__", align: HorizontalAlign.Center}
          })
          .fontSize($r('app.float.title_normal_size'))
          .textAlign(TextAlign.Center)
          .margin({top : 15})

        Text(this.formatTime()){
        }
        .alignRules({
          top: {anchor: "back", align: VerticalAlign.Bottom},
          right:{anchor: "__container__", align: HorizontalAlign.End}
        })
        .fontSize($r('app.float.title_normal_size'))
        .margin({top: $r('app.float.column_padding_top'), right: $r('app.float.column_padding_right')})



        // 游戏版的绘制
        Column() {
          // 在容器内部调用 @Builder 方法
          this.GameBoard()
        }
        // 2. 为这个容器设置 id，以便其他组件可以依赖它
        .id("sudoku_board")
        // 3. 为这个容器设置 alignRules，告诉 RelativeContainer 把它放在哪里
        .alignRules({
          top: { anchor: 'difficulty', align: VerticalAlign.Bottom }, // 它的顶部，对齐 difficulty 文本的底部
          middle: { anchor: '__container__', align: HorizontalAlign.Center }  // 并且它在容器内水平居中
        })
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
        .alignRules({
          top: { anchor: 'sudoku_board', align: VerticalAlign.Bottom } })
        .margin({top: $r('app.float.column_padding_top'),
          left: $r('app.float.column_padding_left'),
          right: $r('app.float.column_padding_right')})


        // 填充数字的绘制
        Column() {
          this.NumberPad()
        }
        .id('keys')
        .alignRules({ top: { anchor: "hp_bar", align: VerticalAlign.Bottom } ,
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        }) // 它的顶部，对齐 hp_bar 的底部
        .margin({left: $r('app.float.column_padding_left'), right: $r('app.float.column_padding_right'), top: $r('app.float.column_padding_top')})
        .enabled(this.isPlaying ? true : false)
      } // end of RelativeContainer
      .backgroundColor($r('app.color.view_background'))
      .width('100%')
      .height('100%')
    } // end of NavDestination
    .backgroundColor($r('app.color.view_background'))
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.onInit(context)
    })

  }

  // 绘制可交互的游戏棋盘
  @Builder
  GameBoard() {
    Stack() {
      this.buildOnlineGridLines()
      Grid() {
        ForEach(this.playerBoard, (row: number[], rowIndex: number) => {
          ForEach(row, (cellValue: number, colIndex: number) => {
            GridItem() {
              Text(cellValue === 0 ? "" : cellValue.toString())
                .width('100%').height('100%')
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(
                  this.puzzle[rowIndex][colIndex] !== 0 ? $r('app.color.bar_selected_color') :
                  this.errorBoard[rowIndex][colIndex] ? Color.Red :
                  Color.Blue)
                .textAlign(TextAlign.Center)
                .backgroundColor((Math.floor(rowIndex / 3) + Math.floor(colIndex / 3)) % 2 === 0 ? $r('app.color.sudoku_board_background') : $r('app.color.level_background'))
                .border({ width: this.selectedCell?.row === rowIndex && this.selectedCell?.col === colIndex ? 3 : 0, color: Color.Orange })
                .onClick(() => {
                  if (!this.isPlaying)
                    return; // 游戏暂停时不可操作
                  // 获取当前点击格子的值
                  const currentValue = this.playerBoard[rowIndex][colIndex];

                  if (this.puzzle[rowIndex][colIndex] === 0) {
                    this.selectedCell = { row: rowIndex, col: colIndex };

                    if (currentValue !== 0) {
                      this.highlightedNumber = currentValue;
                    } else {
                      // 如果点击的是一个纯空格，取消所有数字高亮
                      this.highlightedNumber = 0;
                    }
                  } else {
                    // 点击的是题目给出的初始数字
                    this.selectedCell = null; // 取消对空格的选中框
                    this.highlightedNumber = currentValue; // 高亮所有同类数字
                  }

                })
            }
          })
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    }
    .aspectRatio(1).border({ width: 2, color: $r('app.color.text_color_keys') })
  }

  // 绘制数字输入键盘
  @Builder
  NumberPad() {
    Grid() {
      ForEach(this.keypadNumbers, (num: number) => {
        GridItem() {
          Button() {
            Text(num.toString())
              .fontSize(24)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_color_keys'))
          }
          .type(ButtonType.Circle).
          width('90%').
          aspectRatio(1).
          backgroundColor(Color.White)
          .onClick(() => {
            if (this.selectedCell && this.isPlaying) {
              // 直接传递 number 类型的 num
              this.updatePlayerBoard(this.selectedCell.row, this.selectedCell.col, num);
            }
          })
        }
      })
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .padding({ left: 10, right: 10 }) // 修正：padding({ left: 10, right: 10 })
  }

  // 绘制网格线的方法 (与 Index.ets 中的相同)
  @Builder
  buildOnlineGridLines() {
    Stack() {
      Grid() {
        ForEach(Array.from({ length: 81 }), () => {
          GridItem() {
            Column().width('100%').height('100%').border({ width: 0.5, color: $r('app.color.divider_color') })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      Grid() {
        ForEach(Array.from({ length: 9 }), () => {
          GridItem() {
            Column().width('100%').height('100%').border({ width: 2, color: $r('app.color.text_color_keys') })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
    }
  }


  updatePlayerBoard(row: number, col: number, valueNum: number) {
    if (!this.isPlaying || this.puzzle[row][col] !== 0) {
      // 如果游戏暂停，或者点击的不是空格，则不执行任何操作
      return;
    }

    // 创建 errorBoard 的副本以触发UI刷新
    const newErrorBoard = [...this.errorBoard];

    if (valueNum !== this.solution[row][col]) {
      // 填错了
      newErrorBoard[row][col] = true; // 在错误板上标记为 true
      if (this.errorCount > 0) {
        this.errorCount--;
        this.hpStates[this.errorCount] = false;
        promptAction.showToast({ message: `错误！剩余机会：${this.errorCount}` });
        if (this.errorCount <= 0) {
          this.stopTimer(); this.isPlaying = false;
          promptAction.showDialog({ title: '游戏结束', message: '您已用完所有机会！' });
        }
      }
    } else {
      // 填对了
      newErrorBoard[row][col] = false; // 确保错误标记被清除
    }

    this.errorBoard = newErrorBoard;

    // 1. 创建一个新的数组副本
    const newBoard = [...this.playerBoard];

    // 2. 在新副本上进行修改
    newBoard[row][col] = valueNum;

    // 3. 将 @State 变量指向这个全新的副本
    this.playerBoard = newBoard;

    // 【核心修改】在这里调用胜利检查
    // 在棋盘更新后，立即检查游戏是否已经结束
    this.checkWinAndSaveRecord();
  }

  // 暂停
  stopTimer() {
    clearInterval(this.timerId)
  }

  /**
   * 开启计时器
   */
  startTimer() {
    this.timerId =setInterval(() => {
      this.cumulativeTime++
    }, 1000)
  }


  updateValue() {
    console.log("收到子view 更新 inputValue", this.inputValue)
    // this.inputValue = value
  }

  // 格式化时间
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

  // 绘制生命值
  @Builder
  hpBarBuilder() {
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

  onInit(context: NavDestinationContext)
  {
    const params = context.pathStack.getParamByName('OnlineGamePage')[0] as SudokuData;

    if (params && params.puzzle) {
      LogUtil.debug("OnlineGamePage: onInit received params successfully.");
      // 直接使用 API 数据，只需深拷贝
      this.puzzle = params.puzzle;
      this.solution = params.solution;
      this.difficulty = params.difficulty;

      this.playerBoard = JSON.parse(JSON.stringify(params.puzzle));
      this.errorBoard = Array(9).fill(0).map(() => Array(9).fill(false));

      this.startTimer();
    } else {
      LogUtil.error("OnlineGamePage: Failed to get params in onInit.");
      promptAction.showToast({ message: "错误：无法加载谜题数据。" });
      setTimeout(() => { this.pathStack.pop(); }, 1500);
    }
  }

  // 回到主页
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


  // 【新增方法 1】检查数独是否已正确完成
  private isSudokuComplete(): boolean {
    for (let r = 0; r < 9; r++) {
      for (let c = 0; c < 9; c++) {
        // 只要有一个格子是 0（空格），或者与答案不符，就说明未完成
        if (this.playerBoard[r][c] === 0 || this.playerBoard[r][c] !== this.solution[r][c]) {
          return false;
        }
      }
    }
    return true; // 所有格子都已填对
  }

  // 1. 【修改】重构 gameOverSucDialog，使其能够显示动态内容
  //    我们不再将它定义为类属性，而是在需要时动态创建
  private showGameOverDialog() {
    // 2. 【核心】使用 promptAction.showToast
    promptAction.showToast({
      // 3. 将我们准备好的动态消息作为 message
      message: this.finalBestTimeMessage,
      // 4. 设置一个较长的持续时间，以便用户能看清多行信息
    })

    // 5. Toast 显示后，可以延迟一小段时间再返回主菜单
    setTimeout(() => {
      this.backToMainView();
    }, 3500); // 3.5秒后返回 (与 LONG duration 匹配)
  }

  private async checkWinAndSaveRecord() {
    if (!this.isPlaying || !this.isSudokuComplete()) {
      return;
    }

    // --- 游戏胜利 ---
    LogUtil.info("Game Won!");

    this.stopTimer();
    this.isPlaying = false;

    const finalTime = this.cumulativeTime;
    const finalDifficulty = this.difficulty;

    LogUtil.info(`Final time for difficulty '${finalDifficulty}': ${finalTime}s`);

    try {
      // 3. 【第一步：更新数据库】
      //    调用 repository 的方法，等待它完成
      await gameRecordRepository.updateBestTimeIfNeeded(finalDifficulty, finalTime);
      LogUtil.info("Record update process completed.");

      // 4. 【第二步：重新读取以验证】
      //    再次从数据库中查询刚刚更新的难度的记录
      const updatedRecord = await gameRecordRepository.getRecordByDifficulty(finalDifficulty);

      // 5. 【准备弹窗内容】
      if (updatedRecord) {
        const bestTime = updatedRecord.bestTime;
        // 比较本次用时和数据库中的最佳时间，给出不同提示
        if (finalTime <= bestTime) {
          this.finalBestTimeMessage = `恭喜！您创造了新的纪录！\n\n难度: ${finalDifficulty}\n本次用时: ${finalTime}秒\n最佳纪录: ${bestTime}秒`;
        } else {
          this.finalBestTimeMessage = `恭喜您完成挑战！\n\n难度: ${finalDifficulty}\n本次用时: ${finalTime}秒\n最佳纪录: ${bestTime}秒`;
        }
      } else {
        // 这种情况理论上不会发生，因为 updateBestTimeIfNeeded 会确保记录存在
        this.finalBestTimeMessage = `恭喜完成！用时: ${finalTime}秒`;
      }

    } catch (error) {
      LogUtil.error("Failed to save or read the record:", error);
      this.finalBestTimeMessage = "完成！但保存或读取记录时发生错误。";
    }

    // 6. 【显示弹窗】
    //    此时 this.finalBestTimeMessage 已经有了包含了真实数据库数据的内容
    this.showGameOverDialog();
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

  // 日志级别信息
  undoCallback(changedPropertyName: string) {
    LogUtil.debug("undoCallBack this.undid : " + this.undid)
  }


}