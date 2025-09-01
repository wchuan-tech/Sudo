// BluetoothViewModel.ts
import { ble } from '@kit.ConnectivityKit';
import bluetooth from '@ohos.bluetooth';
import { access } from '@kit.ConnectivityKit';

import { promptAction } from '@kit.ArkUI';
import { LogUtil } from '../utils/LogUtil';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';


let manufactureValueBuffer = new Uint8Array(4);
manufactureValueBuffer[0] = 1;
manufactureValueBuffer[1] = 2;
manufactureValueBuffer[2] = 3;
manufactureValueBuffer[3] = 4;

let serviceValueBuffer = new Uint8Array(4);
serviceValueBuffer[0] = 4;
serviceValueBuffer[1] = 6;
serviceValueBuffer[2] = 7;
serviceValueBuffer[3] = 8;
console.info('manufactureValueBuffer = '+ JSON.stringify(manufactureValueBuffer));
console.info('serviceValueBuffer = '+ JSON.stringify(serviceValueBuffer));


function onReceiveEvent(data: Array<ble.ScanResult>) {
  console.info('BLE scan device find result = '+ JSON.stringify(data));
}



@Observed
export class BluetoothViewModel {
  // 扫描的相关属性
  public isScanning: boolean = false;
  public foundDevices: ble.ScanResult[] = [];
  private scannedDeviceIds: Set<string> = new Set(); // 用于设备去重


  // 开始扫描流程
  async startScan() {
    if (this.isScanning) {
      LogUtil.debug("BluetoothViewModel: Already scanning.");
      return;
    }

    // 1. 检查蓝牙是否开启
    if (bluetooth.getState() !== bluetooth.BluetoothState.STATE_ON) {
      try {
        const dialogResult = await promptAction.showDialog({
          title: "蓝牙未开启",
          message: "蓝牙对战功能需要您开启蓝牙。",
          buttons: [{ text: '取消', color: '#666666' }, // 为“取消”按钮指定一个颜色，例如灰色
            { text: '去开启', color: '#007DFF' } ] // 为“去开启”按钮指定一个颜色，例如蓝色]
        });



        if (dialogResult.index === 1) { // 用户点击了 "去开启"

          try {
            let setting: ble.AdvertiseSetting = {
              interval:150,
              txPower:0,
              connectable:true
            };
            let manufactureDataUnit: ble.ManufactureData = {
              manufactureId:4567,
              manufactureValue:manufactureValueBuffer.buffer
            };
            let serviceDataUnit: ble.ServiceData = {
              serviceUuid:"00001888-0000-1000-8000-00805f9b34fb",
              serviceValue:serviceValueBuffer.buffer
            };
            let advData: ble.AdvertiseData = {
              serviceUuids:["00001888-0000-1000-8000-00805f9b34fb"],
              manufactureData:[manufactureDataUnit],
              serviceData:[serviceDataUnit]
            };
            let advResponse: ble.AdvertiseData = {
              serviceUuids:["00001888-0000-1000-8000-00805f9b34fb"],
              manufactureData:[manufactureDataUnit],
              serviceData:[serviceDataUnit]
            };
            ble.startAdvertising(setting, advData ,advResponse);
          } catch (err) {
            console.debug("BluetoothViewModel: startAdvertising failed.");
            console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
          }


          try {
            access.enableBluetooth();
          } catch (err) {
            console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
          }

          LogUtil.debug("BluetoothViewModel: User chose to enable Bluetooth.");


          // 监听蓝牙状态变化，以便在开启成功后自动开始扫描
          bluetooth.on('stateChange', (state) => {
            if (state === bluetooth.BluetoothState.STATE_ON) {
              LogUtil.debug("BluetoothViewModel: Bluetooth has been enabled successfully.");
              // 蓝牙开启成功，自动开始扫描
              this.doActualScan();
              // 成功扫描后，移除监听器，避免重复触发
              bluetooth.off('stateChange');
            }
          });
        // 引导用户去系统设置开启
      }

      }catch (e) {
        LogUtil.error("BluetoothViewModel: User cancelled enabling bluetooth.");
      }
      return;
    }

    LogUtil.debug("BluetoothViewModel: Starting BLE scan...");
    this.isScanning = true;
    this.foundDevices = []; // 清空上次的扫描结果
    this.scannedDeviceIds.clear();

    try {
      // 2. 开始扫描
      // ble.startBLEScan(
      // );

      // 3. 监听扫描结果
      ble.on('BLEDeviceFind', (results: ble.ScanResult[]) => {
        LogUtil.debug(`BluetoothViewModel: Found ${results.length} devices.`);
        results.forEach(device => {
          // 简单的去重逻辑
          if (device.deviceName && !this.scannedDeviceIds.has(device.deviceId)) {
            this.foundDevices.push(device);
            this.scannedDeviceIds.add(device.deviceId);
          }
        });
      });

    } catch (error) {
      const err = error as BusinessError;
      LogUtil.error(`BluetoothViewModel: startBLEScan failed, code: ${err.code}, message: ${err.message}`);
      promptAction.showToast({ message: `扫描失败: ${err.message}` });
      this.isScanning = false;
    }

    // (可选) 设置一个超时来自动停止扫描
    setTimeout(() => {
      this.stopScan();
    }, 15000); // 扫描15秒
  }

  private doActualScan() {
    LogUtil.debug("BluetoothViewModel: Starting actual BLE scan...");
    if (this.isScanning) return; // 再次检查，防止重复扫描

    this.isScanning = true;
    this.foundDevices = [];
    this.scannedDeviceIds.clear();

    try {
      try {
        ble.on("BLEDeviceFind", onReceiveEvent);
        let scanFilter: ble.ScanFilter = {
          deviceId:"XX:XX:XX:XX:XX:XX",
          name:"test",
          serviceUuid:"00001888-0000-1000-8000-00805f9b34fb"
        };
        let scanOptions: ble.ScanOptions = {
          interval: 500,
          dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
          matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
        }
        ble.startBLEScan([scanFilter],scanOptions);
      } catch (err) {
        console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      }


      ble.on('BLEDeviceFind', (results: ble.ScanResult[]) => {
        LogUtil.debug(`BluetoothViewModel: Found ${results.length} devices.`);
        results.forEach(device => {
          if (device.deviceName && !this.scannedDeviceIds.has(device.deviceId)) {
            this.foundDevices.push(device);
            this.scannedDeviceIds.add(device.deviceId);
          }
        });
      });

    } catch (error) {
      const err = error as BusinessError;
      LogUtil.error(`BluetoothViewModel: startBLEScan failed, code: ${err.code}, message: ${err.message}`);
      promptAction.showToast({ message: `扫描失败: ${err.message}` });
      this.isScanning = false;
    }

    setTimeout(() => {
      this.stopScan();
    }, 15000);
  }

  // 停止扫描
  stopScan() {
    if (!this.isScanning) return;
    try {
      ble.off('BLEDeviceFind'); // 停止监听
      ble.stopBLEScan();
      this.isScanning = false;
      LogUtil.debug("BluetoothViewModel: BLE scan stopped.");
    } catch (error) {
      const err = error as BusinessError;
      LogUtil.error(`BluetoothViewModel: stopBLEScan failed, code: ${err.code}, message: ${err.message}`);
    }
  }

  // 连接设备 (功能占位)
  connectToDevice(device: ble.ScanResult) {
    LogUtil.debug(`BluetoothViewModel: Attempting to connect to ${device.deviceName} (${device.deviceId})`);
    this.stopScan(); // 连接前先停止扫描
    promptAction.showToast({ message: `正在尝试连接到 ${device.deviceName}...` });
    // 实际的连接逻辑会在这里：ble.createGattClientDevice, gattClient.connect() 等
  }


}