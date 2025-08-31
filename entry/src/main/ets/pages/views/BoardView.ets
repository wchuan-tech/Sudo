import { display, promptAction, router } from '@kit.ArkUI';
import { Cell } from '../../data/Cell';
import { LevelData } from '../../data/LevelData';
import { LogUtil } from '../../utils/LogUtil';
import List from '@ohos.util.List';
import { resourceManager } from '@kit.LocalizationKit';
import { Stack } from '@kit.ArkTS';

enum TextDrawState {
  Select = "SELECTED",
  HintSelect = "HINT_SELECTED",
  Change = "CHANGED"
}

enum Operate {
  Erase = "erase",
  Note = "note",
  Hint = "hint",
  Undo = "undo"
}

@Component
export struct BoardView {
  @State count: number = 16;
  private boardString: string =
    "0000100000040000000000000700000000000900000000680000000000000005000000000000000000000100000040000000000000700000000000900000000680000000000000005000000000000000000000100000040000000000000700000000000900000000680000000000000005000000000000000000000000000000";
  private canvasWidth: number = display.getDefaultDisplaySync().width * 0.98;
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  viewScale = Math.floor(display.getDefaultDisplaySync().width / display.getDefaultDisplaySync().height * 10)

  private selectedCellRow: number = -1;
  private selectedCellCol: number = -1;

  private curSelectedValue: string = "Z"

  @Link
  @Watch("doReset")
  restarted: boolean

  @Link
  @Watch("doHint")
  hintClicked: boolean

  @Link
  @Watch("doEditOn")
  editOn: boolean

  @Link
  @Watch("doUndid")
  undid: boolean

  @Link
  @Watch("doErase")
  erased: boolean

  private inputCells: Stack<Cell> = new Stack<Cell>()

  // private cells: List<Cell> = new List<Cell>();
  @Link
  @Watch("listenerData")
  cells: Map<number, Cell>

  @Link
  @Watch("updateValue")
  inputValue: string;

  defaultValueColor: number = getContext(this).resourceManager.getColorSync($r('app.color.text_color_value'));
  errorValueColor: number = getContext(this).resourceManager.getColorSync($r('app.color.text_color_value_error'));
  noteValueColor: number = getContext(this).resourceManager.getColorSync($r('app.color.text_color_value_note'));
  highLightColor: number = getContext(this).resourceManager.getColorSync($r('app.color.cell_background_color_high_light'));
  selectedHighLightColor: number = getContext(this).resourceManager.getColorSync($r('app.color.cell_background_color_high_light_selected'));

  @Link
  gotError:boolean

  @Link
  gotCorrectValue: string

  aboutToAppear(): void {
    this.defaultValueColor = getContext(this).resourceManager.getColorSync($r('app.color.text_color_value').id);
    this.errorValueColor = getContext(this).resourceManager.getColorSync($r('app.color.text_color_value_error').id);
    this.noteValueColor = getContext(this).resourceManager.getColorSync($r('app.color.text_color_value_note').id);
    this.highLightColor = getContext(this).resourceManager.getColorSync($r('app.color.cell_background_color_high_light').id);
    this.selectedHighLightColor = getContext(this).resourceManager.getColorSync($r('app.color.cell_background_color_high_light_selected').id);
    LogUtil.debug("defaultValueColor = " + this.defaultValueColor)
  }

  build() {
    Column() {
      Canvas(this.context)                        // 设置Canvas所需要的context
        // .size({width: '100%', height: '100%'})    // 设置Canvas的宽高
        // .backgroundColor(Color.Gray)
        .onReady(() => {                          // 监听回调，在回调内执行绘画操作
          // this.context.fillRect(10, 10, 130, 40); // 以(10, 10)为起点坐标，画矩形，默认黑色
          this.drawGrid()
          // this.initDrawText()
          this.drawText(TextDrawState.Change)
        })
        .onTouch((event: TouchEvent) => {
          let touch = event.touches[0];  // 获取触摸点
          let x = touch.x
          let y = touch.y
          this.handleTouch(x, y);  // 调用处理函数，判断在哪个方格内
        })
    }
    .width('100%')
    .height('100%')
  }

  // 处理触摸事件，计算点击的方格
  handleTouch(x: number, y: number) {
    // 计算所在的方格行和列
    let cellWidth = this.context.width / this.count;
    let row = Math.floor(y / cellWidth);  // 通过y坐标确定行
    let col = Math.floor(x / cellWidth);   // 通过x坐标确定列

    // 更新显示的方格信息
    let touchedCell = `你点击了第 ${row + 1} 行, 第 ${col + 1} 列`;
    // 打印调试信息
    console.log(`点击位置: x=${x}, y=${y}, 行=${row + 1}, 列=${col + 1}`);
    this.selectedCellRow = row
    this.selectedCellCol = col
    this.updateRowAndCol(row, col)
  }

  replaceAtIndex(str: string, index: number, replacement: string): string {
    if (index < 0 || index >= str.length) {
      throw new Error("Index out of bounds");  // 检查索引范围
    }
    return str.slice(0, index) + replacement + str.slice(index + 1);
  }

  updateValue() {
    console.log("BoardView updateValue this.inputValue = ", this.inputValue)
    // 每次先赋值没有错误,父组件观察到数字变化但不进行操作
    this.gotError = false
    // 每次先赋值正确值为Z,父组件观察到变化但不进行操作
    this.gotCorrectValue = "Z"
    if (this.selectedCellRow != -1 && this.selectedCellCol != -1 && this.inputValue != "Z") {
      // this.drawCell(this.selectedCellRow, this.selectedCellCol, this.inputValue)
      // let index = this.selectedCellRow + 1;
      // if(this.selectedCellCol)
      let index = this.count * (this.selectedCellRow) + this.selectedCellCol;
      console.log("index = ", index)

      let curCell: Cell | undefined = this.cells.get(index);

      // 检查 curCell 是否真的存在，防止 undefined 错误
      if (!curCell) {
        LogUtil.error(`BoardView.updateValue: Cannot find cell at index ${index}. Aborting.`);
        return; // 如果找不到单元格，直接退出函数，避免崩溃
      }
      // =======================================================

      let correctValue = curCell._correctValue; // 现在 curCell 一定有值，这行是安全的

      if (curCell._locked == false) {
        LogUtil.debug("当前值不是锁定状态，可以修改")
        curCell._value = this.inputValue;
      } else {
        LogUtil.debug("当前值是锁定状态，不可以修改")
        this.dealHintValue()
        return
      }

      // // 判断值是否正确
      if (this.editOn) {
        LogUtil.debug("当前编辑笔记状态")
        curCell._error = false
        curCell._locked = false
        curCell._noted = true
        this.inputCells.push(curCell)
      } else if (this.inputValue == correctValue) {
        LogUtil.debug("输入值正确")
        curCell._locked = true
        curCell._error = false
        curCell._noted = false
        this.gotCorrectValue = this.curSelectedValue = curCell._value
        // 判断到值正确，清除输入值堆栈，避免撤回把已经正确的值撤回
        this.inputCells = new Stack<Cell>();
      } else {
        LogUtil.debug("输入值错误 this.gotError : " + this.gotError)

        curCell._error = true
        curCell._locked = false
        curCell._noted = false
        this.gotError = true
        this.inputCells.push(curCell)
      }
      this.cells.set(index, curCell)
      LogUtil.debug("canvas reset")
      this.doRedraw()
    } else if (this.selectedCellRow == -1 && this.selectedCellCol == -1 && this.inputValue != "Z")  {
      this.dealHintValue()
    }
  }

  dealHintValue() {
    this.context.reset()
    // this.initDrawText()
    this.drawText(TextDrawState.HintSelect)
    this.drawGrid()
    this.inputValue = "Z"
  }

  resetState() {
    this.inputValue = "Z"
    this.selectedCellRow = -1;
    this.selectedCellCol = -1;
    this.curSelectedValue = "Z"
  }

  // 绘制单个方格的内容
  drawCell(row: number, col: number, value: string) {
    this.updateRowAndCol(row, col)
    let cellWidth = this.context.width / this.count;
    let x = col * cellWidth + (cellWidth / 3);
    let y = row * cellWidth + (cellWidth / 4) * 3;

    this.context.fillStyle = "#FF0000";
    this.context.font = Math.ceil(cellWidth) * 2 + "px sans-serif";
    this.context.fillText(value, x, y);
    // this.offContext.fillText()
  }

  // 更新点击的整行和整列
  updateRowAndCol(row: number, col: number) {
    this.context.reset();  // 先重置整个画布


    let cellWidth = this.context.width / this.count;
    let index = this.count * (this.selectedCellRow) + this.selectedCellCol;
    LogUtil.debug("updateRowAndCol index = " + index)
    if (index < 0 || index >= this.count * this.count) {
      return
    }
    let curCell = this.cells.get(index) as Cell
    this.curSelectedValue = curCell._value
    // 高亮点击的整行
    for (let i = 0; i < this.count; i++) {
      this.context.fillStyle = this.highLightColor
      this.context.fillRect(i * cellWidth, row * cellWidth, cellWidth, cellWidth);
    }

    // 高亮点击的整列
    for (let j = 0; j < this.count; j++) {
      this.context.fillStyle = this.highLightColor
      this.context.fillRect(col * cellWidth, j * cellWidth, cellWidth, cellWidth);
    }

    // 重新绘制文本内容
    this.drawText(TextDrawState.Select);
    this.drawGrid();       // 重新绘制网格
  }

  // 绘制网格
  public drawGrid(): void {
    let cellWidth = this.context.width / this.count;

    // 绘制水平和垂直线
    for (let i = 1; i < this.count; i++) {
      let startY = i * cellWidth;
      this.context.beginPath();
      this.context.lineWidth = (i % 4 == 0) ? 1.5 : 0.2;
      this.context.moveTo(0, startY);
      this.context.lineTo(this.canvasWidth, startY);
      this.context.stroke();
    }

    for (let i = 1; i < this.count; i++) {
      let startX = i * cellWidth;
      this.context.beginPath();
      this.context.lineWidth = (i % 4 == 0) ? 1.5 : 0.5;
      this.context.moveTo(startX, this.canvasWidth);
      this.context.lineTo(startX, 0);
      this.context.stroke();
    }
  }

  // 绘制每个单元格的文本内容
  drawText(state: TextDrawState) {
    let cellWidth = this.context.width / this.count;

    this.cells.forEach(cellElement => {
      let value = cellElement._value
      if (value != "Z") {
        let x = cellElement._col * cellWidth + (cellWidth / this.viewScale);
        let y = cellElement._row * cellWidth + (cellWidth / this.viewScale) * (this.viewScale - 1);
        if (value == this.curSelectedValue && state == TextDrawState.Select) {
          this.drawMatchValueHighlight(cellElement)
        }
        if (value == this.inputValue && state == TextDrawState.HintSelect) {
          LogUtil.debug("do HintSelect")
          this.drawMatchValueHighlight(cellElement)
        }
        if (cellElement._noted == true) {
          LogUtil.debug("drawText note is true")
          // this.context.fillStyle = '#708090'
          this.context.fillStyle = this.noteValueColor
          this.context.font = Math.ceil(cellWidth) * 2 + "px sans-serif";
          this.context.fillText(value, x, y);
        } else {
          if (cellElement._error) {
            // this.context.fillStyle = $r('app.color.text_color_value') as ResourceColor
            this.context.fillStyle = this.errorValueColor
          } else {
            this.context.fillStyle = this.defaultValueColor
          }
          this.context.font = Math.ceil(cellWidth) * 2 + "px sans-serif";
          this.context.fillText(value, x, y);
        }

      }
    });
  }

  drawHintText() {
    let cellWidth = this.context.width / this.count;

    this.cells.forEach(cellElement => {
      let value = cellElement._value
      if (value != "Z") {
        let x = cellElement._col * cellWidth + (cellWidth / 3);
        let y = cellElement._row * cellWidth + (cellWidth / 4) * 3;
        if (cellElement._error) {
          this.context.fillStyle = "#FF0000";
        } else {
          this.context.fillStyle = "#000000"
        }
        this.context.font = Math.ceil(cellWidth) * 2 + "px sans-serif";
        this.context.fillText(value, x, y);
      }
    });
  }

  drawMatchValueHighlight(cell: Cell) {
    LogUtil.debug("drawMatchValueHighlight curSelectedValue " + cell._value)
    let cellWidth = this.context.width / this.count;
    let x = cell._col * cellWidth
    let y = cell._row * cellWidth
    this.context.fillStyle = this.selectedHighLightColor
    this.context.fillRect(x, y, cellWidth, cellWidth)
  }

  doReset(changedPropertyName: string) {
    LogUtil.debug("BoardView call doReset this.restarted : " + this.restarted)
    if (this.restarted) {
      this.inputCells = new Stack<Cell>()
      this.context.reset()
      this.drawGrid()
      // this.initDrawText()
      this.drawText(TextDrawState.Change)
      this.resetState()
      this.restarted = false
    }
  }

  doHint(changedPropertyName: string) {
    LogUtil.debug("doHint hintClicked = " + this.hintClicked)
    if (!this.hintClicked) {
      return
    }
    if (this.selectedCellCol != -1 && this.selectedCellRow != -1) {
      let index = this.count * (this.selectedCellRow) + this.selectedCellCol;
      console.log("index = ", index)
      let curCell:Cell = this.cells.get(index) as Cell
      let correctValue = curCell._correctValue
      if (!curCell._locked) {
        this.gotCorrectValue = curCell._value = correctValue
        this.doRedraw()
        this.hintClicked = false
        return
      }
    }
    // 从第一个格子开始遍历，找到空格，再从leveData._solution 获取到值填入
    // 这里只能
    let cellElement = this.getSpaceCell()
    if (cellElement != null) {
      let hintValue: string = cellElement._correctValue
      cellElement._value = hintValue
      this.doRedraw()
      this.hintClicked = false
    }
    return
  }

  getSpaceCell(): Cell | null{
    for (let index = 0; index < this.cells.size; index++) {
      let cellElement = this.cells.get(index) as Cell;
      let value = cellElement._value
      if (value == "Z") {
        LogUtil.debug("foreach 111")
        return cellElement
      }
    }
    return null
  }

  doEditOn(changedPropertyName: string) {
    console.log("enter doEditOn editOn : " + this.editOn)
  }

  doUndid(changedPropertyName: string) {

    if (this.undid) {
      if (this.inputCells.length > 0) {
        let topCell = this.inputCells.pop()
        let index = this.count * (topCell._row) + topCell._col;
        let needUndoCell = this.cells.get(index) as Cell
        needUndoCell._value = 'Z'
        needUndoCell._locked = false
        needUndoCell._error = false
        needUndoCell._noted = false

        this.context.reset()
        this.drawText(TextDrawState.Change)
        this.drawGrid()
        this.resetState()
      } else {
        promptAction.showToast({
          message: $r('app.string.no_operation_can_be_undone'),
          duration: 1000
        });
      }
    }
    this.undid = false
  }

  doErase(changedPropertyName: string) {
    if (!this.erased) {
      return
    }
    if (this.selectedCellRow != -1 && this.selectedCellCol != -1) {
      let index = this.count * (this.selectedCellRow) + this.selectedCellCol;
      let currentSelectedCell = this.cells.get(index) as Cell
      if (currentSelectedCell._error || currentSelectedCell._noted) {
        currentSelectedCell._value = "Z"
        this.doRedraw()
      } else {
        promptAction.showToast({
          message: $r('app.string.erase_error_cannot_erase'),
          duration: 1000
        });
        return
      }
    } else {
      promptAction.showToast({
        message: $r('app.string.erase_error_no_selected'),
        duration: 1000
      });
    }
    this.erased = false
  }

  doRedraw() {
    this.context.reset()
    this.drawText(TextDrawState.Change)
    this.drawGrid()
    this.resetState()
  }

  listenerData(changedPropertyName: string) {
    LogUtil.debug("ListenerData this.cells")
  }
}