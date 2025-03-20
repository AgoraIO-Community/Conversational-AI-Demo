package io.iot.dn.ble.scanner

import android.bluetooth.le.ScanFilter
import android.content.Context
import androidx.annotation.RequiresPermission
import io.iot.dn.ble.callback.BleScanCallback

/**
 * Scanner interface for Bluetooth Low Energy devices.
 *
 * Defines the contract for BLE scanning operations.
 */
interface IBleScanner {
    /**
     * Sets the callback to receive scan results and state changes.
     *
     * @param callback The callback implementation to receive scan events. Pass null to remove callback.
     */
    fun setScanCallback(callback: BleScanCallback?)

    /**
     * Starts scanning for BLE devices.
     *
     * @param context The application context
     * @param filters Optional list of scan filters to apply. Pass null for no filtering.
     * @throws SecurityException if BLUETOOTH_SCAN permission is not granted
     */
    @RequiresPermission(android.Manifest.permission.BLUETOOTH_SCAN)
    fun startScan(context: Context, filters: List<ScanFilter>?)

    /**
     * Stops the ongoing BLE scan.
     *
     * @throws SecurityException if BLUETOOTH_SCAN permission is not granted
     */
    @RequiresPermission(android.Manifest.permission.BLUETOOTH_SCAN)
    fun stopScan()
}