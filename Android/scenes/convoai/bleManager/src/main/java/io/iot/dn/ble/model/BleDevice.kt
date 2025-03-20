package io.iot.dn.ble.model

import android.bluetooth.BluetoothDevice
import android.bluetooth.le.ScanRecord

/**
 * Represents a Bluetooth Low Energy device discovered during scanning
 *
 * @property device The underlying Android BluetoothDevice object
 * @property scanRecord The scan record containing advertised data, may be null
 * @property rssi The received signal strength indicator in dBm
 * @property name The device name, either from scan record or device
 * @property address The MAC address of the device
 */
data class BleDevice(
    val device: BluetoothDevice,
    val scanRecord: ScanRecord? = null,
    val rssi: Int,
    val name: String,
    val address: String,
)
