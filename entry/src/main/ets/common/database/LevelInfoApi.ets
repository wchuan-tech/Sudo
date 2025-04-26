import { relationalStore } from '@kit.ArkData';
import { LevelInfo } from '../../data/Levelnfo';
import { LogUtil } from '../../utils/LogUtil';
import RdbUtils from './RdbUtils';
import { CommonConstants as Const } from '../constants/CommonConstants'
class LevelInfoApi {
  /**
   * Insert dayInfo.
   *
   * @param dayInfo
   * @param callback
   */
  insertData(levelInfo: LevelInfo, callback: Function): void {
    const valueBucket = generateBucket(levelInfo);
    RdbUtils.insert('level', valueBucket).then(result => {
      callback(result);
    });
    LogUtil.info('LevelInfoTable Insert dayInfo finished.');
  }
  /**
   * Update dayInfo.
   *
   * @param dayInfo
   * @param callback
   */
  updateData(levelInfo: LevelInfo, callback: Function): void {
    let tableName = Const.LEVEL_INFO.tableName
    if (!tableName) {
      return
    }
    LogUtil.debug("LevelInfoApi updateData table : " + tableName)
    const valueBucket = generateBucket(levelInfo);
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(tableName);
    predicates.equalTo('difficulty', levelInfo.difficulty);
    predicates.equalTo('level', levelInfo.level);
    LogUtil.debug("difficulty = " + levelInfo.difficulty + " level = " + levelInfo.level)
    RdbUtils.update(valueBucket, predicates).then((result: number) => {
      LogUtil.debug("RdbUtils update result : " + result)
      callback(result);
    });
    LogUtil.info('Update levelInfo finished.');
  }
  /**
   * Query dayInfo.
   *
   * @param date
   * @param callback
   */
  /**
   *     this.id = id
         this.difficulty = difficulty
         this.level = level
         this.errorCount = errorCount
         this.hintCount = hintCount
         this.locked = locked
         this.completed = completed
         this.data = data
         this.cumulativeTime = cumulativeTime
   * @param date
   * @param callback
   */
  query(difficulty: string, level: number, callback: Function): void {
    let tableName = Const.LEVEL_INFO.tableName
    if (!tableName) {
      return
    }
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(tableName);
    predicates.equalTo('difficulty', difficulty);
    predicates.equalTo('level', level);
    RdbUtils.query(predicates).then(resultSet => {
      let count = resultSet.rowCount;
      if (count === 0) {
        LogUtil.error('LevelInfoTable query no results.');
        let result = new LevelInfo(0, "easy", 0, 5, 5, true, false, "", 0)
        callback(result, count);
      }
      else {
        let result = new LevelInfo(0, "easy", 0, 5, 5, true, false, "", 0)
        resultSet.goToFirstRow();
        result.id = resultSet.getDouble(resultSet.getColumnIndex('id'));
        result.difficulty = resultSet.getString(resultSet.getColumnIndex('difficulty'));
        result.level = resultSet.getDouble(resultSet.getColumnIndex('level'));
        result.errorCount = resultSet.getDouble(resultSet.getColumnIndex('errorCount'));
        result.hintCount = resultSet.getDouble(resultSet.getColumnIndex('hintCount'));
        result.locked = resultSet.getDouble(resultSet.getColumnIndex('locked')) ? true : false;
        result.completed = resultSet.getDouble(resultSet.getColumnIndex('completed')) ? true : false;
        result.data = resultSet.getString(resultSet.getColumnIndex('data'));
        result.cumulativeTime = resultSet.getDouble(resultSet.getColumnIndex('cumulativeTime'));
        callback(result, count);
      }
      return;
    });
  }
  /**
   * Query dayInfo list.
   *
   * @param date
   * @param callback
   */
  queryList(difficulty: string, callback: Function): void {
    let tableName = Const.LEVEL_INFO.tableName
    if (!tableName) {
      return
    }
    LogUtil.debug("queryList tableName = " + tableName + ' difficulty = ' + difficulty)
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(tableName);
    predicates.equalTo('difficulty', difficulty);
    RdbUtils.query(predicates).then(resultSet => {
      let count = resultSet.rowCount;
      if (count === 0) {
        LogUtil.error('LevelInfoTable queryList no results.');
        let result: LevelInfo[] = [];
        callback(result, 0);
      }
      else {
        resultSet.goToFirstRow();
        let result: LevelInfo[] = [];
        for (let i = 0; i < count; i++) {
          let tmp = new LevelInfo(0, "easy", 0, 5, 5, true, false, "", 0)
          tmp.id = resultSet.getDouble(resultSet.getColumnIndex('id'));
          tmp.difficulty = resultSet.getString(resultSet.getColumnIndex('difficulty'));
          tmp.level = resultSet.getDouble(resultSet.getColumnIndex('level'));
          tmp.errorCount = resultSet.getDouble(resultSet.getColumnIndex('errorCount'));
          tmp.hintCount = resultSet.getDouble(resultSet.getColumnIndex('hintCount'));
          tmp.locked = resultSet.getDouble(resultSet.getColumnIndex('locked')) ? true : false;
          tmp.completed = resultSet.getDouble(resultSet.getColumnIndex('completed')) ? true : false;
          tmp.data = resultSet.getString(resultSet.getColumnIndex('data'));
          tmp.cumulativeTime = resultSet.getDouble(resultSet.getColumnIndex('cumulativeTime'));
          result[i] = tmp;
          resultSet.goToNextRow();
        }
        callback(result);
      }
    });
  }


  queryCompletedList(difficulty: string, completed: boolean, callback: Function): void {
    let tableName = Const.LEVEL_INFO.tableName
    if (!tableName) {
      return
    }
    LogUtil.debug("queryList tableName = " + tableName + ' difficulty = ' + difficulty)
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(tableName);
    predicates.equalTo('difficulty', difficulty);
    predicates.equalTo('completed', completed);
    RdbUtils.query(predicates).then(resultSet => {
      let count = resultSet.rowCount;
      if (count === 0) {
        LogUtil.error('LevelInfoTable queryList no results.');
        let result: LevelInfo[] = [];
        callback(result, 0);
      }
      else {
        resultSet.goToFirstRow();
        let result: LevelInfo[] = [];
        for (let i = 0; i < count; i++) {
          let tmp = new LevelInfo(0, "easy", 0, 5, 5, true, false, "", 0)
          tmp.id = resultSet.getDouble(resultSet.getColumnIndex('id'));
          tmp.difficulty = resultSet.getString(resultSet.getColumnIndex('difficulty'));
          tmp.level = resultSet.getDouble(resultSet.getColumnIndex('level'));
          tmp.errorCount = resultSet.getDouble(resultSet.getColumnIndex('errorCount'));
          tmp.hintCount = resultSet.getDouble(resultSet.getColumnIndex('hintCount'));
          tmp.locked = resultSet.getDouble(resultSet.getColumnIndex('locked')) ? true : false;
          tmp.completed = resultSet.getDouble(resultSet.getColumnIndex('completed')) ? true : false;
          tmp.data = resultSet.getString(resultSet.getColumnIndex('data'));
          tmp.cumulativeTime = resultSet.getDouble(resultSet.getColumnIndex('cumulativeTime'));
          result[i] = tmp;
          resultSet.goToNextRow();
        }
        callback(result);
      }
    });
  }
}


function generateBucket(levelInfo: LevelInfo): relationalStore.ValuesBucket {
  let valueBucket = {} as relationalStore.ValuesBucket;
  Const.LEVEL_INFO.columns?.forEach((item: string) => {
    switch (item) {
      case 'id':
        valueBucket.id = levelInfo.id;
        break;
      case 'difficulty':
        valueBucket.difficulty = levelInfo.difficulty;
        break;
      case 'level':
        valueBucket.level = levelInfo.level;
        break;
      case 'errorCount':
        valueBucket.errorCount = levelInfo.errorCount;
        break;
      case 'hintCount':
        valueBucket.hintCount = levelInfo.hintCount;
        break;
      case 'locked':
        valueBucket.locked = levelInfo.locked;
        break;
      case 'completed':
        valueBucket.completed = levelInfo.completed;
        break;
      case 'data':
        valueBucket.data = levelInfo.data;
        break;
      case 'cumulativeTime':
        valueBucket.cumulativeTime = levelInfo.cumulativeTime;
        break;
      default:
        break;
    }
  });
  return valueBucket;
}
let levelInfoApi = new LevelInfoApi();
export default levelInfoApi as LevelInfoApi;
