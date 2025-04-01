//
//  KeyCenter.swift
//  OpenLive
//
//  Created by GongYuhua on 6/25/16.
//  Copyright © 2016 Agora. All rights reserved.
//

struct KeyCenter {
    /**
     Demo Server
     demo server is only for testing, not for production environment, please use your own server for production
    */
    static var TOOLBOX_SERVER_HOST: String = "https://service.agora.io/toolbox-global"
    
    /**
     Agora Key
     get from Agora Console
     */
    static let AG_APP_ID: String = ""
    static let AG_APP_CERTIFICATE: String = ""
    
    /**
     Basic Auth
     Get from Agora Console
     */
    static let BASIC_AUTH_KEY: String = ""
    static let BASIC_AUTH_SECRET: String = ""
    
    /**
     LLM
     Get from LLM vendor
     For example:
     static let LLM_URL: String="https://api.openai.com/v1/chat/completions"
     static let LLM_API_KEY: String="sk-proj-1234567890"
     static let LLM_SYSTEM_MESSAGES: String="You are a helpful assistant."
     static let LLM_MODEL: String="gpt-3.5-turbo"
     */
    static let LLM_URL: String = ""
    static let LLM_API_KEY: String = ""
    static let LLM_SYSTEM_MESSAGES: [String: Any] = [:]
    static let LLM_PARAMS: [String: Any] = [:]
    /**
     TTS
     Get from TTS vendor
     For example:
     static let TTS_VENDOR: String="microsoft"
     static let TTS_PARAMS: [String : Any] = [
         "key": "***",
         "region": "eastus",
         "endpoint_id": "",
         "voice_name": "en-US-AndrewMultilingualNeural",
         "sample_rate": 48000
     ]
     */
    static let TTS_VENDOR: String = ""
    static let TTS_PARAMS: [String : Any] = [:]
        
}
