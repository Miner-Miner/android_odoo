import 'package:permission_handler/permission_handler.dart';

Future<bool> requestBluetoothPermissions() async {
  final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
  final bluetoothScanStatus = await Permission.bluetoothScan.status;

  if (!bluetoothConnectStatus.isGranted) {
    await Permission.bluetoothConnect.request();
  }

  if (!bluetoothScanStatus.isGranted) {
    await Permission.bluetoothScan.request();
  }

  return await Permission.bluetoothConnect.isGranted &&
         await Permission.bluetoothScan.isGranted;
}
