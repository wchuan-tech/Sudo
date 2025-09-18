/**
 * ApiConstants.ts
 * 统一管理所有与网络API相关的常量
 */

// --- 聚合数据 API ---
export class ApiConstants {
  static readonly JUHE_BASE_URL = "http://apis.juhe.cn/fapig";

  static readonly JUHE_SUDOKU_PATH = "/sudoku/generate";

  static readonly JUHE_APP_KEY = "d6901e04c4f74bf8968b193987e744c8";
  // --- 自有服务器 API (示例) ---
  static readonly MY_API_BASE_URL = "https://api.your-sudoku-game.com";
  // --- 通用网络配置 ---
  static readonly REQUEST_TIMEOUT = 15000; // 请求超时时间 (毫秒)

  // 新增：用于 API 次数管理的 Preferences 键
  static readonly API_CALL_DATE_KEY = 'api_call_date'; // 存储上次调用API的日期 (格式: YYYY-MM-DD)
  static readonly API_CALL_COUNT_KEY = 'api_call_count'; // 存储当天已调用次数

  // 聚合数据每天的免费次数是 50 次
  static readonly JUHE_API_DAILY_LIMIT = 50;
}