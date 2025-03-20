package io.iot.dn.ble.common

import android.Manifest
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * Utility class for Bluetooth Low Energy operations
 */
object BleUtils {
    /**
     * Check if BLE is available and ready to use
     * @param context Android context
     * @return true if BLE is available and all requirements are met
     */
    fun isBleAvailable(context: Context): Boolean {
        return checkBleSupport(context) &&
                checkBleEnabled(context) &&
                checkLocationEnabled(context) &&
                checkBlePermissions(context)
    }

    /**
     * Check if device supports BLE
     * @param context Android context
     * @return true if BLE is supported
     */
    private fun checkBleSupport(context: Context): Boolean {
        return context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
    }

    /**
     * Check if Bluetooth is enabled
     * @param context Android context
     * @return true if Bluetooth is enabled
     */
    private fun checkBleEnabled(context: Context): Boolean {
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        return bluetoothManager.adapter?.isEnabled == true
    }

    /**
     * Check if Location services are enabled
     * @param context Android context
     * @return true if location services are enabled
     */
    private fun checkLocationEnabled(context: Context): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    /**
     * Check if required BLE permissions are granted
     * @param context Android context
     * @return true if all required permissions are granted
     */
    fun checkBlePermissions(context: Context): Boolean {
        val hasScanPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_SCAN
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH
            ) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.BLUETOOTH_ADMIN
                    ) == PackageManager.PERMISSION_GRANTED
        }

        val hasConnectPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH
            ) == PackageManager.PERMISSION_GRANTED
        }

        return hasScanPermission && hasConnectPermission
    }
}