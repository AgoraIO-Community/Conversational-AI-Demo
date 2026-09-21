# Web Toolkit integration

This Demo pins the public npm package `agora-agent-client-toolkit@2.10.0`. Toolkit maintains public APIs, agent state, transcripts, and metrics protocol parsing.

## Installation

Run `bun install --frozen-lockfile` in `Web/Scenes/VoiceAgent`. In your own application, install the package with:

```bash
npm install --save-exact agora-agent-client-toolkit@2.10.0
```

RTC SDK `>=4.23.4` is required. This Demo also uses an authenticated RTM client (`>=2.0.0`). Toolkit accepts RTC/RTM instances created by the application; the application owns audio capture, devices, and login.

## Initialization, events, and cleanup

In browser client code, create RTC and log in to RTM, then await Toolkit initialization. Register listeners and subscribe to the channel before starting the Agent. The application supplies `rtcClient`, `rtmClient`, and `channelName` below:

```typescript
import {
  ConversationalAIAPI,
  EConversationalAIAPIEvents,
  ETranscriptHelperMode
} from 'agora-agent-client-toolkit'

// rtcClient is already created; rtmClient is already logged in.
const api = await ConversationalAIAPI.init({
  rtcEngine: rtcClient,
  rtmEngine: rtmClient,
  renderMode: ETranscriptHelperMode.TEXT,
  enableLog: false
})

api.on(EConversationalAIAPIEvents.TRANSCRIPT_UPDATED, (history) => {
  console.log(history)
})
api.on(EConversationalAIAPIEvents.AGENT_STATE_CHANGED, (uid, event) => {
  console.log(uid, event.state)
})
api.on(EConversationalAIAPIEvents.AGENT_TURN_FINISHED, (uid, turn) => {
  console.log(uid, turn.turnId, turn.e2eLatencyMs, turn.segmentedLatency)
})
api.on(EConversationalAIAPIEvents.AGENT_METRICS, (uid, metric) => {
  console.log(uid, metric)
})
api.subscribeMessage(channelName)
```

Destroy Toolkit before disconnecting RTC/RTM. The following cleanup also handles failed initialization. Await a new `init(...)` when starting the next call:

```typescript
if (ConversationalAIAPI.getState()) {
  ConversationalAIAPI.getInstance().destroy()
}
// Disconnect and release your RTC/RTM clients after Toolkit is destroyed.
```

The Demo waits for both RTC and RTM cleanup to settle before restoring the call controls, even if one cleanup fails. While exiting, it blocks repeated hangup, redial, interrupt, microphone selection, and image upload. Agent startup failures use the same cleanup path.

The Agent API route retries once with `asr.keywords: null` only when the backend explicitly rejects `properties.asr.keywords`. Other failures are returned without retry.

To collect debug logs, enable `enableLog` and forward the `DEBUG_LOG` event to your application's logger.

## Responsibilities retained by the Demo

- `helper/rtc.ts` and `helper/rtm.ts`: initialization, login, audio capture, devices, and connection lifecycle.
- `helper/transcript.ts`: legacy subtitle compatibility; the current protocol uses Toolkit.
- `utils/event.ts` and `utils/index.ts`: event and log formatting utilities used by Demo helpers.
- `src/lib/latency-metrics.ts`: UI mapping and report assembly from parsed metrics. Toolkit parses the raw `turn.finished` protocol.
- On-device AINS: controlled by the Demo RTC layer, disabled by default, enabled only when developer mode and the AINS toggle are both on.

The helpers are coupled to Demo business logic. Use Toolkit's public API and manage RTC/RTM according to your application's requirements.

## Validation

`bun run test` exercises the actual npm Toolkit package for state, RTC/RTM transcripts, metrics, and destroy/reinitialize behavior with simulated transports. Also run `bun run typecheck` and `bun run build`. Validate audio behavior with real calls.

[Toolkit documentation](https://github.com/AgoraIO-Conversational-AI/agent-client-toolkit-ts#readme)

## Developer request overrides

Open `?dev=true` and select the developer badge to configure a custom App ID, a ConvoAI base URL, or `X-Service-Namespace`. The App ID only takes effect after its override switch is enabled; toggling the switch refreshes the page, and an active badge identifies the override. Settings persist locally. Exiting developer mode clears active overrides and keeps the App ID text for later use.

The same dev options accompany preset loading, token retrieval, Agent start/stop/ping, SIP start/status, and metrics reports. The server accepts query overrides only in developer mode. ConvoAI base URL and namespace settings are merged into `request_config.convoai`, preserving existing headers. Token generation continues through the configured environment's token endpoint with the effective App ID. RTC token caching follows the selected App ID and rejects stale prefetch results after a switch.
