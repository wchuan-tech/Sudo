/**
 * AppEvent.ts
 * 统一定义应用内的所有广播事件名称
 */
export enum AppEvent {
  // 示例事件：当用户登录状态改变时
  USER_LOGIN_STATE_CHANGED = 'USER_LOGIN_STATE_CHANGED',

  // 示例事件：当主题（如深色/浅色模式）改变时
  THEME_CHANGED = 'THEME_CHANGED',

  // 示例事件：当游戏分数更新时
  SCORE_UPDATED = 'SCORE_UPDATED'
}