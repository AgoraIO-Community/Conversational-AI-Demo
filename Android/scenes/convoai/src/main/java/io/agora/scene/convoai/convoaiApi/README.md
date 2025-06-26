# ConversationalAI API for Android

**IMPORTANT:**
> You must manage the initialization, lifecycle, and login state of RTC and RTM instances yourself.
>
> Please ensure that the RTC and RTM instances outlive the lifecycle of this component.
>
> Before using this component, make sure RTC is available and RTM is logged in.
>
> You are expected to have already integrated Agora RTC/RTM in your project. Please ensure you are using Agora RTC SDK version **4.5.1 or above**.
>
> ⚠️ Before using this component, you must enable the "Real-time Messaging (RTM)" feature in your Agora project console. If RTM is not enabled, the component will not function properly.
>
> RTM Integration Guide: [RTM](https://doc.shengwang.cn/doc/rtm2/android/landing-page)

![Enable RTM in Agora Console](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/sdhy_7.jpg)
*Screenshot: Enable RTM in the Agora Console Project Settings*

---

## Integration Steps

1. Copy the following files and folders into your Android project:
   - [subRender/v3/](./subRender/v3/) (entire folder)
   - [ConversationalAIAPIImpl.kt](./ConversationalAIAPIImpl.kt)
   - [IConversationalAIAPI.kt](./IConversationalAIAPI.kt)
   - [ConversationalAIUtils.kt](./ConversationalAIUtils.kt)

   > ⚠️ Make sure to keep the package structure (`io.agora.scene.convoai.convoaiApi`) unchanged for smooth integration.

## Quick Start Example

Follow these steps to quickly integrate and use the ConversationalAI API:

1. **Initialize the API configuration**

   Create a configuration object with your RTC and RTM instances:
   ```kotlin
   val config = ConversationalAIAPIConfig(
       rtcEngine = rtcEngineInstance,
       rtmClient = rtmClientInstance,
       renderMode = TranscriptionRenderMode.Word, // or TranscriptionRenderMode.Text
       enableLog = true
   )
   ```

2. **Create the API instance**

   ```kotlin
   val api = ConversationalAIAPIImpl(config)
   ```

3. **Register an event handler**

   Implement and add your event handler to receive agent events and transcriptions:
   ```kotlin
   api.addHandler(object : IConversationalAIAPIEventHandler {
       override fun onAgentStateChanged(agentUserId: String, event: StateChangeEvent) { /* ... */ }
       override fun onAgentInterrupted(agentUserId: String, event: InterruptEvent) { /* ... */ }
       override fun onAgentMetrics(agentUserId: String, metric: Metric) { /* ... */ }
       override fun onAgentError(agentUserId: String, error: ModuleError) { /* ... */ }
       override fun onTranscriptionUpdated(agentUserId: String, transcription: Transcription) { /* ... */ }
       override fun onDebugLog(log: String) { /* ... */ }
   })
   ```

4. **Subscribe to a channel**

   Call this before starting a conversation:
   ```kotlin
   api.subscribeMessage("channelName") { error ->
       if (error != null) {
           // handle error
       }
   }
   ```

5. **(Optional) Set audio parameters before joining RTC channel**

   ```kotlin
   api.loadAudioSettings()
   rtcEngine.joinChannel(token, channelName, null, userId)
   ```

6. **Send a message to the AI agent**

   ```kotlin
   api.chat(
       agentUserId = "agentId",
       message = ChatMessage(
           priority = Priority.INTERRUPT,
           responseInterruptable = true,
           text = "Hello!"
       )
   ) { error ->
       if (error != null) {
           // handle error
       }
   }
   ```

7. **Interrupt the agent (if needed)**

   ```kotlin
   api.interrupt("agentId") { error -> /* ... */ }
   ```

8. **Destroy the API instance when done**

   ```kotlin
   api.destroy()
   ```

---

## Important Notes

- **Audio Settings:**  
  You MUST call `loadAudioSettings()` before joining the RTC channel to ensure optimal audio quality for AI conversation.
  ```kotlin
  api.loadAudioSettings()
  rtcEngine.joinChannel(token, channelName, null, userId)
  ```

- **All event callbacks are on the main thread.**  
  You can safely update UI in your event handlers.

- **Some callbacks (e.g., `onTranscriptionUpdated`) may be high-frequency.**  
  If needed, implement deduplication or throttling in your handler.

- **Error Handling:**  
  All API methods provide error callbacks. Always check for errors in your completion handlers.

---

## File/Folder Structure

- [IConversationalAIAPI.kt](./IConversationalAIAPI.kt) — API interface and all related data structures and enums
- [ConversationalAIAPIImpl.kt](./ConversationalAIAPIImpl.kt) — Main implementation of the ConversationalAI API logic
- [ConversationalAIUtils.kt](./ConversationalAIUtils.kt) — Utility functions and event handler management
- [subRender/](./subRender/) 
    - [v3/](./subRender/v3/) — Transcription module
        - [TranscriptionController.kt](./subRender/v3/TranscriptionController.kt)
        - [MessageParser.kt](./subRender/v3/MessageParser.kt) 

> The above files and folders are all you need to integrate the ConversationalAI API. No other files are required.

---

## Feedback

- If you have any problems or suggestions regarding the sample projects, we welcome you to file an issue. 