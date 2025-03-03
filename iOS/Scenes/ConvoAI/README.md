# 🌟 Conversational AI Demo

The Conversational AI Engine redefines the human-machine interaction interface, breaking through traditional text-based interactions to achieve highly realistic and naturally flowing real-time voice conversations, enabling AI to truly "speak." It is suitable for innovative scenarios such as:

- 🤖 Intelligent assistants
- 💞 Emotional companionship
- 🗣️ Oral language practice
- 🎧 Intelligent customer service
- 📱 Smart hardware
- 🎮 Immersive game NPCs

## 🚀 1. Quick Start

This section mainly describes how to quickly run the Conversational AI Demo.

### 📱 1.1 Environment Preparation

- Xcode 15.0 or above
- iOS devices running iOS 15.0 or above

### ⚙️ 1.2 Running the Sample

1. Follow [Get started with Agora](https://docs-preview.agora.io/en/conversational-ai/get-started/manage-agora-account) to get the **App ID** and **App Certificate** and enable the **Conversational AI** service.
2. Follow [Generate Customer ID and Customer Secret](https://docs.agora.io/en/conversational-ai/rest-api/restful-authentication#generate-customer-id-and-customer-secret) to get the **Basic Auth Key** and **Basic Auth Secret**.
3. Get LLM configuration information from LLM vendor.
4. Get TTS configuration information from TTS vendor.
5. Open the `iOS` project and fill in the configuration information obtained above in the [**KeyCenter.swift**](../../Agent/KeyCenter.swift) file:

```Swift
    #----------- AppId --------------
    static let APP_ID: String = <Agora App ID>
    static let CERTIFICATE: String? = <Agora App Certificate>
  
    #----------- Basic Auth ---------------
    static let BASIC_AUTH_KEY: String = <Agora RESTful API KEY>
    static let BASIC_AUTH_SECRET: String = <Agora RESTful API SECRET>
  
    #----------- LLM -----------
    static let LLM_URL: String = <LLM Vendor API BASE URL>
    static let LLM_API_KEY: String? = <LLM Vendor API KEY>(optional)
    static let LLM_SYSTEM_MESSAGES: String? = <LLM Prompt>(optional)
    static let LLM_MODEL: String? = <LLM Model>(optional)
  
    #----------- TTS -----------
    static let TTS_VENDOR: String = <TTS Vendor>
    static let TTS_PARAMS: [String : Any] = <TTS Parameters>
```

### ⚙️ 2. Source Code Sitemap

| Path                                                                                                                           | Description                                     |
| ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------- |
| [AgentManager.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Manager/AgentManager.swift)                                         | Conversational AI API implementation and models |
| [RTCManager.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Manager/RTCManager.swift)                                             | RTC related implementations                     |
| [AgentPreferenceManager.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Manager/AgentPreferenceManager.swift)                     | Agent state management                          |
| [Main/](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Main)                                                                            | UI components and activities                    |
| [Main/Chat](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Main/Chat)                                                                   | Chat view and controllers                       |
| [AgentInformationViewController.swift](Scenes/VoiceAgent/VoiceAgent/Classes/Main/Setting/VC/AgentInformationViewController.swift) | Information dialog showing agent status         |
| [AgentSettingViewController.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Main/Setting/VC/AgentSettingViewController.swift)     | Settings dialog for agent configuration         |
| [Utils/](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Utils)                                                                          | Utility classes and helper functions            |
| [ConversationSubtitleController.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Utils/ConversationSubtitleController.swift)       | Subtitle rendering component                    |

## 📚 3. Related Resources

- Check our [Conversational AI Engine Document](https://docs.agora.io/en/conversational-ai/overview/product-overview) to learn more about Conversational AI Engine
- Visit [Agora SDK Samples](https://github.com/AgoraIO) for more tutorials
- Explore repositories managed by developer communities at [Agora Community](https://github.com/AgoraIO-Community)
- If you encounter issues during integration, feel free to ask questions on [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io)

## 💬 4. Feedback

If you have any problems or suggestions regarding the sample projects, we welcome you to file an issue.

## 📜 5. License

The sample projects are under the MIT license.
