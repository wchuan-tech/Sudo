import { LogUtil } from "../utils/LogUtil"

export class LevelInfo {

  id: number

  difficulty: string

  level: number

  errorCount: number

  hintCount: number

  locked: boolean

  completed: boolean

  data: string

  cumulativeTime: number

  constructor(id: number, difficulty: string, level: number, errorCount: number, hintCount: number, locked: boolean,
    completed: boolean, data: string, cumulativeTime: number) {
    this.id = id
    this.difficulty = difficulty
    this.level = level
    this.errorCount = errorCount
    this.hintCount = hintCount
    this.locked = locked
    this.completed = completed
    this.data = data
    this.cumulativeTime = cumulativeTime
  }


  toString(): string {
    return `id = ${this.id}, difficulty = ${this.difficulty}, level = ${this.level},
    errorCount = ${this.errorCount}, hintCount = ${this.hintCount},
     locked = ${this.locked}, completed = ${this.completed},
     cumulativeTime = ${this.cumulativeTime}, data = ${this.data} `
  }

}