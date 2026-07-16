# 🌟 Conversational AI Demo

The Conversational AI Engine redefines the human-AI interaction interface, breaking through traditional text-based interactions to achieve highly realistic and naturally flowing real-time voice conversations, enabling AI to truly "speak." It is suitable for innovative scenarios such as:

- 🤖 Intelligent assistants
- 💞 Emotional companionship
- 🗣️ Language Tutor
- 🎧 Intelligent customer service
- 📱 Smart hardware
- 🎮 Immersive game NPCs

## 🚀 1. Quick Start

This section mainly describes how to quickly run the Conversational AI Demo.

### 📱 1.1 Environment Preparation

- Minimum compatibility with Android 8.0 (SDK API Level 26)
- Android Studio 3.5 or above
- Android devices running Android 8.0 or above

### ⚙️ 1.2 Running the Sample

1. Follow [Get started with Agora](https://docs-preview.agora.io/en/conversational-ai/get-started/manage-agora-account) to get the **App ID** and **App Certificate** and enable the **Conversational AI** service.
2. Follow [Generate Customer ID and Customer Secret](https://docs.agora.io/en/conversational-ai/rest-api/restful-authentication#generate-customer-id-and-customer-secret) to get the **Basic Auth Key** and **Basic Auth Secret**.
3. Get LLM configuration information from LLM vendor.
4. Get TTS configuration information from TTS vendor.
5. Open the `Android` project and fill in properties got above to the root [**gradle.properties**](../../gradle.properties) file.

```
#----------- AppId --------------
AG_APP_ID=<Agora App ID>
AG_APP_CERTIFICATE=<Agora App Certificate>

#----------- Basic Auth ---------------
BASIC_AUTH_KEY=<Agora RESTful API KEY>
BASIC_AUTH_SECRET=<Agora RESTful API SECRET>

#----------- Open Source --------------
IS_OPEN_SOURCE=true

#----------- LLM -----------
LLM_URL=<LLM Vendor API BASE URL>
LLM_API_KEY=<LLM Vendor API KEY>(optional)
LLM_PARRAMS=<LLM Parameters>(optional)
LLM_SYSTEM_MESSAGES=<LLM Prompt>(optional)

#----------- TTS -----------
TTS_VENDOR=<TTS Vendor>
TTS_PARAMS=<TTS Parameters>

#----------- AVATAR -----------
AVATAR_VENDOR=<AVATAR Vendor>
AVATAR_PARAMS=<AVATAR Parameters>
```

## 🗂️ 2. Source Code Sitemap

### 2.1 Basic Sitemap
| Path                                                                                   | Description                                      |
|----------------------------------------------------------------------------------------|--------------------------------------------------|
| [api/](src/main/java/io/agora/scene/convoai/api)                                       | Conversational AI API implementation and models. |
| [animation/](src/main/java/io/agora/scene/convoai/animation)                           | Animation effects for agent interaction.         |
| [constant/](src/main/java/io/agora/scene/convoai/constant)                             | Constants and enums definition.                  |
| [ui/living/legacy/](src/main/java/io/agora/scene/convoai/ui/living/legacy)             | Demo-owned legacy v1 subtitle compatibility.     |
| [rtc/](src/main/java/io/agora/scene/convoai/rtc)                                       | RTC related implementations.                     |
| [rtm/](src/main/java/io/agora/scene/convoai/rtm)                                       | RTM related implementations.                     |
| [ui/](src/main/java/io/agora/scene/convoai/ui)                                         | UI components and activities.                    |
| [CovLivingActivity.kt](src/main/java/io/agora/scene/convoai/ui/CovLivingActivity.kt)   | Main activity for AI conversation.               |
| [CovSettingsDialog.kt](src/main/java/io/agora/scene/convoai/ui/CovSettingsDialog.kt)   | Settings dialog for agent configuration.         |
| [CovAgentInfoDialog.kt](src/main/java/io/agora/scene/convoai/ui/CovAgentInfoDialog.kt) | Information dialog showing agent status.         |
| [CovAgentSettingsFragment.kt](src/main/java/io/agora/scene/convoai/ui/dialog/CovAgentSettingsFragment.kt) | Settings fragment for agent configuration.       |
| [CovAgentInfoFragment.kt](src/main/java/io/agora/scene/convoai/ui/dialog/CovAgentInfoFragment.kt)         | Information fragment showing agent status.       |
| [CovAvatarSelectorDialog.kt](src/main/java/io/agora/scene/convoai/ui/dialog/CovAvatarSelectorDialog.kt)         | Information dialog showing agent status.                                            |

### 2.2 Real-time Subtitles
When interacting with conversational agents, you may need real-time subtitles to display your conversations with the agent.
- This sample consumes `io.agora.agents:agora-agent-client-toolkit` from Maven Central. The version is managed in [libs.versions.toml](../../gradle/libs.versions.toml).
- Living and SIP ViewModels create `io.agora.conversational.api.ConversationalAIAPIImpl` and render subtitles from `IConversationalAIAPIEventHandler.onTranscriptUpdated`.
- `ui/living/legacy` retains the legacy v1 RTC stream renderer because that compatibility path is not provided by the toolkit.
- The toolkit is implemented in Kotlin. Pure Java projects should follow Google's [Add Kotlin to an existing app](https://developer.android.com/kotlin/add-kotlin) guidance before integrating it.


## 📚 3. Related Resources

- Check our [Conversational AI Engine Document](https://docs.agora.io/en/conversational-ai/overview/product-overview) to learn more about Conversational AI Engine
- Visit [Agora SDK Samples](https://github.com/AgoraIO) for more tutorials
- Explore repositories managed by developer communities at [Agora Community](https://github.com/AgoraIO-Community)
- If you encounter issues during integration, feel free to ask questions on [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io)

## 💬 4. Feedback

If you have any problems or suggestions regarding the sample projects, we welcome you to file an issue.

## 📜 5. License

The sample projects are under the MIT license.
