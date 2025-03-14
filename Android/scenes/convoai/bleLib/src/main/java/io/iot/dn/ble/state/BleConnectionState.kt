package io.iot.dn.ble.state

/**
 * Bluetooth connection state enum
 */
enum class BleConnectionState {
    /**
     * Idle state, not connected or connecting
     */
    IDLE,

    /**
     * Successfully connected to device
     */
    CONNECTED,

    /**
     * Currently connecting to device
     */
    CONNECTING,

    /**
     * Disconnected from device
     */
    DISCONNECTED,
}