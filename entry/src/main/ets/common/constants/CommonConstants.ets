import CommonConstantsInfo from '../../viewmodel/CommonConstantsInfo';

export class CommonConstants {

  static PADDING: number = 12

  static PADDING_LEFT: number = 5

  static PADDING_RIGHT: number = 5

  static Rank_Padding: number = 2

  static Item_Height: number = 40

  static Item_Height_V2: number = 60

  static Rank_Item_Height: number = 80

  static readonly RDB_NAME = { dbName: 'Sudoku.db' } as CommonConstantsInfo; // db name

  static ColorMode: string = "currentColorMode"

  static PreferenceName: string = "Store"

  static FollowSystem: string = "FollowSystem"

  static UseDarkMode: string = "UseDarkMode"

  static readonly LEVEL_INFO = {
    tableName: 'level',
    columns: [
      'id',
      'difficulty',
      'level',
      'errorCount',
      'hintCount',
      'locked',
      'completed',
      'data',
      'cumulativeTime'
    ]
  } as CommonConstantsInfo

}

