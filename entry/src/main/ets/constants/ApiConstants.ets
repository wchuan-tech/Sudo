/**
 * ApiConstants.ts
 * 统一管理所有与网络API相关的常量
 */

// --- 聚合数据 API ---
export const JUHE_BASE_URL = "http://apis.juhe.cn/fapig";
export const JUHE_SUDOKU_PATH = "/sudoku/generate";
export const JUHE_APP_KEY = "d6901e04c4f74bf8968b193987e744c8"; // 警告：在真实项目中，AppKey 不应硬编码在客户端

// --- 自有服务器 API (示例) ---
export const MY_API_BASE_URL = "https://api.your-sudoku-game.com";

// --- 通用网络配置 ---
export const REQUEST_TIMEOUT = 15000; // 请求超时时间 (毫秒)