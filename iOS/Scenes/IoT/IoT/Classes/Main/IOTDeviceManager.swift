//
//  IOTDeviceManager.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/10.
//

import Foundation

protocol IOTDeviceManagerDelegate: AnyObject {
    func deviceManager(_ manager: IOTDeviceManager, didAddDevice device: LocalDevice)
    func deviceManager(_ manager: IOTDeviceManager, didUpdateDevice device: LocalDevice)
    func deviceManager(_ manager: IOTDeviceManager, didRemoveDevice deviceId: String)
    
    func deviceManager(_ manager: IOTDeviceManager, didUpdatePreset preset: CovIotPreset, forDevice deviceId: String)
    func deviceManager(_ manager: IOTDeviceManager, didUpdateLanguage language: CovIotLanguage, forDevice deviceId: String)
    func deviceManager(_ manager: IOTDeviceManager, didUpdateName name: String, forDevice deviceId: String)
    func deviceManager(_ manager: IOTDeviceManager, didUpdateAIVad enabled: Bool, forDevice deviceId: String)
}

protocol IOTDeviceManagerProtocol {
    func addDelegate(_ delegate: IOTDeviceManagerDelegate)
    func removeDelegate(_ delegate: IOTDeviceManagerDelegate)
    
    func addDevice(device: LocalDevice)
    func updatePreset(preset: CovIotPreset, deviceId: String)
    func updateDeviceName(name: String, deviceId: String)
    func updateAIVad(aivad: Bool, deviceId: String)
    func updateLanguage(language: CovIotLanguage, deviceId: String)
    func removeDevice(deviceId: String)
    
    func getDevice(deviceId: String) -> LocalDevice?
    func getAllDevices() -> [LocalDevice]
}

class IOTDeviceManager: IOTDeviceManagerProtocol {
    // MARK: - Properties
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    private var devices: [LocalDevice] = []
    
    // MARK: - Initialization
    init() {
        loadDevices()
    }
    
    // MARK: - Delegate Management
    func addDelegate(_ delegate: IOTDeviceManagerDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: IOTDeviceManagerDelegate) {
        delegates.remove(delegate)
    }
    
    // MARK: - Device Management
    func addDevice(device: LocalDevice) {
        if let index = devices.firstIndex(where: { $0.deviceId == device.deviceId }) {
            // Device exists, update it
            devices[index] = device
            saveDevices()
            notifyDelegates { $0.deviceManager(self, didUpdateDevice: device) }
        } else {
            // New device, add it
            devices.append(device)
            saveDevices()
            notifyDelegates { $0.deviceManager(self, didAddDevice: device) }
        }
    }
    
    func updatePreset(preset: CovIotPreset, deviceId: String) {
        guard var device = getDevice(deviceId: deviceId) else { return }
        device.currentPreset = preset
        updateDevice(device)
        notifyDelegates { $0.deviceManager(self, didUpdatePreset: preset, forDevice: deviceId) }
    }
    
    func updateDeviceName(name: String, deviceId: String) {
        guard var device = getDevice(deviceId: deviceId) else { return }
        device.name = name
        updateDevice(device)
        notifyDelegates { $0.deviceManager(self, didUpdateName: name, forDevice: deviceId) }
    }
    
    func updateAIVad(aivad: Bool, deviceId: String) {
        guard var device = getDevice(deviceId: deviceId) else { return }
        device.aiVad = aivad
        updateDevice(device)
        notifyDelegates { $0.deviceManager(self, didUpdateAIVad: aivad, forDevice: deviceId) }
    }
    
    func updateLanguage(language: CovIotLanguage, deviceId: String) {
        guard var device = getDevice(deviceId: deviceId) else { return }
        device.currentLanguage = language
        updateDevice(device)
        notifyDelegates { $0.deviceManager(self, didUpdateLanguage: language, forDevice: deviceId) }
    }
    
    func removeDevice(deviceId: String) {
        devices.removeAll { $0.deviceId == deviceId }
        saveDevices()
        notifyDelegates { $0.deviceManager(self, didRemoveDevice: deviceId) }
    }
    
    func getDevice(deviceId: String) -> LocalDevice? {
        return devices.first { $0.deviceId == deviceId }
    }
    
    func getAllDevices() -> [LocalDevice] {
        return devices
    }
    
    // MARK: - Private Methods
    private func updateDevice(_ device: LocalDevice) {
        if let index = devices.firstIndex(where: { $0.deviceId == device.deviceId }) {
            devices[index] = device
            saveDevices()
            notifyDelegates { $0.deviceManager(self, didUpdateDevice: device) }
        }
    }
    
    private func saveDevices() {
        if let encoded = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: "IOTDevices")
        }
    }
    
    private func loadDevices() {
        if let data = UserDefaults.standard.data(forKey: "IOTDevices"),
           let decoded = try? JSONDecoder().decode([LocalDevice].self, from: data) {
            devices = decoded
        }
    }
    
    private func notifyDelegates(_ notification: (IOTDeviceManagerDelegate) -> Void) {
        for delegate in delegates.allObjects {
            if let delegate = delegate as? IOTDeviceManagerDelegate {
                notification(delegate)
            }
        }
    }
}

// MARK: - Default Implementation for Delegate Methods
extension IOTDeviceManagerDelegate {
    func deviceManager(_ manager: IOTDeviceManager, didAddDevice device: LocalDevice) {}
    func deviceManager(_ manager: IOTDeviceManager, didUpdateDevice device: LocalDevice) {}
    func deviceManager(_ manager: IOTDeviceManager, didRemoveDevice deviceId: String) {}
    
    func deviceManager(_ manager: IOTDeviceManager, didUpdatePreset preset: CovIotPreset, forDevice deviceId: String) {}
    func deviceManager(_ manager: IOTDeviceManager, didUpdateLanguage language: CovIotLanguage, forDevice deviceId: String) {}
    func deviceManager(_ manager: IOTDeviceManager, didUpdateName name: String, forDevice deviceId: String) {}
    func deviceManager(_ manager: IOTDeviceManager, didUpdateAIVad enabled: Bool, forDevice deviceId: String) {}
}

struct LocalDevice: Codable {
    var name: String
    let deviceId: String
    let rssi: String
    var currentPreset: CovIotPreset
    var currentLanguage: CovIotLanguage
    var aiVad: Bool
}

