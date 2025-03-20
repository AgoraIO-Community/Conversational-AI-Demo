package io.iot.dn.ble.callback

import io.iot.dn.ble.state.BleConnectionState

/**
 * BLE listener interface
 * Used to monitor BLE device connection state and data interactions
 */
interface BleConnectionCallback {

    /**
     * Connection state changed callback
     * @param state Connection state
     */
    fun onConnectionStateChanged(state: BleConnectionState)

    /**
     * Data received callback
     * @param uuid UUID of the characteristic
     * @param data Received data
     */
    fun onDataReceived(uuid: String, data: ByteArray)

    /**
     * Message sent status callback
     * @param serviceUuid UUID of the service
     * @param characteristicUuid UUID of the characteristic
     * @param success Whether sending was successful
     * @param error Error message, null if sending succeeded
     */
    fun onMessageSent(serviceUuid: String, characteristicUuid: String, success: Boolean, error: String? = null)
}