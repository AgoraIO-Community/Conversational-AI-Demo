package io.iot.dn.ble.log

/**
 * Logger utility class for Bluetooth Low Energy operations.
 * Provides debug, info, warning and error level logging capabilities.
 */
object BleLogger {
    private var logCallback: BleLogCallback? = null

    /**
     * Initializes the logger with an optional callback.
     * @param callback The callback to receive log events, or null to disable logging
     */
    fun init(callback: BleLogCallback? = null) {
        logCallback = callback
    }

    /**
     * Logs a debug message.
     * @param tag The tag identifying the source of the log
     * @param message The message to log
     */
    fun d(tag: String, message: String) {
        logCallback?.onLog(BleLogLevel.DEBUG, tag, message)
    }

    /**
     * Logs an info message.
     * @param tag The tag identifying the source of the log
     * @param message The message to log
     */
    fun i(tag: String, message: String) {
        logCallback?.onLog(BleLogLevel.INFO, tag, message)
    }

    /**
     * Logs a warning message.
     * @param tag The tag identifying the source of the log
     * @param message The message to log
     */
    fun w(tag: String, message: String) {
        logCallback?.onLog(BleLogLevel.WARN, tag, message)
    }

    /**
     * Logs an error message.
     * @param tag The tag identifying the source of the log
     * @param message The message to log
     */
    fun e(tag: String, message: String) {
        logCallback?.onLog(BleLogLevel.ERROR, tag, message)
    }
}