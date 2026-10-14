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

- Xcode 15.0 or above
- iOS devices running iOS 15.0 or above

### ⚙️ 1.2 Running the Sample

1. Follow [Get started with Agora](https://docs-preview.agora.io/en/conversational-ai/get-started/manage-agora-account) to get the **App ID** and **App Certificate** and enable the **Conversational AI** service.
2. Follow [Generate Customer ID and Customer Secret](https://docs.agora.io/en/conversational-ai/rest-api/restful-authentication#generate-customer-id-and-customer-secret) to get the **Basic Auth Key** and **Basic Auth Secret**.
3. Get LLM configuration information from LLM vendor.
4. Get TTS configuration information from TTS vendor.
5. Open the `iOS` project and fill in the configuration information obtained above in the [**KeyCenter.swift**](../../Agent/KeyCenter.swift) file:

```Swift
    static var IS_OPEN_SOURCE: Bool = true

    //----------- AppId --------------
    static let AG_APP_ID: String = <Agora App ID>
    static let AG_APP_CERTIFICATE: String = <Agora App Certificate>
  
    //----------- Basic Auth ---------------
    static let BASIC_AUTH_KEY: String = <Agora RESTful API KEY>
    static let BASIC_AUTH_SECRET: String = <Agora RESTful API SECRET>
  
    //----------- LLM -----------
    static let LLM_URL: String = <LLM Vendor API BASE URL>
    static let LLM_API_KEY: String = <LLM Vendor API KEY>
    static let LLM_SYSTEM_MESSAGES: [[String: Any]] = <LLM Prompt>
    static let LLM_PARAMS: [String: Any] = <LLM Vendor Parameters>
  
    //----------- TTS -----------
    static let TTS_VENDOR: String = <TTS Vendor>
    static let TTS_PARAMS: [String : Any] = <TTS Parameters>

```

Open-source mode does not support digital humans, so `KeyCenter.swift` has no digital-human setup fields and the demo sends `avatar.enable=false`. Ordinary voice defaults to the `aiclient` audio scenario; `independent` mode defaults to `chorus`. Developer mode can explicitly override the client audio scenario. Outside open-source mode, business-server presets can still enable digital humans.

## 🗂️ 2. Source Code Sitemap

### ⚙️ 2.1 Basic Sitemap

| Path                                                                                                          | Description                                     |
| ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| [AgentManager.swift](ConvoAI/ConvoAI/Classes/Manager/AgentManager.swift)                                              | Conversational AI API implementation            |
| [RTCManager.swift](ConvoAI/ConvoAI/Classes/Manager/RTCManager.swift)                                                  | RTC related implementations                     |
| [AgentPreferenceManager.swift](ConvoAI/ConvoAI/Classes/Manager/AgentPreferenceManager.swift)                          | Agent state management                          |
| [Main/](ConvoAI/ConvoAI/Classes/Main)                                                                                 | UI components and view cotrollers               |
| [Main/Chat](ConvoAI/ConvoAI/Classes/Main/Chat)                                                                        | Chat view and controllers                       |
| [AgentInformationViewController.swift](ConvoAI/ConvoAI/Classes/Main/Setting/VC/AgentInformationViewController.swift)  | Information dialog showing agent status         |
| [AgentSettingViewController.swift](ConvoAI/ConvoAI/Classes/Main/Setting/VC/AgentSettingViewController.swift)          | Settings dialog for agent configuration         |
| [Utils/](ConvoAI/ConvoAI/Classes/Utils)                                                                               | Utility classes and helper functions            |
| `agent-client-toolkit-swift` (published version 2.10.1)                                                                                   | Current Conversational AI API, state, and real-time transcript component |
| [TranscriptionV1/](ConvoAI/ConvoAI/Classes/Utils/TranscriptionV1)                                                    | Demo-owned legacy v1 subtitle renderer          |
| [TranscriptionV2/](ConvoAI/ConvoAI/Classes/Utils/TranscriptionV2)                                                    | Demo-owned legacy v2 subtitle renderer          |

### 2.2 Real-time Subtitles

When interacting with conversational agents, you may need real-time subtitles to display your conversations with the agent.
- The current API and transcript implementation come from the CocoaPods component `agent-client-toolkit-swift` (published version 2.10.1), whose Swift module is `AgoraAgentClientToolkit`:

```ruby
pod 'agent-client-toolkit-swift', '2.10.1'
```

- The Demo retains the v1 and v2 subtitle renderers for legacy compatibility; the current default flow uses the Toolkit implementation.


### 2.3 Published Toolkit integration

`iOS/Podfile` configures these published dependencies and resolves their specs through the Tsinghua CocoaPods Specs mirror:

```ruby
pod 'agent-client-toolkit-swift', '2.10.1'
pod 'Agora-Rtm', '2.3.0', :subspecs => ['RtmKit']
```

When switching from source integration or refreshing an older local spec index, run from the demo repository root:

```bash
cd iOS
pod _1.16.2_ install --repo-update
```

Open `Agent.xcworkspace` to build and run. Local and Jenkins builds download the published XCFramework through CocoaPods; no Toolkit source checkout is required.

Use `import AgoraAgentClientToolkit` in Swift. Toolkit requires neither a `:path` override nor a manually added XCFramework. The existing `:path` entries for Demo modules such as `ConvoAI` and `Common` load business code from this repository. When upgrading Toolkit, update the version in both `iOS/Podfile` and `iOS/Scenes/ConvoAI/ConvoAI/ConvoAI.podspec`.

The demo passes its AINS selection into `loadAudioSettings(scenario:enableAins:)`, defaulting to disabled and retaining the selection across audio route changes.

### 2.4 Walkie-Talkie Mode (hold to talk)

For business standard or custom presets, **Walkie-Talkie Mode** appears below **Intelligent Pause** in the agent settings; its tips button explains the mode. It is off by default and resets when the preset changes. Independent presets and open-source mode do not offer it. Agent settings are locked from the start of a call (including token and RTM preparation) until it ends.

While the switch is on, **Intelligent Interruption Handling** and **Intelligent Pause** are shown off and locked. Their stored values are kept and shown again when the switch is turned off. A manual call sends `app_feature.manual_speech_control_mode=manual_sos_and_eos` with `enable_aivad=false` and `pause_state_enabled=false`; other calls send the same `app_feature` as before.

In a connected manual call, hold **Hold to talk** to speak: press publishes `manualSOS`, and release keeps 200 ms of tail audio, then publishes `manualEOS`. The mute control stays the master switch. App inactivity, audio interruption, presented overlays, touch cancellation and RTC reconnect release the button. When the agent ends a turn (`AGENT_MANUAL_EOS`), only the current turn ends.

A failed start leaves the channel if it was joined and shows a hint; hanging up during preparation cancels the start. The call ends with a hint when the agent leaves, the RTM connection fails or a renewed token cannot be fetched, and it ends when the call page is popped or dismissed. If RTM rejects a renewed token, only a hint is shown and the call continues.

To test the controller without a simulator, from the repository root:

```bash
python3 scripts/test_manual_eos_ios.py
```

Then, on a device, turn the switch on, start a call, hold the button to speak and release it to send. Audio, tail timing and server behavior are verified only on devices.

## 📚 3. Related Resources

- Check our [Conversational AI Engine Document](https://docs.agora.io/en/conversational-ai/overview/product-overview) to learn more about Conversational AI Engine
- Visit [Agora SDK Samples](https://github.com/AgoraIO) for more tutorials
- Explore repositories managed by developer communities at [Agora Community](https://github.com/AgoraIO-Community)
- If you encounter issues during integration, feel free to ask questions on [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io)

## 💬 4. Feedback

If you have any problems or suggestions regarding the sample projects, we welcome you to file an issue.

## 📜 5. License

The sample projects are under the MIT license.


### AI workflow and validation

See [iOS workflow](../../AGENTS.md) and [validation guide](../../docs/VALIDATION.md). From the repository root, run `python3 scripts/validate.py ios --suite ains` for standalone AINS tests; `--list` shows the available suites and their scope is defined in `scripts/workflow.json`.
