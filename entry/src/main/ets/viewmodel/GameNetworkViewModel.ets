import { ApiConstants } from '../constants/ApiConstants';
import { apiService, JuheSudokuResult } from '../data/ApiService';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { ToastUtil } from '../utils/ToastUtil';

// 使用 @Observed 来创建可观察对象
@Observed
export class GameNetworkViewModel {
  // 当这个属性变化时，会通知绑定的UI刷新
  public juhePuzzle: JuheSudokuResult | null = null;
  public isLoading: boolean = false;
  public selectedDifficulty: string = "";
  public remainingApiCall: number = ApiConstants.JUHE_API_DAILY_LIMIT;

  // 难度
  private readonly difficultyLevels: string[] = ["easy", "normal", "hard", "veryhard"];

  constructor() {
    // ViewModel 初始化时，加载一次剩余次数
    this.loadRemainingApiCall();
  }

  public async loadRemainingApiCall() {
    const today = new Date().toISOString().slice(0, 10);
    const lastCallDate = await PreferencesUtil.getString(ApiConstants.API_CALL_DATE_KEY);
    let usedCount = 0;

    if (lastCallDate === today) {
      usedCount = await PreferencesUtil.getNumber(ApiConstants.API_CALL_COUNT_KEY);
    }

    this.remainingApiCall = Math.max(0, ApiConstants.JUHE_API_DAILY_LIMIT - usedCount);
  }

  // 方法：用于获取在线数独
  async fetchOnlineSudoku() {
    this.isLoading = true;
    this.juhePuzzle = null; // 请求开始前，先清空旧数据
    this.selectedDifficulty = "";

    const randomIndex = Math.floor(Math.random() * this.difficultyLevels.length);
    const randomDifficulty = this.difficultyLevels[randomIndex];
    this.selectedDifficulty = randomDifficulty;


    try {
      // 调用ApiService来获取数据
      const puzzleData = await apiService.getSudokuFromJuhe(this.selectedDifficulty);
      this.juhePuzzle = puzzleData; // 将获取到的数据保存在ViewModel中
      ToastUtil.showToast("在线数独已生成！");
    } catch (error) {
      // 这里的error.message会是 "次数已用完" 或 "HTTP Error: 500" 等具体信息
      ToastUtil.showLong(`获取失败: ${(error as Error).message}`);
    } finally {
      this.isLoading = false;
      await this.loadRemainingApiCall();
    }
  }
}