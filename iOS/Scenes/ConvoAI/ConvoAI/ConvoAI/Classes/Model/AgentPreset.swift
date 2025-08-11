//
//  AgentPreset.swift
//  VoiceAgent
//
//  Created by Trae AI on 2024/01/19.
//

import Foundation

struct Avatar: Codable {
    let vendor: String
    let avatarId: String
    let avatarName: String
    let thumbImageUrl: String
    let bgImageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case vendor = "vendor"
        case avatarId = "avatar_id"
        case avatarName = "avatar_name"
        case thumbImageUrl = "thumb_img_url"
        case bgImageUrl = "bg_img_url"
    }
}

struct SupportLanguage: Codable {
    let languageCode: String
    let languageName: String
    let aivadEnabledByDefault: Bool
    let aivadSupported: Bool
    
    enum CodingKeys: String, CodingKey {
        case languageCode = "language_code"
        case languageName = "language_name"
        case aivadEnabledByDefault = "aivad_enabled_by_default"
        case aivadSupported = "aivad_supported"
    }
}

struct AgentPreset: Codable {
    let name: String
    let displayName: String
    let description: String?
    let presetType: String
    let defaultLanguageCode: String?
    let defaultLanguageName: String?
    let isSupportVision: Bool
    let callTimeLimitSecond: Int
    let callTimeLimitAvatarSecond: Int?
    let supportLanguages: [SupportLanguage]?
    let avatarIdsByLang: [String: [Avatar]]?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case description
        case presetType = "preset_type"
        case defaultLanguageCode = "default_language_code"
        case defaultLanguageName = "default_language_name"
        case isSupportVision = "is_support_vision"
        case callTimeLimitSecond = "call_time_limit_second"
        case callTimeLimitAvatarSecond = "call_time_limit_avatar_second"
        case supportLanguages = "support_languages"
        case avatarIdsByLang = "avatar_ids_by_lang"
        case avatarUrl = "avatar_url"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let nameString = try? container.decode(String.self, forKey: .name) {
            self.name = nameString
        } else {
            let nameInt = try container.decode(Int.self, forKey: .name)
            self.name = "\(nameInt)"
        }

        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.presetType = try container.decode(String.self, forKey: .presetType)
        self.defaultLanguageCode = try container.decodeIfPresent(String.self, forKey: .defaultLanguageCode)
        self.defaultLanguageName = try container.decodeIfPresent(String.self, forKey: .defaultLanguageName)

        if let isSupportVisionBool = try? container.decode(Bool.self, forKey: .isSupportVision) {
            self.isSupportVision = isSupportVisionBool
        } else {
            let isSupportVisionInt = try container.decode(Int.self, forKey: .isSupportVision)
            self.isSupportVision = (isSupportVisionInt == 1)
        }

        self.callTimeLimitSecond = try container.decode(Int.self, forKey: .callTimeLimitSecond)
        self.callTimeLimitAvatarSecond = try container.decodeIfPresent(Int.self, forKey: .callTimeLimitAvatarSecond)
        self.supportLanguages = try container.decodeIfPresent([SupportLanguage].self, forKey: .supportLanguages)
        self.avatarIdsByLang = try container.decodeIfPresent([String: [Avatar]].self, forKey: .avatarIdsByLang)
        self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(presetType, forKey: .presetType)
        try container.encodeIfPresent(defaultLanguageCode, forKey: .defaultLanguageCode)
        try container.encodeIfPresent(defaultLanguageName, forKey: .defaultLanguageName)
        try container.encode(isSupportVision, forKey: .isSupportVision)
        try container.encode(callTimeLimitSecond, forKey: .callTimeLimitSecond)
        try container.encodeIfPresent(callTimeLimitAvatarSecond, forKey: .callTimeLimitAvatarSecond)
        try container.encodeIfPresent(supportLanguages, forKey: .supportLanguages)
        try container.encodeIfPresent(avatarIdsByLang, forKey: .avatarIdsByLang)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
    }
}

