// src/main/ets/common/constants/GlobalContext.ets

import type common from '@ohos.app.ability.common';

export class GlobalContext {
  private static context: common.UIAbilityContext | null = null;

  public static setContext(context: common.UIAbilityContext): void {
    GlobalContext.context = context;
  }

  public static getContext(): common.UIAbilityContext {
    if (GlobalContext.context === null) {
      throw new Error("GlobalContext not initialized. Call setContext in EntryAbility.");
    }
    return GlobalContext.context;
  }
}