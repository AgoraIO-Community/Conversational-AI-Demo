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
       override fun onMessageReceiptUpdated(agentUserId: String, receipt: MessageReceipt) { /* ... */ }
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

6. **(Optional) Send image messages**

   ```kotlin
   val uuid = "unique-image-id-123" // Generate unique image identifier
   val imageUrl = "https://example.com/image.jpg" // Image HTTP/HTTPS URL
   
   api.sendImage("agentUserId", uuid, imageUrl) { error ->
       if (error != null) {
           // Handle send error
           Log.e("ImageSend", "Failed to send image: ${error.errorMessage}")
       } else {
           // Send request successful, waiting for receipt confirmation
           Log.d("ImageSend", "Image send request successful")
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

## Sending Image Messages

### Send Images

Use the `sendImage` interface to send image messages to AI agent:

```kotlin
val uuid = "unique-image-id-123" // Generate unique image identifier
val imageUrl = "https://example.com/image.jpg" // Image HTTP/HTTPS URL

api.sendImage("agentUserId", uuid, imageUrl) { error ->
    if (error != null) {
        // Handle send error
        Log.e("ImageSend", "Failed to send image: ${error.errorMessage}")
    } else {
        // Send request successful, waiting for receipt confirmation
        Log.d("ImageSend", "Image send request successful")
    }
}
```

### Handle Image Send Status

The actual success or failure status of image sending is confirmed through the following two callbacks:

#### 1. Image Send Success - onMessageReceiptUpdated

When receiving the `onMessageReceiptUpdated` callback, follow these steps to parse and confirm the image send status:

**Important: You must first check if `receipt.type` is `ModuleType.Context`, then check `resource_type`**

```kotlin
override fun onMessageReceiptUpdated(agentUserId: String, receipt: MessageReceipt) {
    // Step 1: Check if message type is Context
    if (receipt.type == ModuleType.Context) {
        try {
            // Step 2: Parse receipt.message as JSON object
            val jsonObject = JSONObject(receipt.message)
            
            // Step 3: Check if resource_type is picture
            if (jsonObject.has("resource_type") && 
                jsonObject.getString("resource_type") == "picture") {
                
                // Step 4: Check if uuid field is included
                if (jsonObject.has("uuid")) {
                    val receivedUuid = jsonObject.getString("uuid")
                    
                    // If uuid matches, this image was sent successfully
                    if (receivedUuid == "your-sent-uuid") {
                        Log.d("ImageSend", "Image sent successfully: $receivedUuid")
                        // Update UI to show send success status
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("ImageSend", "Failed to parse message receipt: ${e.message}")
        }
    }
}
```

#### 2. Image Send Failure - onAgentError

When receiving the `onAgentError` callback and `error.type` is `ModuleType.Context`, parse `error.message` to confirm image send failure:

```kotlin
override fun onAgentError(agentUserId: String, error: ModuleError) {
    // Check if it's a Context type error
    if (error.type == ModuleType.Context) {
        try {
            // Parse error.message as JSON object
            val jsonObject = JSONObject(error.message)
            
            // Check if resource_type is picture
            if (jsonObject.has("resource_type") && 
                jsonObject.getString("resource_type") == "picture") {
                
                // Check if uuid field is included
                if (jsonObject.has("uuid")) {
                    val failedUuid = jsonObject.getString("uuid")
                    
                    // If uuid matches, this image send failed
                    if (failedUuid == "your-sent-uuid") {
                        Log.e("ImageSend", "Image send failed: $failedUuid")
                        // Update UI to show send failure status
                    }
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

- **All event callbacks are on the main thread.**  
  You can safely update UI in your event handlers.

- **Image Send Status Confirmation:**
    - The completion callback of `sendImage` interface only indicates whether the send request was successful, not the actual image send status
    - Actual send success is confirmed through the `onMessageReceiptUpdated` callback
    - Actual send failure is confirmed through the `onAgentError` callback
    - You need to parse the JSON message in the callback to get specific uuid and status information

- **Image Message Parsing Steps:**
    - **Success Callback**: You must first check `receipt.type == ModuleType.Context`, then check `resource_type == "picture"`
    - **Failure Callback**: You must first check `error.type == ModuleType.Context`, then check `resource_type == "picture"`
    - Only after meeting the above conditions can you confirm the specific image send status through the `uuid` field

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