import { apiService, JuheSudokuResult } from '../data/ApiService';
import { ToastUtil } from '../utils/ToastUtil';

// 使用 @Observed 来创建可观察对象
// 在新版本的 SDK 中，这比 ObservableObject + @Published 更推荐
@Observed
export class GameNetworkViewModel {
  // 当这个属性变化时，会通知绑定的UI刷新
  public juhePuzzle: JuheSudokuResult | null = null;
  public isLoading: boolean = false;
  public selectedDifficulty: string = "";

  // 难度
  private readonly difficultyLevels: string[] = ["easy", "normal", "hard", "veryhard"];

  // 方法：用于获取在线数独
  async fetchOnlineSudoku(level: number) {
    this.isLoading = true;
    this.juhePuzzle = null; // 请求开始前，先清空旧数据
    this.selectedDifficulty = "";

    const randomIndex = Math.floor(Math.random() * this.difficultyLevels.length);
    const randomDifficulty = this.difficultyLevels[randomIndex];
    this.selectedDifficulty = randomDifficulty;

    try {
      // 调用ApiService来获取数据
      const puzzleData = await apiService.getSudokuFromJuhe(level, this.selectedDifficulty);
      this.juhePuzzle = puzzleData; // 将获取到的数据保存在ViewModel中
      ToastUtil.showToast("在线数独已生成！");
    } catch (error) {
      // 这里的error.message会是 "次数已用完" 或 "HTTP Error: 500" 等具体信息
      ToastUtil.showLong(`获取失败: ${(error as Error).message}`);
    } finally {
      this.isLoading = false;
    }
  }
}