import {
  display,
  LengthMetrics,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonItemOptionsArray,
  SegmentButtonItemTuple,
  SymbolGlyphModifier
} from '@kit.ArkUI';

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


@Entry
@Component
struct Index {
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
