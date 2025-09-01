// src/main/ets/database/GameRecordRepository.ts

import { relationalStore } from '@kit.ArkData';
import type { ValuesBucket } from '@kit.ArkData';
import { rdbHelper } from './RdbHelperImp';
import { GameRecord } from './GameRecord';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogUtil } from '../../utils/LogUtil'; // 假设您有 LogUtil

const TABLE_NAME = 'game_records';

class GameRecordRepository {

  /**
   * 检查并更新指定难度的最小时间。
   * @param difficulty 要检查和更新的难度
   * @param newTime 来自游戏的、新的完成时间（秒）
   * @returns Promise<void> - 操作完成时，Promise 会被解决或拒绝
   */
  public async updateBestTimeIfNeeded(difficulty: string, newTime: number): Promise<void> {
    LogUtil.info(`Attempting to update best time for '${difficulty}' with new time ${newTime}s.`);

    // 1. 【统一错误处理】用一个 try...catch 包裹所有可能失败的数据库操作
    try {
      // 2. 【第一步：查询】直接调用 rdbHelper 的公共 query 方法，并等待结果
      //    我们不再关心底层的 store 或回调
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo('difficulty', difficulty);

      const resultSet = await rdbHelper.query(predicates, ['best_time']);

      if (resultSet.rowCount > 0) {
        // --- 记录已存在 ---
        resultSet.goToFirstRow();
        const oldBestTime = resultSet.getLong(resultSet.getColumnIndex('best_time'));

        // 3. 【重要】查询完毕，立即关闭 resultSet
        resultSet.close();

        // 4. 【第二步：比较】
        if (newTime < oldBestTime) {
          // 5. 【第三步：更新】
          LogUtil.info(`New time ${newTime}s is better than ${oldBestTime}s. Updating record...`);
          const valuesToUpdate: ValuesBucket = { 'best_time': newTime };
          const updatePredicates = new relationalStore.RdbPredicates(TABLE_NAME);
          updatePredicates.equalTo('difficulty', difficulty);

          await rdbHelper.update(valuesToUpdate, updatePredicates);
          LogUtil.info("Record updated successfully.");
        } else {
          LogUtil.info(`New time ${newTime}s is not better. No update needed.`);
        }
      } else {
        // --- 记录不存在 ---
        // 6. 【重要】确保在不存在记录时也关闭 resultSet
        resultSet.close();

        // 7. 【第三步：插入】
        LogUtil.info(`No record found for '${difficulty}'. Inserting new record...`);
        const valuesToInsert: ValuesBucket = {
          'difficulty': difficulty,
          'best_time': newTime
        };
        await rdbHelper.insert(TABLE_NAME, valuesToInsert);
        LogUtil.info("New record inserted successfully.");
      }
    } catch (err) {
      // 8. 【统一处理】任何一步（query, update, insert）失败，都会在这里被捕获
      LogUtil.error('Error in updateBestTimeIfNeeded:', err);
      // 将错误向上抛出，让 ViewModel 知道操作失败了
      if (err instanceof Error) {
        // 如果 err 本身就是一个 Error 对象，直接重新抛出它，
        // 这样可以保留完整的错误信息和堆栈跟踪
        throw err;
      } else {
        // 如果 err 是其他类型（比如一个字符串），则创建一个新的 Error 对象
        throw new Error(`An unexpected, non-Error type was thrown: ${JSON.stringify(err)}`);
      }
    }
  }

  public async getRecordByDifficulty(difficulty: string): Promise<GameRecord | null> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo('difficulty', difficulty);
    let resultSet = await rdbHelper.query(predicates, ['best_time']);
    try {
      resultSet = await rdbHelper.query(predicates);
      if (resultSet.rowCount === 0) return null;
      resultSet.goToFirstRow();
      return {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        difficulty: resultSet.getString(resultSet.getColumnIndex('difficulty')),
        bestTime: resultSet.getLong(resultSet.getColumnIndex('best_time'))
      };
    } finally {
      // 【优化】这个 finally 块确保了无论 try 中是 return 还是出错，都会执行 close
      if (resultSet) {
        resultSet.close();
      }
    }
  }
}

// 导出一个该类的单例，供整个应用使用
export const gameRecordRepository = new GameRecordRepository();