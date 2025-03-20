package io.iot.dn.wifi.manager

import android.Manifest.permission
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.iot.dn.ble.log.BleLogger
import io.iot.dn.wifi.model.WifiInfo
import android.net.wifi.WifiManager as AndroidWifiManager

/**
 * Implementation of IWifiManager interface that provides WiFi functionality
 * using Android's WifiManager APIs
 */
class WifiManager(private val context: Context) : IWifiManager {

    private val wifiManager: AndroidWifiManager =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as AndroidWifiManager

    /**
     * Checks if the app has required WiFi permissions
     *
     * @return true if all required permissions are granted, false otherwise
     */
    override fun checkWifiPermissions(): Boolean {
        // Check basic WiFi permission
        val hasAccessWifiState = ActivityCompat.checkSelfPermission(
            context, permission.ACCESS_WIFI_STATE
        ) == PackageManager.PERMISSION_GRANTED

        val hasSpecialPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ActivityCompat.checkSelfPermission(
                context, permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }

        val result = hasAccessWifiState && hasSpecialPermission

        BleLogger.d(TAG, "WiFi permission check result: $result")
        return result
    }

    /**
     * Gets information about the currently connected WiFi network
     *
     * @return WifiInfo object containing details about the connected network,
     *         or null if not connected or missing permissions
     */
    override fun getCurrentWifiInfo(): WifiInfo? {
        try {
            if (!checkWifiPermissions()) {
                BleLogger.e(TAG, "Failed to get WiFi info: Missing required permissions")
                return null
            }

            if (!wifiManager.isWifiEnabled) {
                BleLogger.e(TAG, "WiFi is not enabled")
                return null
            }

            // Get WiFi information
            val info = wifiManager.connectionInfo

            if (info == null || info.networkId == -1) {
                BleLogger.e(TAG, "Not connected to any WiFi network")
                return null
            }

            // Get basic WiFi information
            val wifiInfo = WifiInfo(
                ssid = info.ssid.replace("\"", ""),
                bssid = info.bssid ?: "",
                linkSpeed = info.linkSpeed,
                networkId = info.networkId,
                frequency = info.frequency,
                band = getFrequencyBand(info.frequency)
            )

            BleLogger.d(TAG, "Successfully got WiFi info: ${wifiInfo.ssid}")
            return wifiInfo

        } catch (e: Exception) {
            BleLogger.e(TAG, "Error occurred while getting WiFi info: ${e.message}")
            return null
        }
    }

    /**
     * Determines the WiFi frequency band based on the frequency value
     *
     * @param frequency WiFi frequency in MHz
     * @return String describing the frequency band (2.4 GHz, 5 GHz, 6 GHz, or Unknown)
     */
    private fun getFrequencyBand(frequency: Int): String {
        return when (frequency) {
            in 2400..2500 -> "2.4 GHz"
            in 5000..5900 -> "5 GHz"
            in 6000..7000 -> "6 GHz" // WiFi 6E
            else -> "Unknown band ($frequency MHz)"
        }
    }

    /**
     * Checks if the given frequency corresponds to 2.4 GHz WiFi band
     *
     * @param frequency WiFi frequency in MHz
     * @return true if frequency is in 2.4 GHz band, false otherwise
     */
    override fun is24GHzWifi(frequency: Int): Boolean {
        return frequency in 2400..2500
    }

    companion object {
        private const val TAG = "WifiManager"
    }
}