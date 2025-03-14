package io.iot.dn.ble.config

/**
 * Configuration class for BLE operations
 *
 * @property scanTimeout Timeout duration for BLE scanning in milliseconds
 * @property connectTimeout Timeout duration for BLE connection in milliseconds
 * @property mtu Maximum Transmission Unit size for BLE communication
 */
data class BleConfig(
    val scanTimeout: Long = DEFAULT_SCAN_TIMEOUT,
    val connectTimeout: Long = DEFAULT_CONNECT_TIMEOUT,
    val awaitTimeout: Long = DEFAULT_AWAIT_TIMEOUT,
    val mtu: Int = DEFAULT_MTU,
) {
    companion object {
        /** Default scan timeout of 10 seconds */
        const val DEFAULT_SCAN_TIMEOUT = 10000L

        /** Default connection timeout of 5 seconds */
        const val DEFAULT_CONNECT_TIMEOUT = 10000L

        const val DEFAULT_AWAIT_TIMEOUT = 10000L

        /** Default MTU size of 255 bytes */
        const val DEFAULT_MTU = 255
    }
}