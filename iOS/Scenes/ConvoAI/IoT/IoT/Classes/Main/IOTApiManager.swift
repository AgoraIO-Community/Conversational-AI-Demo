//
//  File.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/7.
//

import Foundation
import Common

// MARK: - Models
struct CovIotPreset: Codable {
    let preset_name: String
    let display_name: String
    let preset_brief: String
    let preset_type: String
    let support_languages: [CovIotLanguage]
    let call_time_limit_second: Int64
}

struct CovIotTokenModel: Codable {
    let agent_url: String
    let auth_token: String
}

struct CovIotLanguage: Codable {
    let isDefault: Bool
    let code: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case isDefault = "default"
        case code
        case name
    }
}

// MARK: - Protocol
protocol IOTApiProtocol {
    /// Fetches the list of presets
    /// - requestId: The unique identifier of the request
    /// - Parameter completion: Callback with optional error and array of presets
    func fetchPresets(requestId: String, completion: @escaping (IOTRequestError?, [CovIotPreset]?) -> Void)
    
    /// Generates a token for device authentication
    /// - Parameters:
    ///   - deviceId: The unique identifier of the device
    ///   - completion: Callback with optional token model and error
    func generatorToken(deviceId: String, completion: @escaping (CovIotTokenModel?, IOTRequestError?) -> Void)
    
    /// Updates device settings
    /// - Parameters:
    ///   - deviceId: The unique identifier of the device
    ///   - presetName: Name of the preset configuration
    ///   - asrLanguage: Language code for ASR (Automatic Speech Recognition)
    ///   - enableBHVS: Flag to enable/disable BHVS (Background Human Voice Suppression)
    ///   - completion: Callback with optional error
    func updateSettings(
        deviceId: String,
        presetName: String,
        asrLanguage: String,
        aivad: Bool,
        completion: @escaping (IOTRequestError?) -> Void
    )
}

// MARK: - Implementation
class IOTApiManager: IOTApiProtocol {
    private let SERVICE_VERSION = "v1"
    
    private var baseUrl: String {
        return AppContext.shared.baseServerUrl
    }
    
    // MARK: - Fetch Presets
    func fetchPresets(requestId: String, completion: @escaping (IOTRequestError?, [CovIotPreset]?) -> Void) {
        let url = "\(baseUrl)/convoai-iot/\(SERVICE_VERSION)/presets/list"
        let parameters: [String: Any] = [
            "request_id": requestId
        ]
        IoTLogger.info("fetch iot preset api: \(url) parameters: \(parameters)")

        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            IoTLogger.info("presets request response: \(result)")
            
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                completion(.serverError(code: code, message: msg), [])
                return
            }
            
            guard let data = result["data"] as? [[String: Any]] else {
                completion(.unknownError(message: "Invalid data format"), [])
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let presets = try JSONDecoder().decode([CovIotPreset].self, from: jsonData)
                completion(nil, presets)
            } catch {
                completion(.unknownError(message: error.localizedDescription), nil)
            }
        } failure: { msg in
            completion(.unknownError(message: msg), nil)
        }
    }
    
    // MARK: - Generate Token
    func generatorToken(deviceId: String, completion: @escaping (CovIotTokenModel?, IOTRequestError?) -> Void) {
        guard !deviceId.isEmpty else {
            completion(nil, .unknownError(message: "deviceId is null"))
            return
        }
        
        let url = "\(baseUrl)/convoai-iot/\(SERVICE_VERSION)/auth/token/generate"
        let parameters: [String: Any] = [
            "request_id": UUID().uuidString,
            "device_id": deviceId
        ]
        IoTLogger.info("generator token api: \(url) parameters: \(parameters)")
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            IoTLogger.info("token request response: \(result)")
            
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                completion(nil, .serverError(code: code, message: msg))
                return
            }
            
            guard let data = result["data"] as? [String: Any] else {
                completion(nil, .unknownError(message: "Invalid data format"))
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let tokenModel = try JSONDecoder().decode(CovIotTokenModel.self, from: jsonData)
                completion(tokenModel, nil)
            } catch {
                completion(nil, .unknownError(message: error.localizedDescription))
            }
        } failure: { msg in
            completion(nil, .unknownError(message: msg))
        }
    }
    
    // MARK: - Update Settings
    func updateSettings(
        deviceId: String,
        presetName: String,
        asrLanguage: String,
        aivad: Bool,
        completion: @escaping (IOTRequestError?) -> Void
    ) {
        guard !deviceId.isEmpty else {
            completion(.unknownError(message: "deviceId is null"))
            return
        }
        
        let url = "\(baseUrl)/convoai-iot/\(SERVICE_VERSION)/device/preset/update"
        let parameters: [String: Any] = [
            "request_id": UUID().uuidString,
            "device_id": deviceId,
            "preset_name": presetName,
            "asr_language": asrLanguage,
            "advanced_features_enable_aivad": aivad
        ]
        
        IoTLogger.info("update setting api: \(url) parameters: \(parameters)")
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            IoTLogger.info("update settings response: \(result)")
            
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                completion(.serverError(code: code, message: msg))
                return
            }
            
            completion(nil)
        } failure: { msg in
            completion(.unknownError(message: msg))
        }
    }
}

enum IOTRequestError: Error {
    case serverError(code: Int, message: String)
    case unknownError(message: String)

    var code: Int {
        switch self {
        case .serverError(let code, _):
            return code
        case .unknownError:
            return -100
        }
    }

    var message: String {
        switch self {
        case .serverError(_, let message), .unknownError(let message):
            return message
        }
    }
}

