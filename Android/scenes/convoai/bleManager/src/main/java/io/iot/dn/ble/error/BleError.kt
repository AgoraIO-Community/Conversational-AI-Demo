package io.iot.dn.ble.error

/**
 * Base class for BLE-related errors
 */
sealed class BleError : Exception() {
    /**
     * Error indicating that Bluetooth is not available on the device
     * @property message The error message
     */
    data class BluetoothNotAvailable(override val message: String = "Bluetooth is not available") : BleError()

    /**
     * Error indicating that Bluetooth permission is denied
     * @property message The error message
     */
    data class BluetoothPermissionDenied(override val message: String = "Bluetooth permission denied") : BleError()
}