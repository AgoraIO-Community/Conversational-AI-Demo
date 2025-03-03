# 🌟 Conversational AI Demo

The Conversational AI Engine redefines the human-machine interaction interface, breaking through traditional text-based interactions to achieve highly realistic and naturally flowing real-time voice conversations, enabling AI to truly "speak." It is suitable for innovative scenarios such as intelligent assistants, emotional companionship, oral language practice, intelligent customer service, smart hardware, and immersive game NPCs.

## 🚀 1. Quick Start

This section mainly describes how to quickly run the Conversational AI Demo.

### 📱 1.1 Environment Preparation

- Minimum compatibility with Android 7.0 (SDK API Level 24)
- Android Studio 3.5 or above
- Android devices running Android 7.0 or above

### ⚙️ 1.2 Running the Sample

1. Follow [The Account Document](https://docs.agora.io/en/video-calling/reference/manage-agora-account) to get the **App ID** and **App Certificate**.
2. Please contact Agora technical support to grant conversational AI permission to your APPID. Only after granting permission can you properly experience the demo features.
3. Open the `Android` project and fill in properties got above to the root [**gradle.properties**](../../gradle.properties) file.

```
#----------- AppId --------------
AG_APP_ID=<Agora App ID>
AG_APP_CERTIFICATE=<Agora App Certificate>

#----------- Basic Auth ---------------
BASIC_AUTH_KEY=<Agora RESTful API KEY>
BASIC_AUTH_SECRET=<Agora RESTful API SECRET>

#----------- LLM -----------
LLM_URL=<LLM Vendor API BASE URL>
LLM_API_KEY=<LLM Vendor API KEY>
LLM_SYSTEM_MESSAGES=<LLM Prompt>
LLM_MODEL=<LLM Model>

#----------- TTS -----------
TTS_VENDOR=<TTS Vendor>
TTS_PARAMS=<TTS Parameters>
```

### ⚙️ 2. Source Code Sitemap

| Path                                                                                                    | Description                                      |
| ------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [api/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/api)                                    | Conversational AI API implementation and models. |
| [animation/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/animation)                        | Animation effects for agent interaction.         |
| [constant/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/constant)                          | Constants and enums definition.                  |
| [subRender/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/subRender/v2)                     | Subtitle rendering component.                    |
| [rtc/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/rtc)                                    | RTC related implementations.                     |
| [ui/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/ui)                                      | UI components and activities.                    |
| [utils/](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/utils)                                | Utility classes and helper functions.            |
| [CovLivingActivity.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovLivingActivity.kt)   | Main activity for AI conversation.               |
| [CovSettingsDialog.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovSettingsDialog.kt)   | Settings dialog for agent configuration.         |
| [CovAgentInfoDialog.kt](Android/scenes/convoai/src/main/java/io/agora/scene/convoai/CovAgentInfoDialog.kt) | Information dialog showing agent status.         |

## 📚 3. Related Resources

- Check our [Conversational AI Engine Document]() to learn more about Conversational AI Engine
- Visit [Agora SDK Samples](https://github.com/AgoraIO) for more tutorials
- Explore repositories managed by developer communities at [Agora Community](https://github.com/AgoraIO-Community)
- If you encounter issues during integration, feel free to ask questions on [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io)

## 💬 4. Feedback

If you have any problems or suggestions regarding the sample projects, we welcome you to file an issue.

## 📜 5. License

The sample projects are under the MIT license.
