package io.agora.scene.convoai.iot.manager

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.agora.scene.convoai.iot.CovLogger
import io.agora.scene.convoai.iot.model.CovIotDevice

/**
 * IoT Device Manager responsible for storing and retrieving device information
 */
class CovIotDeviceManager private constructor(context: Context) {
    private val TAG = "CovIotDeviceManager"
    
    // SharedPreferences keys
    private val PREFS_NAME = "iot_devices_prefs"
    private val DEVICES_KEY = "saved_devices"
    
    private val sharedPrefs: SharedPreferences = 
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    
    /**
     * Load device list from local storage
     * @return List of devices, or empty list if none found
     */
    fun loadDevicesFromLocal(): List<CovIotDevice> {
        try {
            val devicesJson = sharedPrefs.getString(DEVICES_KEY, null)
            
            if (!devicesJson.isNullOrEmpty()) {
                val type = object : TypeToken<List<CovIotDevice>>() {}.type
                val loadedDevices = Gson().fromJson<List<CovIotDevice>>(devicesJson, type)
                
                CovLogger.d(TAG, "Loaded ${loadedDevices.size} devices from local storage")
                return loadedDevices
            } else {
                CovLogger.d(TAG, "No saved devices found in local storage")
            }
        } catch (e: Exception) {
            CovLogger.e(TAG, "Failed to load devices: ${e.message}")
            e.printStackTrace()
        }
        return emptyList()
    }
    
    /**
     * Save device list to local storage
     * @param deviceList List of devices to save
     * @return Whether the save operation was successful
     */
    fun saveDevicesToLocal(deviceList: List<CovIotDevice>): Boolean {
        try {
            val devicesJson = Gson().toJson(deviceList)
            sharedPrefs.edit().putString(DEVICES_KEY, devicesJson).apply()
            
            CovLogger.d(TAG, "Saved ${deviceList.size} devices to local storage")
            return true
        } catch (e: Exception) {
            CovLogger.e(TAG, "Failed to save devices: ${e.message}")
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Add a single device and save
     * @param device Device to add
     * @return Whether the operation was successful
     */
    fun addDevice(device: CovIotDevice): Boolean {
        val currentDevices = loadDevicesFromLocal().toMutableList()
        currentDevices.add(0, device) // Add to the beginning of the list
        return saveDevicesToLocal(currentDevices)
    }
    
    /**
     * Remove a single device and save
     * @param deviceId ID of the device to remove
     * @return Whether the operation was successful
     */
    fun removeDevice(deviceId: String): Boolean {
        val currentDevices = loadDevicesFromLocal().toMutableList()
        val initialSize = currentDevices.size
        currentDevices.removeAll { it.id == deviceId }
        
        if (currentDevices.size < initialSize) {
            return saveDevicesToLocal(currentDevices)
        }
        return false
    }
    
    /**
     * Update device information and save
     * @param device Updated device information
     * @return Whether the operation was successful
     */
    fun updateDevice(device: CovIotDevice): Boolean {
        val currentDevices = loadDevicesFromLocal().toMutableList()
        val index = currentDevices.indexOfFirst { it.id == device.id }
        
        if (index != -1) {
            currentDevices[index] = device
            return saveDevicesToLocal(currentDevices)
        }
        return false
    }
    
    /**
     * Get total device count
     * @return Number of devices
     */
    fun getDeviceCount(): Int {
        return loadDevicesFromLocal().size
    }

    /**
     * Get a specific device by ID
     * @param deviceId ID of the device to retrieve
     * @return The device if found, null otherwise
     */
    fun getDevice(deviceId: String): CovIotDevice? {
        return loadDevicesFromLocal().find { it.id == deviceId }
    }
    
    companion object {
        @Volatile
        private var instance: CovIotDeviceManager? = null
        
        fun getInstance(context: Context): CovIotDeviceManager {
            return instance ?: synchronized(this) {
                instance ?: CovIotDeviceManager(context.applicationContext).also { instance = it }
            }
        }
    }
} 