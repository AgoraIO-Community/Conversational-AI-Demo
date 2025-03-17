package io.iot.dn.ble.manager

import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanFilter
import android.content.Context
import io.iot.dn.ble.callback.BleConnectionCallback
import io.iot.dn.ble.callback.BleListener
import io.iot.dn.ble.callback.BleScanCallback
import io.iot.dn.ble.common.BleUtils
import io.iot.dn.ble.config.BleConfig
import io.iot.dn.ble.connector.BleConnector
import io.iot.dn.ble.connector.IBleConnector
import io.iot.dn.ble.error.BleError
import io.iot.dn.ble.log.BleLogger
import io.iot.dn.ble.model.BleDevice
import io.iot.dn.ble.scanner.BleScanner
import io.iot.dn.ble.scanner.IBleScanner
import io.iot.dn.ble.state.BleConnectionState
import io.iot.dn.ble.state.BleScanState
import java.util.Collections
import java.util.concurrent.atomic.AtomicReference

/**
 * BleManager handles Bluetooth Low Energy operations including:
 * - Device scanning
 * - Connection management
 * - Data transmission
 * - Characteristic notifications
 */
class BleManager(
    private val context: Context,
    private val bleConfig: BleConfig = BleConfig(),
    private var bleScanner: IBleScanner = BleScanner(bleConfig),
    private var bleConnector: IBleConnector = BleConnector(context, bleConfig)
) : IBleManager {
    private val listeners = Collections.synchronizedList(mutableListOf<BleListener>())
    private val currentConnectionState = AtomicReference(BleConnectionState.IDLE)
    private val isDistributing = AtomicReference(false)

    private val bleScanCallback = object : BleScanCallback {
        override fun onScanStateChanged(state: BleScanState) {
            BleLogger.d(TAG, "Scan state changed: $state")
            listeners.forEach { it.onScanStateChanged(state) }
        }

        override fun onDeviceFound(device: BleDevice) {
            // BleLogger.d(TAG, "Device found: ${device.device.address}")
            // Handle scan result
            listeners.forEach { it.onDeviceFound(device) }
        }
    }

    private val connectionCallback = object : BleConnectionCallback {
        override fun onConnectionStateChanged(state: BleConnectionState) {
            BleLogger.d(TAG, "onConnectionStateChanged: $state")
            updateConnectionState(state)
        }

        override fun onDataReceived(uuid: String, data: ByteArray) {
            BleLogger.d(TAG, "onDataReceived: $uuid, ${data.size}")
            listeners.forEach { it.onDataReceived(uuid, data) }
        }

        override fun onMessageSent(serviceUuid: String, characteristicUuid: String, success: Boolean, error: String?) {
            BleLogger.d(TAG, "onMessageSent: $serviceUuid, $characteristicUuid, $success, $error")
            listeners.forEach { it.onMessageSent(serviceUuid, characteristicUuid, success, error) }
        }
    }

    override fun startScan(filters: List<ScanFilter>?) {
        BleLogger.d(TAG, "Starting BLE scan")
        checkBluetoothAvailable()
        checkBluetoothPermission()
        bleScanner.setScanCallback(bleScanCallback)
        bleScanner.startScan(context, filters)
        BleLogger.i(TAG, "Scan started successfully")
    }

    override fun stopScan() {
        BleLogger.d(TAG, "Stopping BLE scan")
        checkBluetoothAvailable()
        checkBluetoothPermission()
        bleScanner.stopScan()
        bleScanner.setScanCallback(null)  // Remove callback
        BleLogger.i(TAG, "Scan stopped successfully")
    }

    private fun checkBluetoothAvailable() {
        if (!BleUtils.isBleAvailable(context)) {
            BleLogger.e(TAG, "Bluetooth not available")
            throw BleError.BluetoothNotAvailable()
        }
    }

    private fun checkBluetoothPermission() {
        if (!BleUtils.checkBlePermissions(context)) {
            BleLogger.e(TAG, "Bluetooth permissions denied")
            throw BleError.BluetoothPermissionDenied()
        }
    }

    override fun connect(device: BluetoothDevice): Boolean {
        BleLogger.d(TAG, "Connecting to device: ${device.address}")
        checkBluetoothPermission()
        bleConnector.setConnectionCallback(connectionCallback)
        val result = bleConnector.connect(device)
        return result
    }

    override fun disconnect() {
        BleLogger.d(TAG, "Disconnecting BLE connection")
        checkBluetoothPermission()
        bleConnector.disconnect()
        bleConnector.setConnectionCallback(null)
    }

    override fun send(serviceUuid: String, characteristicUuid: String, data: ByteArray): Boolean {
        BleLogger.d(
            TAG, "Sending data to characteristic: $characteristicUuid, service: $serviceUuid, data length: ${data.size}"
        )
        checkBluetoothPermission()
        return bleConnector.send(serviceUuid, characteristicUuid, data)
    }

    override fun sendSSID(ssid: String): Boolean {
        BleLogger.d(TAG, "sendSSID => $ssid")
        checkBluetoothPermission()
        return bleConnector.sendSSID(ssid)
    }

    override fun sendPassword(pwd: String): Boolean {
        BleLogger.d(TAG, "sendPassword => $pwd")
        checkBluetoothPermission()
        return bleConnector.sendPassword(pwd)
    }

    override fun sendToken(token: String): Boolean {
        BleLogger.d(TAG, "sendToken => $token")
        checkBluetoothPermission()
        return bleConnector.sendToken(token)
    }

    override fun sendUrl(url: String): Boolean {
        BleLogger.d(TAG, "sendUrl => $url")
        checkBluetoothPermission()
        return bleConnector.sendUrl(url)
    }

    override fun startStation(): Boolean {
        checkBluetoothPermission()
        return bleConnector.startStation()
    }

    override fun getDeviceId(): String {
        checkBluetoothPermission()
        return bleConnector.getDeviceId()
    }

    override fun distributionNetwork(device: BluetoothDevice, ssid: String, pwd: String, token: String, url: String): Boolean {
        // Check if network distribution is already in progress
        if (isDistributing.get()) {
            BleLogger.w(TAG, "Network distribution already in progress, please wait for current process to complete")
            return false
        }

        checkBluetoothPermission()

        // Mark network distribution as started
        isDistributing.set(true)

        var startStationResult = false
        try {
            val sendSsidResult = sendSSID(ssid)
            if (!sendSsidResult) {
                BleLogger.e(TAG, "distributionNetwork sendSSID failed")
                return false
            }

            if (pwd.isNotEmpty()) {
                val sendPasswordResult = sendPassword(pwd)
                if (!sendPasswordResult) {
                    BleLogger.e(TAG, "distributionNetwork sendPassword failed")
                    return false
                }
            }

            val sendUrlResult = sendUrl(url)
            if (!sendUrlResult) {
                BleLogger.e(TAG, "distributionNetwork sendUrl failed")
                return false
            }

            val sendTokenResult = sendToken(token)
            if (!sendTokenResult) {
                BleLogger.e(TAG, "distributionNetwork sendToken failed")
                return false
            }

            startStationResult = startStation()
        } catch (e: Exception) {
            BleLogger.e(TAG, "Exception occurred during network distribution: ${e.message}")
        } finally {
            isDistributing.set(false)
        }

        // Return true indicates network distribution request was accepted
        return startStationResult
    }

    override fun addListener(listener: BleListener) {
        if (!listeners.contains(listener)) {
            listeners.add(listener)
        }
    }

    override fun removeListener(listener: BleListener) {
        listeners.remove(listener)
    }

    fun updateConnectionState(newState: BleConnectionState) {
        val oldState = currentConnectionState.getAndSet(newState)
        if (oldState != newState) {
            listeners.forEach { it.onConnectionStateChanged(newState) }
        }
    }

    companion object {
        private const val TAG = "BleManager"
    }
}