import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import { LogUtil } from '../utils/LogUtil';

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
  // 聚合数据 API 相关常量
  private readonly JUHE_APP_KEY = "d6901e04c4f74bf8968b193987e744c8";
  private readonly JUHE_SUDOKU_URL = "http://apis.juhe.cn/fapig/sudoku/generate";

  // 自有服务器 API 地址 (示例)
  private readonly BASE_URL = "https://api.your-sudoku-game.com";

  /**
   * 从聚合数据API获取一个新的数独谜题
   */
  async getSudokuFromJuhe(level: number): Promise<JuheSudokuResult> {
    const url = `${this.JUHE_SUDOKU_URL}?level=${level}&key=${this.JUHE_APP_KEY}`;
    LogUtil.debug(`ApiService: Requesting Sudoku from Juhe: ${url}`);

    let httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, { method: http.RequestMethod.GET });

      if (response.responseCode === http.ResponseCode.OK) {
        const apiResponse: JuheApiResponse = JSON.parse(response.result as string);
        if (apiResponse.error_code === 0) {
          return apiResponse.result;
        } else {
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
    // 修正：添加一个 return/throw 语句来覆盖所有代码路径
    throw new Error('ApiService: getSudokuFromJuhe function reached an unhandled state.');
  }

  /**
   * 获取每日挑战 (示例)
   */
  async getDailyPuzzle(): Promise<DailyPuzzle> {
    const url = `${this.BASE_URL}/daily_puzzle`;
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
    // 修正：添加一个 return/throw 语句来覆盖所有代码路径
    throw new Error('ApiService: getDailyPuzzle function reached an unhandled state.');
  }

  /**
   * 提交分数到排行榜 (示例)
   */
  async submitScore(levelId: number, playerName: string, timeInSeconds: number): Promise<void> {
    const url = `${this.BASE_URL}/leaderboard/submit`;
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