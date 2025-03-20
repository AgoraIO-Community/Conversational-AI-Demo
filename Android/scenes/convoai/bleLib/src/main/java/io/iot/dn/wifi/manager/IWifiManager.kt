package io.iot.dn.wifi.manager

import io.iot.dn.wifi.model.WifiInfo

/**
 * WiFi Manager Interface
 * Defines standard interface for WiFi related operations
 */
interface IWifiManager {
    /**
     * Check WiFi related permissions
     * @return true if all required permissions are granted, false otherwise
     */
    fun checkWifiPermissions(): Boolean

    /**
     * Get current connected WiFi information
     * @return WifiInfo object containing WiFi information, null if not connected or no permission
     */
    fun getCurrentWifiInfo(): WifiInfo?

    /**
     * Check if current connected WiFi is 2.4GHz
     * @param frequency WiFi frequency in MHz
     * @return true if connected to 2.4GHz WiFi, false if connected to 5GHz or not connected
     */
    fun is24GHzWifi(frequency: Int): Boolean
}