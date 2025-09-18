// src/main/ets/database/GameRecord.ets

export interface GameRecord {
  id?: number;
  difficulty: string; // "easy", "normal", "hard", "veryhard"
  bestTime: number; // in seconds
}
