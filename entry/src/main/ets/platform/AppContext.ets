/** 应用级系统上下文。所有需要文件、Preferences 的能力都从这里取上下文。 */
import common from '@ohos.app.ability.common'

export class AppContext {
  private static current: common.UIAbilityContext | null = null

  static set(context: common.UIAbilityContext): void {
    AppContext.current = context
  }

  static get(): common.UIAbilityContext | null {
    return AppContext.current
  }
}
