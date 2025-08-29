// 文件: src/main/ets/data/bluetooth/BluetoothManager.ets

import { BleScanManager } from './Scan'; // 导入扫描器
import { BleAdvertisingManager } from './Broadcast'; // 导入广播器
import { LogUtil } from '../../utils/LogUtil';


export class BluetoothManager {
  static startScanning() {
    throw new Error('Method not implemented.');
  }
  // 仍然是单例模式
  private static instance: BluetoothManager | null = null;

  // 持有扫描器和广播器的实例
  private scanner: BleScanManager;
  private broadcaster: BleAdvertisingManager;

  private constructor() {
    // 在构造时创建实例
    this.scanner = new BleScanManager();
    this.broadcaster = new BleAdvertisingManager();

    LogUtil.info("BluetoothManager initialized with Scanner and Broadcaster.");
  }

  public static getInstance(): BluetoothManager {
    if (!BluetoothManager.instance) {
      BluetoothManager.instance = new BluetoothManager();
    }
    return BluetoothManager.instance;
  }

  // ============== 提供统一的、简化的 API ==============

  public startScanning(): void {
    // 总指挥命令扫描小队开始工作

    this.scanner.startScan();
    if (this.scanner) {
      LogUtil.warn("Already scanning.");
      return;
    }
  }

  public stopScanning(): void {
    this.scanner.stopScan();
  }

  public startBroadcasting(): void {
    // 总指挥命令广播小队开始工作
    this.broadcaster.startAdvertising();
  }

  public stopBroadcasting(): void {
    this.broadcaster.stopAdvertising();
  }

  // TODO: 从 Scanner 和 Broadcaster 处接收事件，并转发给 ViewModel
}