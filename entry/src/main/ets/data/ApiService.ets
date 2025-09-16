import http from '@ohos.net.http';
import { LogUtil } from '../utils/LogUtil';
import { ApiConstants } from '../constants/ApiConstants';
import { CommonConstants } from '../constants/CommonConstants';
import { PreferencesUtil } from '../utils/PreferencesUtil';

// =================================================================
// 1. 数据模型定义 (Interfaces)
// =================================================================

/** 聚合数据API外层包裹的结构 */
export interface JuheApiResponse {
  reason: string;
  result: JuheSudokuResult;
  error_code: number;
}

/** 聚合数据API返回的数独谜题结果 */
export interface JuheSudokuResult {
  puzzle: number[][];
  solution: number[][];
  level: number;
}

/** “每日挑战”谜题的数据结构 (示例) */
export interface DailyPuzzle {
  puzzleId: string;
  date: string;
  difficulty: string;
  puzzleData: string[][];
  solutionData: string[][];
}

/** 排行榜条目的数据结构 (示例) */
export interface LeaderboardEntry {
  rank: number;
  playerName: string;
  timeInSeconds: number;
}


// =================================================================
// 2. 网络服务类 (ApiService Class)
// =================================================================

class ApiService {

  private async canCallApi(): Promise<boolean> {
    const today = new Date().toISOString().slice(0, 10); // 获取 YYYY-MM-DD 格式的今天日期

    // 从 Preferences 中读取上次的调用日期和次数
    const lastCallDate = await PreferencesUtil.getString(ApiConstants.API_CALL_DATE_KEY);
    let callCount = await PreferencesUtil.getNumber(ApiConstants.API_CALL_COUNT_KEY);

    if (lastCallDate === today) {
      // 如果是同一天
      if (callCount >= ApiConstants.JUHE_API_DAILY_LIMIT) {
        // 次数已超限
        LogUtil.warn(`API daily limit of ${ApiConstants.JUHE_API_DAILY_LIMIT} reached.`);
        return false;
      }
    } else {
      // 如果是新的一天，重置计数器
      LogUtil.info("New day, resetting API call count.");
      callCount = 0;
      await PreferencesUtil.putSync(ApiConstants.API_CALL_DATE_KEY, today);
    }

    return true;
  }

  private async recordApiCall(): Promise<void> {
    const today = new Date().toISOString().slice(0, 10);
    let callCount = await PreferencesUtil.getNumber(ApiConstants.API_CALL_COUNT_KEY);

    // 确保日期是最新的（防止跨天问题）
    const lastCallDate = await PreferencesUtil.getString(ApiConstants.API_CALL_DATE_KEY);
    if(lastCallDate !== today) {
      callCount = 0;
      await PreferencesUtil.put(ApiConstants.API_CALL_DATE_KEY, today);
    }

    callCount++;
    await PreferencesUtil.put(ApiConstants.API_CALL_COUNT_KEY, callCount);
    LogUtil.info(`API call recorded. Today's count: ${callCount}`);
  }

  /**
   * 从聚合数据API获取一个新的数独谜题
   */
  async getSudokuFromJuhe(difficulty:string): Promise<JuheSudokuResult> {

    if (!(await this.canCallApi())) {
      throw new Error("今日免费次数已用完");
    }

    const url = `${ApiConstants.JUHE_BASE_URL}${ApiConstants.JUHE_SUDOKU_PATH}?key=${ApiConstants.JUHE_APP_KEY}&difficulty=${difficulty}`;
    LogUtil.debug(`ApiService: Requesting Sudoku from Juhe: ${url}`);

    let httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, { method: http.RequestMethod.GET });

      if (response.responseCode === http.ResponseCode.OK) {
        const apiResponse: JuheApiResponse = JSON.parse(response.result as string);
        if (apiResponse.error_code === 0) {
          await this.recordApiCall();
          return apiResponse.result;
        } else {
          if (apiResponse.error_code === 10012) {
            throw new Error("今日免费次数已用完");
          }
          throw new Error(apiResponse.reason);
        }
      } else {
        throw new Error(`HTTP Error: ${response.responseCode}`);
      }
    } catch (err) {
      if (err instanceof Error) {
        LogUtil.error(`ApiService: getSudokuFromJuhe failed: ${err.message}`);
        throw err;
      } else {
        const errorMessage = `An unexpected error occurred in getSudokuFromJuhe: ${JSON.stringify(err)}`;
        LogUtil.error(errorMessage);
        throw new Error(errorMessage);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 获取每日挑战
   */
  async getDailyPuzzle(): Promise<DailyPuzzle> {
    const url = `${ApiConstants.JUHE_BASE_URL}/daily_puzzle`;
    LogUtil.debug(`ApiService: Fetching daily puzzle from ${url}`);
    let httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(url, { method: http.RequestMethod.GET });
      if (response.responseCode === http.ResponseCode.OK) {
        const data: DailyPuzzle = JSON.parse(response.result as string);
        return data;
      } else {
        throw new Error(`Failed to fetch daily puzzle. Status: ${response.responseCode}`);
      }
    } catch (err) {
      if (err instanceof Error) {
        LogUtil.error(`ApiService: getDailyPuzzle failed: ${err.message}`);
        throw err;
      } else {
        const errorMessage = `An unexpected error occurred in getDailyPuzzle: ${JSON.stringify(err)}`;
        LogUtil.error(errorMessage);
        throw new Error(errorMessage);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 提交分数到排行榜 (示例)
   */
  async submitScore(levelId: number, playerName: string, timeInSeconds: number): Promise<void> {
    const url = `${ApiConstants.MY_API_BASE_URL}/leaderboard/submit`;
    LogUtil.debug(`ApiService: Submitting score to ${url}`);
    let httpRequest = http.createHttp();

    const body = JSON.stringify({
      levelId: levelId,
      playerName: playerName,
      time: timeInSeconds
    });

    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: body
      });

      if (response.responseCode !== http.ResponseCode.CREATED && response.responseCode !== http.ResponseCode.OK) {
        throw new Error(`Failed to submit score. Status: ${response.responseCode}`);
      }
      // 对于 Promise<void>，成功时不需要 return 语句
    } catch (err) {
      if (err instanceof Error) {
        LogUtil.error(`ApiService: submitScore failed: ${err.message}`);
        throw err;
      } else {
        const errorMessage = `An unexpected error occurred in submitScore: ${JSON.stringify(err)}`;
        LogUtil.error(errorMessage);
        throw new Error(errorMessage);
      }
    } finally {
      httpRequest.destroy();
    }
  }
}

// =================================================================
// 3. 导出单例
// =================================================================

export const apiService = new ApiService();