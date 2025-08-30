import { common } from '@kit.AbilityKit';
import { ToastUtil } from '../utils/ToastUtil';
import { SudokuData } from '../data/SudokuModels';
import { LevelInfo } from '../data/Levelnfo';
import { LogUtil } from '../utils/LogUtil';
import LevelInfoApi from '../common/database/LevelInfoApi';
import { DataUtil } from '../utils/DataUtil';
import { AlertDialog, ButtonOptions, display, LengthMetrics, promptAction, router } from '@kit.ArkUI';

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


  // saveData
  @State
  cumulativeTime: number = 0;
  @State
  curLevelInfo: LevelInfo = new LevelInfo(0, "newbie", 1, 5, 5, true, false, "", 0)






  // 从导航参数中接收谜题和答案
  @Consume('navPathStack') pathStack: NavPathStack

  @State private puzzle: number[][] = [];
  @State private solution: number[][] = [];
  // 专门用于玩家操作的棋盘，是 puzzle 的一个深拷贝
  @State private playerBoard: number[][] = [];
  // 记录当前选中的单元格
  @State private selectedCell: CellPosition | null = null;


  onReady(context: NavDestinationContext) {
    const params = router.getParams() as SudokuData;
    if (params && params.puzzle) {
      this.puzzle = params.puzzle;
      this.solution = params.solution;
      this.playerBoard = JSON.parse(JSON.stringify(params.puzzle));
      ToastUtil.showToast("开始挑战吧！");
    } else {
      ToastUtil.showLong("错误：无法加载谜题数据。");
      setTimeout(() => {
        this.pathStack?.pop();
      }, 1500);
    }
  }

  // 检查答案
  checkSolution() {
    for (let i = 0; i < 9; i++) {
      for (let j = 0; j < 9; j++) {
        // 如果玩家填写的数字（非0）与答案不符
        if (this.playerBoard[i][j] !== 0 && this.playerBoard[i][j] !== this.solution[i][j]) {
          ToastUtil.showLong("很遗憾，有错误哦，请再检查一下！");
          return;
        }
        // 如果有空格未填写
        if (this.playerBoard[i][j] === 0) {
          ToastUtil.showLong("谜题还没完成哦！");
          return;
        }
      }
    }
    // 如果所有检查都通过
    ToastUtil.showLong("恭喜你，挑战成功！");
  }

  build() {
    NavDestination() {
      RelativeContainer() {
        Text("1"){
          Span("2")
        }
        Button({type: ButtonType.Circle,stateEffect: true}){
          Row(){
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
        })



      }
      }
  }

  togglePlayPause() {
    throw new Error('Method not implemented.');
  }


  backToMainView() {
    throw new Error('Method not implemented.');
  }

  savaGameData() {
    this.curLevelInfo.cumulativeTime = this.cumulativeTime
    LogUtil.debug("savaGameData time : " + this.curLevelInfo.cumulativeTime)
    LevelInfoApi.updateData(this.curLevelInfo, (result: number) => {
      LogUtil.debug("saveGameData callback result : " + result)
    })
    LevelInfoApi.query(this.curLevelInfo.difficulty, this.curLevelInfo.level, (result: LevelInfo, count: number) => {
      LogUtil.debug("saveGameData query number : " + count + " cumulativeTime = " + result.cumulativeTime)
    })
  }

  // 绘制可交互的游戏棋盘
  @Builder
  GameBoard() {
    Stack() {
      // 底层：绘制网格线
      this.buildOnlineGridLines()

      // 顶层：绘制数字
      Grid() {
        ForEach(this.playerBoard, (row: number[], rowIndex: number) => {
          ForEach(row, (cellValue: number, colIndex: number) => {
            GridItem() {
              Text(cellValue === 0 ? "" : cellValue.toString())
                .width('100%').height('100%')
                .fontSize(22).fontWeight(FontWeight.Bold)
                // 初始数字用主题色，玩家填写的数字用另一种颜色
                .fontColor(this.puzzle[rowIndex][colIndex] !== 0 ?
                $r('app.color.bar_selected_color') : $r('app.color.text_color_keys'))
                .textAlign(TextAlign.Center)
                .backgroundColor((Math.floor(rowIndex / 3) + Math.floor(colIndex / 3)) % 2 === 0 ?
                $r('app.color.sudoku_board_background') : $r('app.color.level_background'))
                  // 选中单元格高亮
                .border({
                  width: this.selectedCell?.row === rowIndex && this.selectedCell?.col === colIndex ? 3 : 0,
                  color: Color.Orange
                })
                .onClick(() => {
                  // 只有空格子才能被选中和修改
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
    }
    .aspectRatio(1).width('90%')
    .border({ width: 2, color: $r('app.color.text_color_keys') })
  }

  // 绘制数字输入键盘
  @Builder
  NumberPad() {
    Grid() {
      ForEach(Array.from({ length: 9 }), (_: undefined, index: number) => {
        GridItem() {
          Button((index + 1).toString())
            .fontSize(20)
            .width('90%')
            .aspectRatio(1)
            .onClick(() => {
              if (this.selectedCell) {
                // 更新玩家棋盘上对应格子的数字
                this.playerBoard[this.selectedCell.row][this.selectedCell.col] = index + 1;
              }
            })
        }
      })
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .width('95%')
    .margin({ top: 20 })
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
}