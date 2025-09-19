import { SudokuData } from '../data/SudokuModels';
import { LevelInfo } from '../data/Levelnfo';
import { LogUtil } from '../utils/LogUtil';
import LevelInfoApi from '../data/database/LevelInfoApi';
import { AlertDialog, display,promptAction } from '@kit.ArkUI';
import { GameRecordRepository} from '../data/database/GameRecordRepository';


interface Move {
  row: number;
  col: number;
  oldValue: number;
  newValue: number;
}

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

  @State
  gotError: boolean = false

  @State
  restarted: boolean = false

  @State
  undid:boolean = false

  @State
  editOn: boolean = false


  @Consume('navPathStack')
  pathStack: NavPathStack

  private boardSideLength = display.getDefaultDisplaySync().width * 0.9 - vp2px(5) * 2;

  // --- 游戏核心状态 ---
  @State private puzzle: number[][] = [];
  @State private solution: number[][] = [];
  @State private playerBoard: number[][] = [];
  @State private notes: number[][][] = []; // 笔记
  @State private errorBoard: boolean[][] = [];
  @State private historyStack: Move[] = []; // 撤销栈

  // --- 游戏过程状态 ---
  @State difficulty: string = "Loading...";
  @State isPlaying: boolean = true;
  @State cumulativeTime: number = 0;
  @State errorCount: number = 5;
  @State hpStates: boolean[] = [true, true, true, true, true];

  // --- 操作按钮状态 ---
  @State operate_buttons: string[] = ["undo", "erase", "edit"];
  @State private editMode: boolean = false; // 笔记模式
  @State editBadgeOn: boolean = false; // Badge 显示状态
  @State editBadgeColor: Resource = $r('app.color.operate_edit_off');


  PK: string = "PK"


  // 组件
  // 暂停/开始按钮
  @State buttonIcon:Resource = this.isPlaying ? $r('app.media.pause') : $r('app.media.play')
  @State elapsedTime: number = 0
  @State timerId: number = 1;

  @State
  curLevelInfo: LevelInfo = new LevelInfo(0, "newbie", 1, 5, 5, true, false, "", 0)
  @State
  hintCount: number = 5


  // 数字以及各类游戏操作
  @State
  values: string[] = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
  keypadNumbers: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  @State
  private highlightedNumber: number = 0; // 0 表示没有数字被高亮


  // 记录当前选中的单元格
  @State private selectedCell: CellPosition | null = null;

  @State private finalBestTimeMessage: string = "正在计算...";

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

      // 【新增】初始化一个空的 9x9xN 的笔记数组
      this.notes = Array(9).fill(0).map(() => Array(9).fill(0).map(() => []));

      // 【新增】每次新游戏开始时，清空历史记录
      this.historyStack = [];

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
        Row() {
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
        .backgroundColor($r('app.color.sudoku_board_background'))
        .enabled(this.isPlaying ? true : false)



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
        .height('10%') // 或者一个固定的 vp 值，例如 .height(150)
        .enabled(this.isPlaying ? true : false)

        GridRow({
          columns: 3,
          gutter: {
            x: 10,
            y: 10},
          direction: GridRowDirection.Row
        }) {
          ForEach(this.operate_buttons, (operate: string) => {
            GridCol() {
              Button(
                {
                  type: ButtonType.Capsule,  stateEffect: true}
              ){
                this.operateBuild(operate)
              }
              .id(operate)
              .fontColor(Color.Black)
              .fontSize(18)
              .buttonStyle(ButtonStyleMode.NORMAL)
              .width('100%')
              .clickEffect({level:ClickEffectLevel.LIGHT})
              .onClick(() => {
                switch (operate) {
                  case "undo":
                    this.clickUndoButton()
                    break
                  case "erase":
                    this.clickEraseButton()
                    break
                  case "edit":
                    this.clickEditButton()
                    break
                }
              })
            }
          })
        }
        .id('operate_button')
        .alignRules({top: {anchor: "keys", align: VerticalAlign.Bottom}})
        .margin({
          left: $r('app.float.column_padding_left'),
          right: $r('app.float.column_padding_right'),
          top: $r('app.float.column_padding_top')})
        .enabled(this.isPlaying ? true : false)
      } // end of RelativeContainer
      .width('100%')
      .height('100%')
    } // end of NavDestination
    .backgroundColor($r('app.color.sudoku_board_background'))
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.onInit(context)
    })

  }


  @Builder
  operateBuild(operate: string) {
    Column() {
      if(operate == "edit") {
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

  // 绘制可交互的游戏棋盘
  @Builder
  GameBoard() {
    Stack() {
      this.buildOnlineGridLines();
      Grid() {
        ForEach(this.playerBoard, (row: number[], rowIndex: number) => {
          ForEach(row, (cellValue: number, colIndex: number) => {
            GridItem() {
              // 【核心修改】使用 Stack 来叠放主数字和笔记
              Stack() {
                // 渲染主数字
                Text(cellValue === 0 ? "" : cellValue.toString())
                  .width('100%')
                  .height('100%')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Center)
                  .fontColor(
                    this.puzzle[rowIndex][colIndex] !== 0 ? $r('app.color.bar_selected_color') :
                      (this.errorBoard[rowIndex][colIndex] ? Color.Red : Color.Blue)
                  )

                // 【核心修改】如果主数字为空，且有笔记，则渲染笔记
                if (cellValue === 0 && this.notes[rowIndex][colIndex]?.length > 0) {
                  Grid() {
                    ForEach(this.notes[rowIndex][colIndex], (noteValue:number) => {
                      GridItem() {
                        Text(noteValue.toString())
                          .fontSize(8)// 笔记字体更小
                          .fontColor($r('app.color.text_color_value_note'))
                      }
                    })
                  }
                  .columnsTemplate('1fr 1fr 1fr')
                  .rowsTemplate('1fr 1fr 1fr')
                  .width('90%')
                  .height('90%')
                }
              }
              .backgroundColor((Math.floor(rowIndex / 3) + Math.floor(colIndex / 3)) % 2 === 0 ?
              $r('app.color.sudoku_board_background') : $r('app.color.level_background'))
              .border({
                width: this.selectedCell?.row === rowIndex && this.selectedCell?.col === colIndex ? 3 : 0,
                color: Color.Orange
              })
              .onClick(() => {
                if (!this.isPlaying) return;
                if (this.puzzle[rowIndex][colIndex] === 0) {
                  this.selectedCell = { row: rowIndex, col: colIndex };
                }
              })
            }
          })
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .aspectRatio(1)
      .border({ width: 2, color: $r('app.color.text_color_keys') })
    }
  }

  // 绘制数字输入键盘
  @Builder
  NumberPad() {
    Grid() {
      ForEach(this.keypadNumbers, (num: number) => {
        GridItem() {
          Button() {
            Text(num.toString())
              .fontColor("#FFFAF0")
              .fontSize(24)
          }
          .type(ButtonType.Circle).
          width('90%').
          aspectRatio(1)
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
            Column().
            width('100%').
            height('100%').
            border({ width: 2})
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
    }
  }


  private updatePlayerBoard(row: number, col: number, valueNum: number) {
    if (!this.isPlaying || this.puzzle[row][col] !== 0) return;

    if (this.editMode) {
      // --- 笔记模式 ---
      const newNotes = JSON.parse(JSON.stringify(this.notes)) as number[][][];
      const cellNotes = newNotes[row][col];
      const noteIndex = cellNotes.indexOf(valueNum);
      if (noteIndex > -1) {
        cellNotes.splice(noteIndex, 1);
      } else {
        cellNotes.push(valueNum);
        cellNotes.sort();
      }
      this.notes = newNotes;
    } else {
      // --- 填数模式 ---
      const oldValue = this.playerBoard[row][col];
      if (oldValue === valueNum) return;

      this.historyStack.push({ row, col, oldValue, newValue: valueNum });

      const newBoard = [...this.playerBoard];
      newBoard[row][col] = valueNum;
      this.playerBoard = newBoard;

      // 填数后清除笔记
      if (this.notes[row][col]?.length > 0) {
        const newNotes = JSON.parse(JSON.stringify(this.notes)) as number[][][];
        newNotes[row][col] = [];
        this.notes = newNotes;
      }

      // 错误检查和胜利检查逻辑
      this.checkWinAndSaveRecord();
    }
  }

  private clickUndoButton() {
    if (this.historyStack.length === 0) {
      promptAction.showToast({ message: "没有可撤销的操作" });
      return;
    }
    const lastMove = this.historyStack.pop()!;
    const newBoard = [...this.playerBoard];
    newBoard[lastMove.row][lastMove.col] = lastMove.oldValue;
    this.playerBoard = newBoard;
  }

  private clickEraseButton() {
    if (this.selectedCell) {
      const row:number = this.selectedCell.row;
      const col:number = this.selectedCell.col;
      if (this.puzzle[row][col] !== 0)
        return;

      if (this.playerBoard[row][col] !== 0) {
        this.updatePlayerBoard(row, col, 0);
        promptAction.showToast({ message: "不可擦除!" });
      }
      if (this.notes[row][col]?.length > 0) {
        const newNotes = JSON.parse(JSON.stringify(this.notes)) as number[][][];
        newNotes[row][col] = [];
        this.notes = newNotes;
        promptAction.showToast({ message: "擦除成功" });
      }
    }
  }

  private clickEditButton() {
    this.editMode = !this.editMode;
    this.editBadgeOn = this.editMode;
    this.editBadgeColor = this.editBadgeOn ? $r('app.color.operate_edit_on') : $r('app.color.operate_edit_off');
    promptAction.showToast({ message: this.editMode ? "笔记模式 ON" : "笔记模式 OFF" });
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

  private showGameOverDialog() {
    promptAction.showToast({
      message: this.finalBestTimeMessage,
      duration: 3500
    })

    // 延迟一小段时间返回主菜单
    setTimeout(() => {
      this.backToMainView();
    }, 3500);
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
      const gameRecordRepository = new GameRecordRepository();

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


}