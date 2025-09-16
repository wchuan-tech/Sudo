// src/main/ets/common/constants/DatabaseConstants.ts

/**
 * 数据库全局常量
 */
export abstract class DB_CONFIG {
  static readonly DB_NAME = 'SudokuApp.db'; // 统一的数据库文件名
  static readonly DB_VERSION = 1; // 当前数据库版本
}

/**
 * 'game_records' 表的常量定义
 */
export abstract class TBL_GAME_RECORDS {
  // 表名
  static readonly NAME = 'game_records';

  // 列名
  static readonly COL_ID = 'id';
  static readonly COL_DIFFICULTY = 'difficulty';
  static readonly COL_BEST_TIME = 'best_time';

  // 创建表的 SQL 语句
  static readonly SQL_CREATE = `
    CREATE TABLE IF NOT EXISTS ${TBL_GAME_RECORDS.NAME} (
      ${TBL_GAME_RECORDS.COL_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${TBL_GAME_RECORDS.COL_DIFFICULTY} TEXT NOT NULL UNIQUE,
      ${TBL_GAME_RECORDS.COL_BEST_TIME} INTEGER NOT NULL
    )
  `;
}

/**
 * 'level_info' 表的常量定义 (示例)
 */
export abstract class TBL_LEVEL_INFO {
  // 表名
  static readonly NAME = 'level_info';

  // 列名
  static readonly COL_ID = 'id';
  static readonly COL_DIFFICULTY = 'difficulty';
  static readonly COL_LEVEL = 'level';
  static readonly COL_DATA = 'data';
  static readonly COL_COMPLETED = 'completed';

  // 创建表的 SQL 语句
  static readonly SQL_CREATE = `
    CREATE TABLE IF NOT EXISTS ${TBL_LEVEL_INFO.NAME} (
      ${TBL_LEVEL_INFO.COL_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${TBL_LEVEL_INFO.COL_DIFFICULTY} TEXT NOT NULL,
      ${TBL_LEVEL_INFO.COL_LEVEL} INTEGER NOT NULL,
      ${TBL_LEVEL_INFO.COL_DATA} TEXT NOT NULL,
      ${TBL_LEVEL_INFO.COL_COMPLETED} INTEGER NOT NULL DEFAULT 0
    )
  `;
}

/**
 * 'level' 表的常量定义
 */
export abstract class TBL_LEVEL {
  // 表名
  static readonly NAME = 'level';

  // 列名
  static readonly COL_ID = 'id';
  static readonly COL_DIFFICULTY = 'difficulty';
  static readonly COL_LEVEL = 'level';
  static readonly COL_ERROR_COUNT = 'errorCount';
  static readonly COL_HINT_COUNT = 'hintCount';
  static readonly COL_LOCKED = 'locked';
  static readonly COL_COMPLETED = 'completed';
  static readonly COL_DATA = 'data';
  static readonly COL_CUMULATIVE_TIME = 'cumulativeTime';

  // 创建表的 SQL 语句
  static readonly SQL_CREATE = `
    CREATE TABLE IF NOT EXISTS ${TBL_LEVEL.NAME} (
      ${TBL_LEVEL.COL_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${TBL_LEVEL.COL_DIFFICULTY} TEXT NOT NULL,
      ${TBL_LEVEL.COL_LEVEL} INTEGER NOT NULL,
      ${TBL_LEVEL.COL_ERROR_COUNT} INTEGER NOT NULL,
      ${TBL_LEVEL.COL_HINT_COUNT} INTEGER NOT NULL,
      ${TBL_LEVEL.COL_LOCKED} INTEGER NOT NULL,
      ${TBL_LEVEL.COL_COMPLETED} INTEGER NOT NULL,
      ${TBL_LEVEL.COL_DATA} TEXT NOT NULL,
      ${TBL_LEVEL.COL_CUMULATIVE_TIME} INTEGER NOT NULL
    )
  `;

  // UNIQUE 约束可以单独创建索引，以方便版本管理
  static readonly SQL_CREATE_UNIQUE_INDEX = `
    CREATE UNIQUE INDEX IF NOT EXISTS idx_level_difficulty_unique ON ${TBL_LEVEL.NAME} (${TBL_LEVEL.COL_DIFFICULTY}, ${TBL_LEVEL.COL_LEVEL})
  `;
}