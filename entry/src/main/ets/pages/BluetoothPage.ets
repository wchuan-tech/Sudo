import { BluetoothViewModel } from '../viewmodel/BluetoothViewModel';
import { ble } from '@kit.ConnectivityKit';

@Builder
export function BluetoothPageBuilder() {
  BluetoothPage()
}

@Entry
@Component
struct BluetoothPage {
  @Consume('navPathStack')
  pathStack: NavPathStack;

  @State private viewModel: BluetoothViewModel = new BluetoothViewModel();

  // 页面出现时，自动开始扫描
  aboutToAppear() {
    this.viewModel.startScan();
  }

  // 页面消失时，自动停止扫描
  aboutToDisappear() {
    this.viewModel.stopScan();
  }

  build() {
    NavDestination() {
      RelativeContainer(){
        Text("1") {
          Span("2")
        }
      Column() {
        // 1. 顶部标题栏
        Row() {
          Image($r('app.media.back')).width(24).height(24)
            .onClick(() => { this.pathStack.pop(); })
          Text(" 蓝牙 ")
            .fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 15 })
          Blank()
          // 扫描状态指示器
          if (this.viewModel.isScanning) {
            Row({ space: 5 }) {
              Progress({ value: 0, total: 100 }).width(16).height(16)
              Text("扫描中...").fontSize(14).fontColor(Color.Gray)
            }
          }
        }
        .width('100%').padding(15).alignItems(VerticalAlign.Center)

        Divider()

        // 2. 设备列表
        if (this.viewModel.foundDevices.length > 0) {
          List({ space: 10 }) {
            ForEach(this.viewModel.foundDevices, (device: ble.ScanResult) => {
              ListItem() {
                Row() {
                  Image($r('app.media.bluetooth')).width(20).height(20) // 蓝牙图标
                  Text(device.deviceName).fontSize(18).margin({ left: 10 })
                  Blank()
                  Text(`信号: ${device.rssi}dBm`).fontSize(12).fontColor(Color.Gray)
                }
                .padding(15)
                .backgroundColor($r('app.color.level_background'))
                .borderRadius(12)
                .onClick(() => {
                  this.viewModel.connectToDevice(device);
                })
              }
            })
          }
          .width('100%').padding(15)
          .layoutWeight(1)
        } else {
          // 列表为空时的占位符
          Column() {
            if (this.viewModel.isScanning) {
              Text("正在努力寻找附近的玩家...").fontColor(Color.Gray)
            } else {
              Text("附近没有发现可对战的玩家").fontColor(Color.Gray)
              Button("重新扫描")
                .margin({ top: 20 })
                .onClick(() => { this.viewModel.startScan(); })
            }
          }
          .justifyContent(FlexAlign.Center)
          .width('100%').height('100%')
          .layoutWeight(1)
        }
      }
      .backgroundColor($r('app.color.view_background'))
    }
  }
}
}