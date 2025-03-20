package io.iot.dn.ble.callback

import io.iot.dn.ble.model.BleDevice
import io.iot.dn.ble.state.BleScanState

/**
 * Callback interface for BLE scanning operations
 */
interface BleScanCallback {

    /**
     * Called when scan state changes
     * @param state The scan state value corresponding to BleScanState enum ordinal
     * @see io.iot.dn.ble.state.BleScanState
     */
    fun onScanStateChanged(state: BleScanState)

    /**
     * Called when a BLE device is discovered during scanning
     * @param device The discovered BLE device containing device information
     */
    fun onDeviceFound(device: BleDevice)
}