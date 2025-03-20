package io.iot.dn.ble.manager

import android.bluetooth.BluetoothDevice
import androidx.annotation.RequiresPermission
import android.Manifest
import android.bluetooth.le.ScanFilter
import androidx.annotation.WorkerThread

/**
 * Interface defining Bluetooth Low Energy (BLE) manager operations.
 * Provides methods for scanning, connecting, and communicating with BLE devices.
 */
interface IBleManager {
    /**
     * Starts scanning for BLE devices.
     *
     * @param filters Optional list of scan filters to apply. Pass null for no filtering.
     * @throws SecurityException if BLUETOOTH_SCAN permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    fun startScan(filters: List<ScanFilter>?)

    /**
     * Stops the ongoing BLE device scan.
     *
     * @throws SecurityException if BLUETOOTH_SCAN permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    fun stopScan()

    /**
     * Establishes a connection with the specified BLE device.
     *
     * @param device The BluetoothDevice to establish connection with
     * @return true if connection was successfully established, false otherwise
     * @throws SecurityException if BLUETOOTH_CONNECT permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun connect(device: BluetoothDevice): Boolean

    /**
     * Disconnects from the currently connected BLE device.
     *
     * @throws SecurityException if BLUETOOTH_CONNECT permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun disconnect()

    /**
     * Sends data to a specific service and characteristic on the connected BLE device.
     *
     * @param serviceUuid The UUID of the BLE service to write to
     * @param characteristicUuid The UUID of the BLE characteristic to write to
     * @param data The byte array of data to send
     * @return true if data was sent successfully, false otherwise
     * @throws SecurityException if BLUETOOTH_CONNECT permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun send(serviceUuid: String, characteristicUuid: String, data: ByteArray): Boolean

    /**
     * Sends WiFi SSID to the connected BLE device.
     *
     * @param ssid The WiFi network SSID to send
     * @return true if SSID was sent successfully, false otherwise
     * @throws SecurityException if BLUETOOTH_CONNECT permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun sendSSID(ssid: String): Boolean

    /**
     * Sends WiFi password to the connected BLE device.
     *
     * @param pwd The WiFi network password to send
     * @return true if password was sent successfully, false otherwise
     * @throws SecurityException if BLUETOOTH_CONNECT permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun sendPassword(pwd: String): Boolean

    /**
     * Sends authentication token to the connected BLE device.
     *
     * @param token The authentication token to send
     * @return true if token was sent successfully, false otherwise
     * @throws SecurityException if BLUETOOTH_CONNECT permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun sendToken(token: String): Boolean

    /** 
     * Sends URL to the connected BLE device.
     *
     * @param url The URL to send
     * @return true if URL was sent successfully, false otherwise
     * @throws SecurityException if BLUETOOTH_CONNECT permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun sendUrl(url: String): Boolean

    /**
     * Initiates station mode on the connected BLE device.
     *
     * @return true if station mode was started successfully, false otherwise
     * @throws SecurityException if BLUETOOTH_CONNECT permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun startStation(): Boolean

    /**
     * Get the device ID of connected BLE device
     * @return Device ID string
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun getDeviceId(): String

    /**
     * Performs network distribution setup on the connected BLE device.
     * This includes sending WiFi credentials and authentication token.
     *
     * @param device The BluetoothDevice to perform network distribution on
     * @param ssid The WiFi network SSID
     * @param pwd The WiFi network password
     * @param token The authentication token
     * @return true if network distribution was successful, false otherwise
     * @throws SecurityException if BLUETOOTH_CONNECT permission is not granted
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun distributionNetwork(device: BluetoothDevice, ssid: String, pwd: String, token: String, url: String): Boolean

    /**
     * Registers a BLE event listener to receive scan and connection callbacks.
     *
     * @param listener The BleListener implementation to receive BLE events
     */
    fun addListener(listener: io.iot.dn.ble.callback.BleListener)

    /**
     * Unregisters a previously added BLE event listener.
     *
     * @param listener The BleListener implementation to remove
     */
    fun removeListener(listener: io.iot.dn.ble.callback.BleListener)

}