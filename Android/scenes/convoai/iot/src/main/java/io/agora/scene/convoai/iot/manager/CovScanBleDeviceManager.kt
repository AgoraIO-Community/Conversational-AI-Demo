package io.agora.scene.convoai.iot.manager

import io.iot.dn.ble.model.BleDevice

/**
 * Bluetooth device manager singleton class
 * Used to store and manage scanned Bluetooth devices
 */
object CovScanBleDeviceManager {
    // Store all scanned devices, key is device address, value is BleDevice object
    private val deviceMap = mutableMapOf<String, BleDevice>()
    
    /**
     * Add device to manager
     * @param device Bluetooth device
     */
    fun addDevice(device: BleDevice) {
        deviceMap[device.address] = device
    }
    
    /**
     * Get device by address
     * @param address Device address
     * @return Corresponding BleDevice object, returns null if not exists
     */
    fun getDevice(address: String): BleDevice? {
        return deviceMap[address]
    }
    
    /**
     * Get all devices
     * @return List of all stored devices
     */
    fun getAllDevices(): List<BleDevice> {
        return deviceMap.values.toList()
    }
    
    /**
     * Clear device list
     */
    fun clearDevices() {
        deviceMap.clear()
    }
    
    /**
     * Remove specified device
     * @param address Device address
     */
    fun removeDevice(address: String) {
        deviceMap.remove(address)
    }
} 