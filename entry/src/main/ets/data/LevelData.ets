import { LogUtil } from "../utils/LogUtil"

export class  LevelData {
  public _puzzle: string[][]

  public get puzzle(): string[][] {
    LogUtil.debug("puzzle getter " +this._puzzle)
    return this._puzzle
  }

  _solution: string[][]

  public set solution(value: string[][]) {
    this._solution = value
  }

  public get solution(): string[][] {
    return this._solution
  }

  _levelName: string

  public set levelName(value: string) {
    this._levelName = value
  }

  public get levelName(): string {
    return this._levelName
  }

  _difficulty: string

  public set difficulty(value: string) {
    this._difficulty = value
  }

  public get difficulty(): string {
    return this._difficulty
  }

  constructor(puzzle: string[][], solution: string[][], levelName: string, difficulty: string) {
    this._puzzle = puzzle
    this._solution = solution
    this._levelName = levelName
    this._difficulty = difficulty
    LogUtil.debug("LevelData puzzle : " + this._puzzle)
    LogUtil.debug("LevelData puzzle getter : " + this.puzzle)
  }



}