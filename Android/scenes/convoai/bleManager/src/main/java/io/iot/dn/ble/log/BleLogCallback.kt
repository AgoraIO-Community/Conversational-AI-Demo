package io.iot.dn.ble.log

/**
 * Callback interface for receiving BLE log events.
 */
interface BleLogCallback {
    /**
     * Called when a log event occurs.
     * @param level The severity level of the log
     * @param tag The tag identifying the source of the log
     * @param message The log message content
     */
    fun onLog(level: BleLogLevel, tag: String, message: String)
}

/**
 * Enum defining the available log severity levels.
 */
enum class BleLogLevel {
    /** Debug level for detailed information */
    DEBUG,
    /** Info level for general information */
    INFO,
    /** Warning level for potential issues */
    WARN,
    /** Error level for serious problems */
    ERROR
}