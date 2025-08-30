import {
  display,
  LengthMetrics,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonItemOptionsArray,
  SegmentButtonItemTuple,
  SymbolGlyphModifier
} from '@kit.ArkUI';


import { geoLocationManager } from '@kit.LocationKit'

// 蓝牙模块
import { ble } from '@kit.ConnectivityKit';
import bluetooth from '@ohos.bluetooth';
import  {Bluetooth} from '@kit.ConnectivityKit';
import { access } from '@kit.ConnectivityKit';
import { connection } from '@kit.ConnectivityKit';

// api接口使用
import { GameNetworkViewModel } from '../viewmodel/GameNetworkViewModel';
import { JuheSudokuResult } from '../data/ApiService';
import { SudokuData } from '../data/SudokuModels';

import { Cell } from '../data/Cell';
import { LogUtil } from '../utils/LogUtil';
import { RawUtils } from '../utils/RawUtils';
import { DataUtil } from '../utils/DataUtil';
import { LevelInfo } from '../data/Levelnfo';
import { ToastUtil } from '../utils/ToastUtil';
import LevelInfoApi from '../common/database/LevelInfoApi';
import { GridConstants } from '../common/constants/GridConstants';
import { StyleConstants } from '../common/constants/StyleConstants';
import { Header } from './views/Header';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { BreakpointSystem } from '../utils/BreakpointSystem';
import { MineView } from './views/MineView';
import { Difficulty } from '../common/normal/Difficulty';
import { common, ConfigurationConstant, EnvironmentCallback } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import { CommonConstants } from '../common/constants/CommonConstants';

import { promptAction } from '@kit.ArkUI'; // 导入 promptAction 用于显示对话框




import { BusinessError } from '@ohos.base';

interface PuzzleDisplayParam {
  puzzle: number[][];
}

@Entry
@Component
struct Index {

  // 在线模式
  @State private gameViewModel: GameNetworkViewModel = new GameNetworkViewModel();
  callbackId: number = 0;

  @Provide('navPathStack')
  pathStack: NavPathStack = new NavPathStack()


  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @StorageLink('deviceHeight') deviceHeight: number = 0;
  @State message: string = 'Hello World';
  private boardSideLength = display.getDefaultDisplaySync().width - vp2px(5) * 2;
  // private heightVp = this.getUIContext.px2vp(boardSideLength)
  private vp = this.boardSideLength / display.getDefaultDisplaySync().width * 100
  private marginTop = display.getDefaultDisplaySync().width * 0.25;
  highVp: number = px2vp(this.boardSideLength)
  @State
  selectedIndex: number = 0
  @State
  curDifficulty: Difficulty = Difficulty.Newbie
  difficultyArray: Difficulty[] =
    [Difficulty.Newbie, Difficulty.Easy, Difficulty.Middle, Difficulty.Hard, Difficulty.Hell]
  @State
  levelInfos: LevelInfo[] = []
  private controller: TabsController = new TabsController()
  // levelInfos: List<LevelInfo> = new List<LevelInfo>()
  @State singleSelectCapsuleOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: $r('app.string.difficulty_newbie') }, { text: $r('app.string.difficulty_easy') },
      { text: $r('app.string.difficulty_middle') }, { text: $r('app.string.difficulty_hard') },
      { text: $r('app.string.difficulty_hell') }] as SegmentButtonItemTuple,
    multiply: false,
    fontSize: $r('app.float.title_normal_size'),
    selectedFontSize: $r('app.float.title_normal_size'),
    backgroundColor: $r('app.color.segment_background'),
    selectedBackgroundColor: $r('app.color.segment_select_color'),
    backgroundBlurStyle: BlurStyle.BACKGROUND_THICK
  })
  
  @State
  @Watch('onTabChange')
  tabSelectedIndexes: number[] = [0]

  @State isScanning: boolean = false;
  @State foundDevices: ble.ScanResult[] = [];

  private context = getContext(this) as common.UIAbilityContext;

  @StorageLink('colorMode')
  @Watch("listenerColorModeChange")
  colorMode: ConfigurationConstant.ColorMode | undefined = this.context.config.colorMode;

  aboutToAppear(): void {
    // AppStorage.setOrCreate("PathStack", this.pathStack)
    LogUtil.debug("Index aboutToAppear")
    this.breakpointSystem.register();
    this.initData(this.curDifficulty)

    this.subscribeConfigurationUpdate()
  }

  aboutToDisappear(): void {
    this.breakpointSystem.unregister()
    LogUtil.debug("aboutToDisappear")
  }

  initData(difficulty: string) {
    LevelInfoApi.queryList(difficulty, (result: LevelInfo[]) => {
      this.levelInfos = result
      // LogUtil.debug("queryList callback length = " + result.length)
      let lastLevelCompleted = false
      this.levelInfos.forEach((value: LevelInfo, index: number) => {
        // LogUtil.debug('levelInfo : ' + value.toString() + ' index : ' + index)
        if (value.locked && lastLevelCompleted) {
          value.locked = false
        }
        if (value.completed) {
          lastLevelCompleted = true
        } else {
          lastLevelCompleted = false
        }
      })
      if (this.levelInfos && this.levelInfos.length == 0) {
        for (let index = 0; index < 100; index++) {
          let completed = false
          let locked = true
          if (index == 0) {
            LogUtil.debug("set locked = false")
            locked = false
          }
          let id = this.getIdStart(difficulty) + index
          let info = new LevelInfo(id, difficulty, index + 1, 5, 5, locked, completed, "", 0)
          this.levelInfos.push(info)
          // LogUtil.debug("info locked = " + info.locked)
          LevelInfoApi.insertData(info, (result: number) => {
            LogUtil.debug("insertData result = " + result)
          })
        }
      }
    })
  }

  @Builder
  NavigationMenus() {
    Row() {
      Image($r('app.media.home'))
        .width(24)
        .height(24)
      Image($r('app.media.history'))
        .width(24)
        .height(24)
        .margin({ left: 24 })

    }
  }

  @Builder
  CustomToolbar() {
    Row() {
      Column() {
        Image($r('app.media.home'))
          .size({ width: 25, height: 25 })
          .renderMode(this.selectedIndex == 0 ? ImageRenderMode.Original : ImageRenderMode.Template)
        Text($r('app.string.toolbar_home'))
          .fontSize(16)
          .fontColor(this.selectedIndex == 0 ? $r('app.color.bar_selected_color') :
          $r('app.color.bar_unselected_color'))
          .padding({ top: $r('app.float.menu_padding') })
      }
      .alignItems(HorizontalAlign.Center)
      .height('100%')
      .layoutWeight(1)
      .onClick(() => {
        this.selectedIndex = 0;
        ToastUtil.showToast('主页')
      })

      Column() {
        Image($r('app.media.me'))
          .size({ width: 25, height: 25 })
          .renderMode(this.selectedIndex == 1 ? ImageRenderMode.Original : ImageRenderMode.Template)
        Text($r('app.string.toolbar_me'))
          .fontSize(16)
          .fontColor(this.selectedIndex == 1 ? $r('app.color.bar_selected_color') :
          $r('app.color.bar_unselected_color'))
          .padding({ top: $r('app.float.menu_padding') })
      }
      .alignItems(HorizontalAlign.Center)
      .height('100%')
      .layoutWeight(1)
      .onClick(() => {
        this.selectedIndex = 1;
        ToastUtil.showToast('排行榜')
        this.pathStack.pushPathByName("Mine", null)
      })
    }
  }

  // this.selectedIndex === targetIndex ? :
  @Builder
  TabBuilder(title: string, targetIndex: number, normalImg: Resource) {
    Column() {
      Image(normalImg)
        .size({ width: 25, height: 25 })
        .renderMode(this.selectedIndex == targetIndex ? ImageRenderMode.Original : ImageRenderMode.Template)
      Text(title)
        .fontColor(this.selectedIndex === targetIndex ? '#1698CE' : '#6B6B6B')
    }
    .width('100%')
    .height(50)
    .backgroundColor($r('app.color.item_background'))
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Navigation(this.pathStack) {
      Column({ space: 4 }) {
        Tabs({ barPosition: BarPosition.End, index: 0, controller: this.controller }) {
          TabContent() {
            Column() {
              this.buildHeader()

              // this.bluetoothItem()
              this.onlineModeItem();

              this.buildLevelContent()
            }
          }
          .padding({
            // top: $r('app.float.column_padding_top'),
            left: $r('app.float.column_padding_left'),
            right: $r('app.float.column_padding_right'),
          })
          .height(StyleConstants.FULL_HEIGHT)
          .tabBar(this.TabBuilder(getContext(this).resourceManager.getStringSync($r('app.string.toolbar_home')), 0,
            $r('app.media.home')))

          // .tabBar(new BottomTabBarStyle($r('app.media.home'), $r('app.string.toolbar_home')))
          TabContent() {
            MineView()
          }
          .padding({
            // top: $r('app.float.column_padding_top'),
            left: $r('app.float.column_padding_left'),
            right: $r('app.float.column_padding_right'),
          })
          .height(StyleConstants.FULL_HEIGHT)
          .tabBar(this.TabBuilder(getContext(this).resourceManager.getStringSync($r('app.string.toolbar_me')), 1,
            $r('app.media.me')))
        }
        .vertical(false)
        .height(StyleConstants.FULL_HEIGHT)
        .width(StyleConstants.FULL_WIDTH)
        // .barBackgroundColor($r('app.color.toolbar_background_color'))
        .fadingEdge(true)
        .barOverlap(true)
        .onChange((index: number) => {
          LogUtil.debug("Tabs Onchange index " + index)
          this.selectedIndex = index
          switch (index) {
            case 0:
              ToastUtil.showToast('主页')
              break;
            case 1:
              ToastUtil.showToast('用户中心')
              break
            default:
              BreakpointConstants
          }
        })

      }
      .height(StyleConstants.FULL_HEIGHT)
    }
    .mode(NavigationMode.Stack)
    .height(StyleConstants.FULL_HEIGHT)
    .hideTitleBar(true)
    .hideToolBar(true)
    .backgroundColor($r('app.color.view_background'))
    .toolbarConfiguration(this.CustomToolbar())
    .hideToolBar(true)
  }


  // =================================================================
  // 方法一：重构 onlineModeItem (功能不变，保持原样)
  // 这个方法职责很清晰：触发网络请求。
  // =================================================================
  @Builder
  onlineModeItem() {
    Row() {
      Image($r('app.media.about'))
        .width(24).height(24).margin({ right: 10 })
      Text("在线模式")
        .fontSize($r('app.float.description_font_size'))
        .fontColor($r('app.color.item_name_color'))
      Blank()
      if (this.gameViewModel.isLoading) {
        Progress({ value: 0, total: 100 }).width(20).height(20)
      } else {
        Text("获取新谜题")
          .fontSize(12)
          .fontColor($r('app.color.bar_selected_color'))
          .padding({ left: 8, right: 8, top: 4 })
          .border({
            width: 1,
            color: $r('app.color.bar_selected_color'),
            radius: 8
          })
      }
    }
    .width('100%')
    .height(CommonConstants.Item_Height)
    .padding({ left: 8, right: 8, top: 4 })
    .backgroundColor($r('app.color.level_background'))
    .borderRadius(12)
    .onClick(async () => {
      // 点击时，依然是调用 ViewModel 的方法来获取数据
      await this.gameViewModel.fetchOnlineSudoku(1);
      const puzzleData = this.gameViewModel.juhePuzzle;

      if (puzzleData) {
        const params: SudokuData = {
          puzzle: puzzleData.puzzle,
          solution: puzzleData.solution
        };

        // =======================================================
        // ↓↓↓↓↓↓     核心修改：使用带回调的 pushPathByName      ↓↓↓↓↓↓
        // =======================================================
        this.pathStack.pushPathByName(
          "OnlineGamePage", // 目标页面
          params,           // 传递的参数
          () => {           // onPop 回调函数
            LogUtil.debug("Popped back from OnlineGamePage.");
            // 在这里可以执行任何您需要的操作，比如刷新主页数据、显示提示等。
            // 例如，我们可以清空 ViewModel 中的数据，以便下次重新获取
            this.gameViewModel.juhePuzzle = null;
            promptAction.showToast({ message: "欢迎回来！" });
          }
        );

      }
    })
  }


  // @Builder
  // bluetoothItem() {
  //   Row() {
  //     // 你可以找一个合适的图标
  //     Image($r('app.media.item_dark')) // 暂时借用一下深色模式的图标
  //       .height('100%')
  //       .padding({left: $r('app.float.column_padding_left')})
  //
  //     Text("蓝牙设备扫描") // 功能名称
  //       .padding({left: $r('app.float.column_padding_left')})
  //       .fontSize($r('app.float.description_font_size'))
  //       .fontColor($r('app.color.item_name_color'))
  //
  //     Blank()
  //
  //     Image($r("app.media.item_list_more"))
  //       .padding({right: CommonConstants.PADDING})
  //       .height('50%')
  //   }
  //   .width('100%')
  //   .height(CommonConstants.Item_Height)
  //   .onClick(() => {
  //     // 3. ==================== 在这里调用蓝牙扫描功能 ====================
  //
  //
  //     this.handleStartScanWithLogging();
  //
  //     // 注意：扫描结果会打印在 Logcat/HiLog 中。
  //     // 如果要跳转到新页面进行扫描和连接，可以在这里使用 this.pathStack.pushPath(...)
  //   })
  //
  //   if (this.isScanning && this.foundDevices.length === 0) {
  //     Text("正在扫描，请稍候...")
  //       .margin({ top: 20 })
  //       .fontColor(Color.Gray)
  //   } else if (this.foundDevices.length > 0) {
  //     // 如果有设备，就显示列表
  //     List({ space: 10 }) {
  //       ForEach(this.foundDevices, (device: ble.ScanResult) => {
  //         ListItem() {
  //           Text(device.deviceName ? device.deviceName : `Unknown (${device.deviceId.substring(0,8)}...)`)
  //             .fontSize(16)
  //             .padding(10)
  //             .width('100%')
  //         }
  //         .backgroundColor($r('app.color.level_background'))
  //         .borderRadius(8)
  //       })
  //     }
  //     .layoutWeight(1) // 让列表占据剩余空间
  //   }
  //
  // }

  // 2. ==================== 使用 async/await 改造函数 ====================
  // private async handleStartScanWithLogging(): Promise<void> {
  //   // 1. 检查蓝牙状态
  //   const isEnabled = bluetooth.getState() === bluetooth.BluetoothState.STATE_ON;
  //
  //   if (isEnabled) {
  //     // 蓝牙已开启，直接开始扫描
  //     this.startScanProcedure();
  //     return; // 结束函数
  //   }
  //
  //   // 2. 蓝牙未开启，弹出对话框引导用户
  //   try {
  //     const dialogResult = await promptAction.showDialog({
  //       title: "蓝牙未开启",
  //       message: "为了发现并连接设备，数独游戏需要您开启蓝牙。",
  //       buttons: [{ text: '取消', color: '#000000' }, { text: '去开启', color: '#007DFF' }]
  //     });
  //
  //     if (dialogResult.index === 1) { // 用户点击了 "去开启"
  //       ToastUtil.showToast("请在系统弹窗中允许开启蓝牙");
  //
  //       // 3. ==================== 在这里嵌入蓝牙启动功能 ====================
  //       //    调用封装好的函数，并等待它的结果
  //       access.enableBluetooth();
  //       // =================================================================
  //
  //         // Promise resolve(true) 了，说明蓝牙已成功开启
  //         ToastUtil.showToast("蓝牙已开启，开始扫描...");
  //         this.startScanProcedure();
  //       // 如果 success 是 false (虽然我们的实现里没有这种情况) 或 Promise reject 了，
  //       // catch 块会处理
  //     } else {
  //       ToastUtil.showToast("操作已取消");
  //     }
  //   } catch (err) {
  //     // 这个 catch 会捕获 showDialog 的失败或 requestEnableBluetooth 的 reject
  //     ToastUtil.showLong(`操作失败: ${(err as Error).message}`);
  //   }
  // }
  //
  // private startScanProcedure(): void {
  //   ToastUtil.showToast("开始扫描蓝牙设备...");
  //   this.foundDevices = [];
  // }

  @Builder
  buildHeader() {
    Header({ currentBreakpoint: this.currentBreakpoint })
  }

  @Builder
  buildLevelContent() {
    SegmentButton({
      options: this.singleSelectCapsuleOptions,
      selectedIndexes: this.tabSelectedIndexes
    })
      .id("segment_difficulty")
      .margin({ left: 5, right: 5, top: 20 })

    RelativeContainer() {
      // BoardView(inpu)
      this.buildLevels(this.levelInfos)
    }
    .id("layout_board")
    .border({ width: 1, color: Color.Gray })
    .borderRadius(5)
    .margin({
      left: 5,
      right: 5,
      top: 20,
      bottom: 20
    })
    .height('50%')
  }

  @Builder
  buildLevels(levelInfos: Array<LevelInfo>) {
    RelativeContainer() {
      Grid() {
        ForEach(this.levelInfos, (info: LevelInfo) => {
          GridItem() {
            Stack() {
              Image($r('app.media.star'))
                .width('40%')
                .renderMode(info.completed ? ImageRenderMode.Original : ImageRenderMode.Template)
                .visibility(info.locked ? Visibility.Hidden : Visibility.Visible)
                .onClick(() => {
                  this.startGame(info)
                })
              Image($r('app.media.lock_red'))
                .width('40%')
                .visibility(info.locked ? Visibility.Visible : Visibility.Hidden)
                .onClick(() => {
                  ToastUtil.showLong($r('app.string.tip_level_unlocked'))
                })
            }
            .margin({ top: 5, bottom: 5 })
          }
          .width('20%')
          .backgroundColor($r('app.color.level_background'))
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
    }
    .margin({
      top: 5,
      bottom: 5,
      right: 5,
      left: 5
    })
  }

  startGame(info: LevelInfo) {
    let difficulty: string = info.difficulty
    let level: number = info.level;
    let errorCount: number = info.errorCount;
    let hintCount: number = info.hintCount;
    let puzzle: string[][], solution: string[][]
    let data = ""
    if (info.data == "") {
      LogUtil.debug(`difficulty : ${difficulty}, level : ${level}`)
      let content = RawUtils.readRawConfigData(difficulty, level)
      if (content != null) {
        // LogUtil.debug("read " + difficulty + " leve " + level + " content : " + content)
        let splitContent: string[] = content.split('solution：').map(part => part.trim());
        let puzzlePart: string = splitContent[0];
        let solutionPart: string = splitContent[1];
        let puzzle: string[][] = puzzlePart
          .split('\n')
          .slice(1)// 跳过第一个标记 "puzzle：" 行
          .map(line => line.trim().split(' '));
        let solution: string[][] = solutionPart
          .split('\n')
          .map(line => line.trim().split(' '));
        let gameDataMap: Map<number, Cell> = this.initMap(puzzle, solution)
        data = DataUtil.map2JsonString<number, Cell>(gameDataMap);
        LogUtil.debug("init Map data = " + data)
        info.data = data
        // LogUtil.debug("puzzle\n" + puzzle)
        // LogUtil.debug("solution\n" + solution)
      }
    } else {
      data = info.data
    }
    if (data == "") {
      LogUtil.error("获取不到关卡数据")
      return
    }
    LevelInfoApi.updateData(info, (result: number) => {
      LogUtil.debug("update Level Table result : " + result)
    })
    // this.pathStack.pushPath({name: 'PageSudoku', param: info})
    let pathInfo: NavPathInfo = new NavPathInfo('PageSudoku', info
      , (popInfo: PopInfo) => {
        LogUtil.debug("pop callback")
        this.initData(this.curDifficulty)
      })
    // this.pathStack.pushDestination(pathInfo, true)
    this.pathStack.pushPathByName('PageSudoku', info, () => {
      LogUtil.debug("pop callback")
      this.initData(this.curDifficulty)
    })
  }

  count: number = 16;

  initMap(puzzle: string[][], solution: string[][]): Map<number, Cell> {
    let cells: Map<number, Cell> = new Map<number, Cell>()
    for (let i = 0; i < this.count; i++) {
      for (let j = 0; j < this.count; j++) {
        // let value = this.boardString.charAt(this.count * j + i);
        let value = puzzle[i][j]
        let correctValue = solution[i][j]
        if (value != "Z") {
          let cell: Cell = new Cell(i, j, value, value, correctValue, false, true, false)
          cells.set(this.count * i + j, cell);
        } else {
          let cell: Cell = new Cell(i, j, value, value, correctValue, false, false, false)
          cells.set(this.count * i + j, cell);
        }
      }
    }
    return cells
  }

  onTabChange(changedPropertyName: string) {

    LogUtil.debug((`选中按钮索引 -- ${this.tabSelectedIndexes}`))
    this.curDifficulty = this.difficultyArray[this.tabSelectedIndexes[0]]
    this.initData(this.curDifficulty)
  }

  getIdStart(difficulty: string): number {
    switch (difficulty) {
      case Difficulty.Newbie:
        return 0
      case Difficulty.Easy:
        return 1000
      case Difficulty.Middle:
        return 2000
      case Difficulty.Hard:
        return 3000
      case Difficulty.Hell:
        return 4000
      default:
        return 10000
    }
  }

  envCallback: EnvironmentCallback = {
    onConfigurationUpdated(config) {
      LogUtil.info(`envCallback onConfigurationUpdated success: ${JSON.stringify(config)}`);
      let mode = config.colorMode;
      LogUtil.debug('envCallback onConfigurationUpdated mode = ' + config.colorMode)
      if (mode == ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
        // emitter.emit("colorModeChange")//发送消息模式改变
        //深色模式
        LogUtil.debug("深色模式")
        // getContext(this).getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
      } else if (mode == ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
        //浅色模式
        LogUtil.debug("浅色模式")
        // getContext(this).getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
      }
      emitter.on("colorModeChange", () => {
        //模式发生变化，UI做出相应变化
        this.context.getApplicationContext().setColorMode(mode)
      })
    },
    onMemoryLevel(level){
      console.log(`onMemoryLevel level: ${JSON.stringify(level)}`);
    }
  };

  subscribeConfigurationUpdate(): void {
    let systemLanguage: string | undefined = this.context.config.language; // 获取系统当前语言

    // 1.获取ApplicationContext
    let applicationContext = this.context.getApplicationContext();

    // 2.通过applicationContext订阅环境变量变化
    try {
      this.callbackId = applicationContext.on('environment', this.envCallback);
    } catch (err) {
      // let code = (err as BusinessError).code;
      // let message = (err as BusinessError).message;
      // hilog.error(DOMAIN_NUMBER, TAG, `Failed to register applicationContext. Code is ${code}, message is ${message}`);
    }
  }

  listenerColorModeChange(changedPropertyName: string) {
    LogUtil.debug("listenerColorModeChange colorMode = " + this.colorMode)
  }
}


function MiniView() {
  throw new Error('Function not implemented.');
}
