//
//  AppContext.swift
//  AgoraEntScenarios
//
//  Created by wushengtao on 2022/10/18.
//

import Foundation

@objc public class AppContext: NSObject {
    @objc public static let shared: AppContext = .init()
    
    public let globalTermsOfServiceUrl: String = "https://www.agora.io/en/terms-of-service/"
    public let globalPrivacyUrl: String = "https://www.agora.io/en/privacy-policy/"

    private var _appId: String = ""
    private var _certificate: String = ""
    private var _baseServerUrl: String = ""
    private var _environments: [[String : String]] = []
    private var _graphId: String = ""
    
    private var _basicAuthKey: String = ""
    private var _basicAuthSecret: String = ""
    private var _llmUrl: String = ""
    private var _llmApiKey: String = ""
    private var _llmSystemMessages: String = ""
    private var _llmModel: String = ""
    private var _ttsVendor: String = ""
    private var _ttsParams: [String: Any] = [:]
    
    override init() {
        super.init()
    }
    
    @objc public var appId: String {
        get { return _appId }
        set { _appId = newValue }
    }
    
    @objc public var certificate: String {
        get { return _certificate }
        set { _certificate = newValue }
    }
    
    @objc public var baseServerUrl: String {
        get { return _baseServerUrl }
        set { _baseServerUrl = newValue }
    }
    
    @objc public var environments: [[String : String]] {
        get { return _environments }
    }
    
    public func loadInnerEnvironment() {
        if let bundlePath = Bundle.main.path(forResource: "Common", ofType: "bundle"),
           let bundle = Bundle(path: bundlePath),
           let environmentsPath = bundle.path(forResource: "environments", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: environmentsPath)),
           let environments = try? JSONDecoder().decode([String: [[String: String]]].self, from: data) {
            _environments = environments["global"] ?? []
            if (appId.isEmpty) {
                _appId = _environments.first?["appId"] ?? ""
                _certificate = _environments.first?["certificate"] ?? ""
                _baseServerUrl = _environments.first?["host"] ?? ""
            }
        }
    }
    
    @objc public var graphId: String {
        get { return _graphId }
        set { _graphId = newValue }
    }
    
    @objc public var basicAuthKey: String {
        get { return _basicAuthKey }
        set { _basicAuthKey = newValue }
    }
    
    @objc public var basicAuthSecret: String {
        get { return _basicAuthSecret }
        set { _basicAuthSecret = newValue }
    }
    
    @objc public var llmUrl: String {
        get { return _llmUrl }
        set { _llmUrl = newValue }
    }
    
    @objc public var llmApiKey: String {
        get { return _llmApiKey }
        set { _llmApiKey = newValue }
    }
    
    @objc public var llmSystemMessages: String {
        get { return _llmSystemMessages }
        set { _llmSystemMessages = newValue }
    }
    
    @objc public var llmModel: String {
        get { return _llmModel }
        set { _llmModel = newValue }
    }
    
    @objc public var ttsVendor: String {
        get { return _ttsVendor }
        set { _ttsVendor = newValue }
    }
    
    @objc public var ttsParams: [String: Any] {
        get { return _ttsParams }
        set { _ttsParams = newValue }
    }
}
