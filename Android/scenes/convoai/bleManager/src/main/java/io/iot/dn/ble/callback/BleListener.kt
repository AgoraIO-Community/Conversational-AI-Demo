package io.iot.dn.ble.callback

import io.iot.dn.ble.model.BleDevice
import io.iot.dn.ble.state.BleConnectionState
import io.iot.dn.ble.state.BleScanState

/**
 * BLE listener interface
 * Combines scan callback and connection callback functionality
 */
interface BleListener : BleScanCallback, BleConnectionCallback {
    override fun onScanStateChanged(state: BleScanState) {}
    override fun onDeviceFound(device: BleDevice) {}
    override fun onConnectionStateChanged(state: BleConnectionState) {}
    override fun onDataReceived(uuid: String, data: ByteArray) {}
    override fun onMessageSent(serviceUuid: String, characteristicUuid: String, success: Boolean, error: String?) {}
}