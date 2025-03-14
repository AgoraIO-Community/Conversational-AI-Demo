//
//  File.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/10.
//

import Foundation

protocol IOTPresetsManagerDelegate: AnyObject {
    func presetsManager(_ manager: IOTPresetsManager, didUpdatePresets presets: [CovIotPreset])
    func presetsManager(_ manager: IOTPresetsManager, didDeleteAllPresets: Void)
}

protocol IOTPresetsManagerProtocol {
    func addDelegate(_ delegate: IOTPresetsManagerDelegate)
    func removeDelegate(_ delegate: IOTPresetsManagerDelegate)
    func setPresets(presets: [CovIotPreset])
    func deleteAllPresets()
    func allPresets() -> [CovIotPreset]?
}

class IOTPresetsManager: IOTPresetsManagerProtocol {
    // MARK: - Properties
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    private var presets: [CovIotPreset]?
    
    // MARK: - Singleton
    static let shared = IOTPresetsManager()
        
    // MARK: - Delegate Management
    func addDelegate(_ delegate: IOTPresetsManagerDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: IOTPresetsManagerDelegate) {
        delegates.remove(delegate)
    }
    
    // MARK: - Preset Management
    func setPresets(presets: [CovIotPreset]) {
        self.presets = presets
        notifyDelegates { $0.presetsManager(self, didUpdatePresets: presets) }
    }
    
    func deleteAllPresets() {
        presets = nil
        notifyDelegates { $0.presetsManager(self, didDeleteAllPresets: ()) }
    }
    
    func allPresets() -> [CovIotPreset]? {
        return presets
    }
    
    // MARK: - Private Methods
    private func notifyDelegates(_ notification: (IOTPresetsManagerDelegate) -> Void) {
        for delegate in delegates.allObjects {
            if let delegate = delegate as? IOTPresetsManagerDelegate {
                notification(delegate)
            }
        }
    }
}

// MARK: - Default Implementation for Delegate Methods
extension IOTPresetsManagerDelegate {
    func presetsManager(_ manager: IOTPresetsManager, didUpdatePresets presets: [CovIotPreset]) {}
    func presetsManager(_ manager: IOTPresetsManager, didDeleteAllPresets: Void) {}
}
