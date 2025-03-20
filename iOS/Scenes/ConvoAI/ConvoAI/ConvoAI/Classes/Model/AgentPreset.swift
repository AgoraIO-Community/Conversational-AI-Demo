//
//  AgentPreset.swift
//  VoiceAgent
//
//  Created by Trae AI on 2024/01/19.
//

import Foundation

struct SupportLanguage: Codable {
    let languageCode: String
    let languageName: String
    
    enum CodingKeys: String, CodingKey {
        case languageCode = "language_code"
        case languageName = "language_name"
    }
}

struct AgentPreset: Codable {
    let name: String
    let displayName: String
    let index: Int
    let presetType: String
    let defaultLanguageCode: String
    let defaultLanguageName: String
    let supportLanguages: [SupportLanguage]
    let callTimeLimitSecond: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case index
        case presetType = "preset_type"
        case defaultLanguageCode = "default_language_code"
        case defaultLanguageName = "default_language_name"
        case supportLanguages = "support_languages"
        case callTimeLimitSecond = "call_time_limit_second"
    }
}
