// src/main/ets/common/constants/GlobalContext.ets

import type common from '@ohos.app.ability.common';

export class GlobalContext {
  private static context: common.UIAbilityContext | null = null;

  public static setContext(context: common.UIAbilityContext): void {
    // 错误: this.context = context;
    // 正确: 使用类名 GlobalContext 访问静态属性
    GlobalContext.context = context;
  }

  public static getContext(): common.UIAbilityContext {
    // 同样需要修改这里
    if (GlobalContext.context === null) {
      throw new Error("GlobalContext not initialized. Call setContext in EntryAbility.");
    }
    // 错误: return this.context;
    // 正确: 使用类名 GlobalContext 访问静态属性
    return GlobalContext.context;
  }
}