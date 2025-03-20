package io.iot.dn.ble.state

/**
 * Bluetooth scan state enum
 */
enum class BleScanState {
    /**
     * Idle state, scan not started
     */
    IDLE,

    /**
     * Currently scanning
     */
    SCANNING,

    /**
     * Scan stopped
     */
    STOPPED,

    /**
     * Scan timeout
     */
    TIMEOUT,

    /**
     * Scan failed
     */
    FAILED,

    /**
     * Device found
     */
    FOUND
}