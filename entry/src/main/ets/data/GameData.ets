export class GameData {
  private _difficulty: string

  public set difficulty(value: string) {
    this._difficulty = value
  }

  public get difficulty(): string {
    return this._difficulty
  }

  private _level: number

  public set level(value: number) {
    this._level = value
  }

  public get level(): number {
    return this._level
  }

  private _data: string

  public set data(value: string) {
    this._data = value
  }

  public get data(): string {
    return this._data
  }

  private _errorCount: number

  public set errorCount(value: number) {
    this._errorCount = value
  }

  public get errorCount(): number {
    return this._errorCount
  }

  private _hintCount: number

  public set hintCount(value: number) {
    this._hintCount = value
  }

  public get hintCount(): number {
    return this._hintCount
  }



  constructor(difficulty: string, level: number, data: string, errorCount: number, hintCount: number) {
    this._difficulty = difficulty
    this._level = level
    this._data = data
    this._errorCount = errorCount
    this._hintCount = hintCount
  }



}