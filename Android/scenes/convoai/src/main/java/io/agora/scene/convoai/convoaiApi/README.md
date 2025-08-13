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
       renderMode = TranscriptRenderMode.Word, // or TranscriptRenderMode.Text
       enableLog = true
   )
   ```

2. **Create the API instance**

   ```kotlin
   val api = ConversationalAIAPIImpl(config)
   ```

3. **Register an event handler**

   Implement and add your event handler to receive agent events and transcripts:
   ```kotlin
   api.addHandler(object : IConversationalAIAPIEventHandler {
       override fun onAgentStateChanged(agentUserId: String, event: StateChangeEvent) { /* ... */ }
       override fun onAgentInterrupted(agentUserId: String, event: InterruptEvent) { /* ... */ }
       override fun onAgentMetrics(agentUserId: String, metric: Metric) { /* ... */ }
       override fun onAgentError(agentUserId: String, error: ModuleError) { /* ... */ }
       override fun onMessageError(agentUserId: String, error: MessageError) { /* ... */ } 
       override fun onMessageReceiptUpdated(agentUserId: String, receipt: MessageReceipt) { /* ... */ }
       override fun onAgentVoiceprintStateChanged(agentUserId: String, event: VoiceprintEvent) { /* ... */ }    
       override fun onTranscriptUpdated(agentUserId: String, transcript: Transcript) { /* ... */ }
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

    **⚠️ Important: If Avatar is enabled, you must set the correct audio scenario:**

   ```kotlin
   // When enabling Avatar, use AUDIO_SCENARIO_DEFAULT for better audio mixing effects
   api.loadAudioSettings(Constants.AUDIO_SCENARIO_DEFAULT)
   rtcEngine.joinChannel(token, channelName, null, userId)
   ```

6. **(Optional) Send messages to AI agent**

   **Send text messages:**
   ```kotlin
   // Basic text message
   api.chat("agentUserId", TextMessage(text = "Hello, how are you?")) { error ->
       if (error != null) {
           Log.e("Chat", "Failed to send text: ${error.errorMessage}")
       }
   }
   
   // Text message with priority control
   api.chat("agentUserId", TextMessage(
       text = "Urgent question!",
       priority = Priority.INTERRUPT,
       responseInterruptable = true
   )) { error ->
       if (error != null) {
           Log.e("Chat", "Failed to send text: ${error.errorMessage}")
       }
   }
   ```

   **Send image messages:**
   ```kotlin
   val uuid = "unique-image-id-123" // Generate unique image identifier
   val imageUrl = "https://example.com/image.jpg" // Image HTTP/HTTPS URL
   
   api.chat("agentUserId", ImageMessage(uuid = uuid, imageUrl = imageUrl)) { error ->
       if (error != null) {
           Log.e("Chat", "Failed to send image: ${error.errorMessage}")
       } else {
           Log.d("Chat", "Image send request successful")
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

## Message Type Description

### Text Message (TextMessage)

Text messages are suitable for natural language interaction:

```kotlin
// Text message
val textMessage = TextMessage(text = "Hello, how are you?")
```

### Image Message (ImageMessage)

Image messages are suitable for visual content processing, with status tracking via `uuid`:

```kotlin
// Using image URL
val urlImageMessage = ImageMessage(
    uuid = "img_123",
    imageUrl = "https://example.com/image.jpg"
)

// Using Base64 encoding (note 32KB limit)
val base64ImageMessage = ImageMessage(
    uuid = "img_456",
    imageBase64 = "data:image/jpeg;base64,..."
)
```

### Send Messages

Use the unified `chat` interface to send different types of messages:

```kotlin
// Send text message
api.chat("agentUserId", TextMessage(text = "Hello, how are you?")) { error ->
    if (error != null) {
        Log.e("Chat", "Failed to send text: ${error.errorMessage}")
    }
}

// Send image message
api.chat("agentUserId", ImageMessage(uuid = "img_123", imageUrl = "https://...")) { error ->
    if (error != null) {
        Log.e("Chat", "Failed to send image: ${error.errorMessage}")
    }
}
```

### Handle Image Send Status

The actual success or failure status of image sending is confirmed through the following two callbacks:

#### 1. Image Send Success - onMessageReceiptUpdated

When receiving the `onMessageReceiptUpdated` callback, follow these steps to parse and confirm the image send status:

**Important: Check `receipt.chatMessageType == ChatMessageType.Image` for image message status**

```kotlin
override fun onMessageReceiptUpdated(agentUserId: String, receipt: MessageReceipt) {
    if (receipt.chatMessageType == ChatMessageType.Image) {
        try {
            val json = JSONObject(receipt.message)
            if (json.has("uuid")) {
                val receivedUuid = json.getString("uuid")

                 // If uuid matches, this image was sent successfully
                 if (receivedUuid == "your-sent-uuid") {
                     Log.d("ImageSend", "Image sent successfully: $receivedUuid")
                     // Update UI to show send success status
                 }
            }
        } catch (e: Exception) {
            Log.e("ImageSend", "Failed to parse message receipt: ${e.message}")
        }
    }
}
```

#### 2. Image Send Failure - onMessageError

When receiving the `onMessageError` callback, follow these steps to parse and confirm the image send failure:

```kotlin
override fun onMessageError(agentUserId: String, error: MessageError) {
    if (error.chatMessageType == ChatMessageType.Image) {
        try {
            val json = JSONObject(error.message)
            if (json.has("uuid")) {
                val failedUuid = json.getString("uuid")

                 // If uuid matches, this image send failed
                 if (failedUuid == "your-sent-uuid") {
                     Log.e("ImageSend", "Image send failed: $failedUuid")
                     // Update UI to show send failure status
                 }
            }
        } catch (e: Exception) {
            Log.e("ImageSend", "Failed to parse error message: ${e.message}")
        }
    }
}
```

---

## Important Notes

- **Audio Settings:**  
  You MUST call `loadAudioSettings()` before joining the RTC channel to ensure optimal audio quality for AI conversation.
  ```kotlin
  api.loadAudioSettings()
  rtcEngine.joinChannel(token, channelName, null, userId)
  ```

- **Avatar Audio Settings:**
  If Avatar functionality is enabled, you must use the `Constants.AUDIO_SCENARIO_DEFAULT` audio scenario to achieve optimal audio mixing effects:
  ```kotlin
  // Correct audio settings when enabling Avatar
  api.loadAudioSettings(Constants.AUDIO_SCENARIO_DEFAULT)
  rtcEngine.joinChannel(token, channelName, null, userId)
  ```

  Audio setting recommendations for different scenarios:
    - **Avatar Mode**: `Constants.AUDIO_SCENARIO_DEFAULT` - Provides better audio mixing effects
    - **Standard Mode**: `Constants.AUDIO_SCENARIO_AI_CLIENT` - Suitable for standard AI conversation scenarios


- **All event callbacks are on the main thread.**  
  You can safely update UI in your event handlers.

- **Message Send Status Confirmation:**
    - The `chat` interface completion callback only indicates whether the send request was successful, not the actual message processing status
    - Actual successful image message sending is confirmed through the `onMessageReceiptUpdated` callback
    - Image message send failures are confirmed through the `onMessageError` callback
    - It's recommended to use the `chatMessageType` field for quick judgment, which provides better performance

- **Image Message Status Tracking:**
    - Directly check `chatMessageType == ChatMessageType.Image`
    - Confirm specific image send status by parsing the `uuid` field in JSON

---

## File/Folder Structure

- [IConversationalAIAPI.kt](./IConversationalAIAPI.kt) — API interface and all related data structures and enums
- [ConversationalAIAPIImpl.kt](./ConversationalAIAPIImpl.kt) — Main implementation of the ConversationalAI API logic
- [ConversationalAIUtils.kt](./ConversationalAIUtils.kt) — Utility functions and event handler management
- [subRender/](./subRender/) 
    - [v3/](./subRender/v3/) — transcript module
        - [TranscriptController.kt](./subRender/v3/TranscriptController.kt)
        - [MessageParser.kt](./subRender/v3/MessageParser.kt) 

> The above files and folders are all you need to integrate the ConversationalAI API. No other files are required.

---

## Feedback

- If you have any problems or suggestions regarding the sample projects, we welcome you to file an issue. 