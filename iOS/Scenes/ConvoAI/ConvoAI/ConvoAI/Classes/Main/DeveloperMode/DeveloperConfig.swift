//
//  DeveloperConfig.swift
//  ConvoAI
//
//  Created by HeZhengQing on 2025/07/29.
//

import UIKit
import SnapKit
import Common

public class DeveloperConfig {
    
    private let kSessionFree = "io.agora.convoai.kSessionFree"
    private let kMetrics = "io.agora.convoai.kMetrics"

    static let shared = DeveloperConfig()
    
    public var isDeveloperMode = false
    public var defaultAppId: String? = nil
    public var defaultHost: String? = nil
    public var convoaiServerConfig: String? = nil
    public var graphId: String? = nil
    public var sdkParams: [String] = []
    public var metrics: Bool = false

    internal var serverHost: String = ""
    internal var audioDump: Bool = false
    internal var sessionLimitEnabled: Bool = false
    
    internal var onCloseDevMode: (() -> Void)?
    internal var onSwitchServer: (() -> Void)?
    internal var onCopy: (() -> Void)?
    internal var onSessionLimit: ((Bool) -> Void)?
    internal var onAudioDump: ((Bool) -> Void)?
    internal var onMetrics: ((Bool) -> Void)?
    internal var onSDKParams: ((String) -> Void)?

    @discardableResult
    public func setServerHost(_ serverHost: String) -> Self {
        self.serverHost = serverHost
        return self
    }
    
    @discardableResult
    public func setSessionLimit(enabled: Bool = false, onChange: ((Bool) -> Void)? = nil) -> Self {
        self.sessionLimitEnabled = enabled
        self.onSessionLimit = onChange
        return self
    }
    
    @discardableResult
    public func setAudioDump(enabled: Bool = false, onChange: ((Bool) -> Void)? = nil) -> Self {
        self.audioDump = enabled
        self.onAudioDump = onChange
        return self
    }
    
    @discardableResult
    public func setCloseDevModeCallback(callback: (() -> Void)?) -> Self {
        self.onCloseDevMode = callback
        return self
    }
    
    @discardableResult
    public func setMetrics(enabled: Bool = false, onChange: ((Bool) -> Void)? = nil) -> Self {
        self.metrics = enabled
        self.onMetrics = onChange
        return self
    }
    
    @discardableResult
    public func setSwitchServerCallback(callback: (() -> Void)?) -> Self {
        self.onSwitchServer = callback
        return self
    }
    
    @discardableResult
    public func setCopyCallback(callback: (() -> Void)?) -> Self {
        self.onCopy = callback
        return self
    }

    @discardableResult
    public func setSDKParamsCallback(callback: ((String) -> Void)?) -> Self {
        self.onSDKParams = callback
        return self
    }
    
    public func setSessionFree(_ enable: Bool) {
        UserDefaults.standard.set(enable, forKey: kSessionFree)
    }
    
    public func getSessionFree() -> Bool {
        return UserDefaults.standard.bool(forKey: kSessionFree)
    }
    
    public func resetDevParams() {
        self.isDeveloperMode = false
        self.graphId = nil
        self.metrics = false
        self.sdkParams.removeAll()
        self.convoaiServerConfig = nil
        if let defaultHost = self.defaultHost {
            AppContext.shared.baseServerUrl = defaultHost
            self.defaultHost = nil
            self.onSwitchServer?()
        }
        
        if let defaultAppId = self.defaultAppId {
            AppContext.shared.appId = defaultAppId
            self.defaultAppId = nil
        }
    }
}
