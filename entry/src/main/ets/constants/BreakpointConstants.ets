export class BreakpointConstants {
  /**
   * Breakpoints that represent small device types.
   */
  static readonly BREAKPOINT_SM: string = 'sm';

  /**
   * Breakpoints that represent middle device types.
   */
  static readonly BREAKPOINT_MD: string = 'md';

  /**
   * Breakpoints that represent large device types.
   */
  static readonly BREAKPOINT_LG: string = 'lg';

  /**
   * dark_mode
   */
  static readonly BREAKPOINT_DARK_MODE: string = 'dark_mode';

  /**
   * Current breakpoints that to query the device types.
   */
  static readonly CURRENT_BREAKPOINT: string = 'currentBreakpoint';


  /**
   * Range of the small device width.
   */
  static readonly RANGE_SM: string = '(320vp<=width<600vp)';

  /**
   * Range of the middle device width.
   */
  static readonly RANGE_MD: string = '(600vp<=width<840vp)';

  /**
   * Range of the large device width.
   */
  static readonly RANGE_LG: string = '(840vp<=width)';

  /**
   * 系统当前的深浅模式。可选值：true、false。
   * 深色模式为true，浅色模式为false。
   * dark-mode
   */
  static readonly DARK_MODE: string = '(dark-mode: true)';
}