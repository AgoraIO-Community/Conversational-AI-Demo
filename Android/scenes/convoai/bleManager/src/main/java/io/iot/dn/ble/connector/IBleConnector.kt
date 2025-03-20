package io.iot.dn.ble.connector

import android.Manifest
import android.bluetooth.BluetoothDevice
import androidx.annotation.RequiresPermission
import androidx.annotation.WorkerThread
import io.iot.dn.ble.callback.BleConnectionCallback
import io.iot.dn.ble.callback.BleListener

/**
 * Interface for BLE device connection and communication.
 * Provides methods to connect, send data and manage BLE connections.
 */
interface IBleConnector {
    /**
     * Connect to a BLE device
     * @param device The Bluetooth device to connect to
     * @return true if connection request was initiated successfully, false otherwise
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun connect(device: BluetoothDevice): Boolean

    /**
     * Disconnect from currently connected BLE device
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun disconnect()

    /**
     * Send data to a specific characteristic
     * @param serviceUuid UUID of the service
     * @param characteristicUuid UUID of the characteristic
     * @param data Data bytes to send
     * @return true if data was sent successfully, false otherwise
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun send(serviceUuid: String, characteristicUuid: String, data: ByteArray): Boolean

    /**
     * Send SSID to connected device
     * @param ssid Network SSID to send
     * @return true if SSID was sent successfully, false otherwise
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun sendSSID(ssid: String): Boolean

    /**
     * Send password to connected device
     * @param pwd Network password to send
     * @return true if password was sent successfully, false otherwise
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun sendPassword(pwd: String): Boolean

    /**
     * Send token to connected device
     * @param token Authentication token to send
     * @return true if token was sent successfully, false otherwise
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun sendToken(token: String): Boolean

    /** 
     * Send URL to connected device
     * @param url The URL to send
     * @return true if URL was sent successfully, false otherwise
     */
    @WorkerThread
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun sendUrl(url: String): Boolean

    /**
     * Start the station mode on connected device
     * @return true if station was started successfully, false otherwise
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
     * Set callback for connection state and data events
     * @param callback The callback implementation, or null to remove callback
     */
    fun setConnectionCallback(callback: BleConnectionCallback?)
}