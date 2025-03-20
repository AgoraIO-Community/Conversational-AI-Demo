package io.iot.dn.wifi.model

/**
 * WiFi information data model
 */
data class WifiInfo(
    val ssid: String = "",
    val bssid: String = "",
    val linkSpeed: Int = 0,
    val networkId: Int = 0,
    val frequency: Int = 0,
    val band: String = "",
) {
    /**
     * Convert WiFi information to formatted string for display
     */
    override fun toString(): String {
        return "SSID: $ssid\nBSSID: $bssid\nLink Speed: $linkSpeed\nNetwork ID: $networkId\nFrequency: $frequency\nBand: $band"
    }
}