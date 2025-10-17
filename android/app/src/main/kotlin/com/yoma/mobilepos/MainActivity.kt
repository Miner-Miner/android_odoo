package com.yoma.mobilepos

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.OutputStream
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "my.bluetooth.channel"
    private var bluetoothSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var connectedDevice: BluetoothDevice? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ✅ 1. Get paired printer devices only
                    "getPairedPrinters" -> {
                        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                        if (bluetoothAdapter == null) {
                            result.error("NO_ADAPTER", "Bluetooth not supported", null)
                        } else {
                            val pairedPrinters = bluetoothAdapter.bondedDevices
                                .filter { device ->
                                    val name = device.name?.lowercase(Locale.getDefault()) ?: ""
                                    // simple heuristic: contains "printer" or known prefixes
                                    name.contains("printer") ||
                                    name.startsWith("bt") ||
                                    name.startsWith("pos") ||
                                    name.startsWith("escpos") ||
                                    name.contains("rpp")
                                    // name.isNotEmpty()   
                                }
                                .map {
                                    mapOf(
                                        "name" to it.name,
                                        "address" to it.address,
                                        "type" to it.type
                                    )
                                }
                            result.success(pairedPrinters)
                        }
                    }

                    // ✅ 2. Connect to a printer
                    "connectPrinter" -> {
                        val address = call.argument<String>("address")
                        if (address == null) {
                            result.error("INVALID", "No address provided", null)
                            return@setMethodCallHandler
                        }

                        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                        if (bluetoothAdapter == null) {
                            result.error("NO_ADAPTER", "Bluetooth not supported", null)
                            return@setMethodCallHandler
                        }

                        val device = bluetoothAdapter.getRemoteDevice(address)
                        try {
                            // Standard SPP UUID for serial devices
                            val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                            bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid)
                            bluetoothSocket!!.connect()
                            outputStream = bluetoothSocket!!.outputStream
                            connectedDevice = device
                            result.success(true)
                        } catch (e: IOException) {
                            e.printStackTrace()
                            result.error("CONNECTION_FAILED", e.message, null)
                        }
                    }

                    // ✅ 3. Print text to connected printer
                    "printText" -> {
                        val text = call.argument<String>("text")
                        if (outputStream == null) {
                            result.error("NO_CONNECTION", "Not connected to printer", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val bytes = text?.toByteArray(Charsets.UTF_8)
                            outputStream!!.write(bytes)
                            outputStream!!.flush()
                            // ESC/POS line feed (new line)
                            outputStream!!.write(byteArrayOf(0x0A))
                            result.success(true)
                        } catch (e: IOException) {
                            e.printStackTrace()
                            result.error("PRINT_FAILED", e.message, null)
                        }
                    }

                    // ✅ 4. Disconnect
                    "disconnectPrinter" -> {
                        try {
                            outputStream?.close()
                            bluetoothSocket?.close()
                            outputStream = null
                            bluetoothSocket = null
                            connectedDevice = null
                            result.success(true)
                        } catch (e: IOException) {
                            e.printStackTrace()
                            result.error("DISCONNECT_FAILED", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
