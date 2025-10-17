import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothHelper {
  static const MethodChannel _channel = MethodChannel('my.bluetooth.channel');
  static String? _connectedAddress;

  /// Request Android 12+ Bluetooth permissions
  static Future<bool> requestPermissions() async {
    final connect = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request();
    return connect.isGranted && scan.isGranted;
  }

  /// ✅ Get paired printers
  static Future<List<Map<String, dynamic>>> getPairedPrinters() async {
    final granted = await requestPermissions();
    if (!granted) return [];

    try {
      final result = await _channel.invokeMethod('getPairedPrinters');

      if (result is List) {
        // Convert each element to a properly typed Map<String, dynamic>
        return result
            .map((e) => Map<String, dynamic>.from(
                (e as Map).map((k, v) => MapEntry(k.toString(), v))))
            .toList();
      }

      return [];
    } catch (e) {
      print("Error getting paired printers: $e");
      return [];
    }
  }

  /// Connect to printer
  static Future<bool> connectPrinter(String address) async {
    final granted = await requestPermissions();
    if (!granted) return false;

    try {
      final success =
          await _channel.invokeMethod('connectPrinter', {"address": address});
      if (success == true) _connectedAddress = address;
      return success == true;
    } catch (e) {
      print("Connection failed: $e");
      return false;
    }
  }

  /// Print text
  static Future<bool> printText(String text) async {
    try {
      final success = await _channel.invokeMethod('printText', {"text": text});
      return success == true;
    } catch (e) {
      print("Print failed: $e");
      return false;
    }
  }

  /// Disconnect
  static Future<void> disconnectPrinter() async {
    try {
      await _channel.invokeMethod('disconnectPrinter');
      _connectedAddress = null;
    } catch (e) {
      print("Error disconnecting: $e");
    }
  }

  /// Smart print logic
  static Future<bool> smartPrint(String text, {String? address}) async {
    if (_connectedAddress != null) {
      return await printText(text);
    }
    if (address != null) {
      final connected = await connectPrinter(address);
      if (!connected) return false;
      final printed = await printText(text);
      await disconnectPrinter();
      return printed;
    }
    return false;
  }

  static bool get isConnected => _connectedAddress != null;
  static String? get connectedAddress => _connectedAddress;
}
