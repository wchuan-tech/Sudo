import { AbilityConstant, Configuration, ConfigurationConstant,
  EnvironmentCallback,
  UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { mediaquery, window } from '@kit.ArkUI';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { AppUtil } from '../utils/AppUtil';
import RdbUtils from '../data/database/RdbUtils';
import ColumnInfo from '../data/ColumnInfo';
import { LogUtil } from '../utils/LogUtil';
import { CommonConstants } from '../constants/CommonConstants';
import {  emitter } from '@kit.BasicServicesKit';
import { GlobalContext } from '../data/GlobalContext';

import { DB_CONFIG, TBL_GAME_RECORDS, TBL_LEVEL_INFO
  ,TBL_LEVEL} from '../constants/DatabaseConstants';


export default class EntryAbility extends UIAbility {

  followSystemMode: boolean = false
  useDayMode: boolean = true

  callbackId: number = 0

  currentMode?: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT

  sudokuDb: string = DB_CONFIG.DB_NAME // 数据库名称

  async onCreate() {

    GlobalContext.setContext(this.context);

    try {
      await this.initDataBase();
      LogUtil.info('Database has been successfully initialized in EntryAbility.');
    } catch (error) {
      LogUtil.error('FATAL: Database initialization failed in EntryAbility.', error);
    }


    //添加订阅
    this.callbackId = this.context.getApplicationContext()
      .on('environment',this.envCallback);
  }

  onDestroy(): void {
    this.context.getApplicationContext().off('environment', this.callbackId)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {

    AppUtil.init(this.context, windowStage)

    LogUtil.debug("onWindowStageCreate")
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    LogUtil.debug("StageCreate this.context.config.colorMode = " + this.context.config.colorMode)

    this.currentMode = this.context.config.colorMode
    AppStorage.setOrCreate(CommonConstants.ColorMode, this.context.config.colorMode);
    PreferencesUtil.init(CommonConstants.PreferenceName)

    this.followSystemMode = PreferencesUtil.getBooleanSync(CommonConstants.FollowSystem)
    LogUtil.debug("followSystemMode = " + this.followSystemMode)

    if (!this.followSystemMode) {
      let mode: ConfigurationConstant.ColorMode = this.useDayMode ? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT : ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      this.context.getApplicationContext().setColorMode(mode)
    }


    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');

    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }

  async initDataBase(): Promise<void> {

    LogUtil.info("Ranking database (Rdb.db) initialized successfully.");
    RdbUtils.initDb(this.context, this.sudokuDb);
    await RdbUtils.createDb();

  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtil.debug("newConfig.colorMode = " + newConfig.colorMode + " this.currentMode = " + this.currentMode)
  }

  /**
   * 切换模式后的回调
   */
  envCallback: EnvironmentCallback = {
    onConfigurationUpdated(config) {

      LogUtil.info(`envCallback onConfigurationUpdated success: ${JSON.stringify(config)}`);
      let mode = config.colorMode;
      LogUtil.debug('envCallback onConfigurationUpdated mode = ' + config.colorMode)

      if (mode == ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
        //深色模式
        LogUtil.debug("深色模式")
        } else if (mode == ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
        //浅色模式
        LogUtil.debug("浅色模式")
        }
      emitter.on("colorModeChange", () => {
        let followSystem: boolean = PreferencesUtil.getBooleanSync(CommonConstants.FollowSystem)
        LogUtil.debug("emitter change this.followSystemMode " + followSystem)
        if (followSystem) {
          //模式发生变化，UI做出相应变化
          this.context.getApplicationContext().setColorMode(config.colorMode)
        }
      })
    },
    onMemoryLevel(level){
      console.log(`onMemoryLevel level: ${JSON.stringify(level)}`);
    }
  };

}
