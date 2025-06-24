import { RTMEvents } from 'agora-rtm'
import {
  IMicrophoneAudioTrack,
  UID,
  type NetworkQuality,
  type IAgoraRTCRemoteUser,
  type ConnectionState,
  ICameraVideoTrack,
  type ConnectionDisconnectedReason,
} from 'agora-rtc-sdk-ng'

export enum ESubtitleHelperMode {
  TEXT = 'text',
  WORD = 'word',
  UNKNOWN = 'unknown',
}

export enum EMessageType {
  USER_TRANSCRIPTION = 'user.transcription',
  AGENT_TRANSCRIPTION = 'assistant.transcription',
  MSG_INTERRUPTED = 'message.interrupt',
  MSG_METRICS = 'message.metrics',
  MSG_ERROR = 'message.error',
  /** @deprecated */
  MSG_STATE = 'message.state',
}

export enum ERTMEvents {
  MESSAGE = 'message',
  PRESENCE = 'presence',
  // TOPIC = 'topic',
  // STORAGE = 'storage',
  // LOCK = 'lock',
  STATUS = 'status',
  // LINK_STATE = 'linkState',
  // TOKEN_PRIVILEGE_WILL_EXPIRE = 'tokenPrivilegeWillExpire',
}

export enum ERTCEvents {
  NETWORK_QUALITY = 'network-quality',
  USER_PUBLISHED = 'user-published',
  USER_UNPUBLISHED = 'user-unpublished',
  STREAM_MESSAGE = 'stream-message',
  USER_JOINED = 'user-joined',
  USER_LEFT = 'user-left',
  CONNECTION_STATE_CHANGE = 'connection-state-change',
  AUDIO_METADATA = 'audio-metadata',
}

export enum ERTCCustomEvents {
  MICROPHONE_CHANGED = 'microphone-changed',
  REMOTE_USER_CHANGED = 'remote-user-changed',
  REMOTE_USER_JOINED = 'remote-user-joined',
  REMOTE_USER_LEFT = 'remote-user-left',
  LOCAL_TRACKS_CHANGED = 'local-tracks-changed',
}

export enum EConversationalAIAPIEvents {
  AGENT_STATE_CHANGED = 'agent-state-changed',
  AGENT_INTERRUPTED = 'agent-interrupted',
  AGENT_METRICS = 'agent-metrics',
  AGENT_ERROR = 'agent-error',
  TRANSCRIPTION_UPDATED = 'transcription-updated',
  DEBUG_LOG = 'debug-log',
}

export enum EModuleType {
  LLM = 'llm',
  MLLM = 'mllm',
  TTS = 'tts',
  UNKNOWN = 'unknown',
}

export type TAgentMetric = {
  type: EModuleType
  name: string
  value: number
  timestamp: number
}

export type TModuleError = {
  type: EModuleType
  code: number
  message: string
  timestamp: number
}

export type TStateChangeEvent = {
  state: EAgentState
  turnID: number
  timestamp: number
  reason: string
}

export interface IConversationalAIAPIEventHandlers {
  [EConversationalAIAPIEvents.AGENT_STATE_CHANGED]: (
    agentUserId: string,
    event: TStateChangeEvent
  ) => void
  [EConversationalAIAPIEvents.AGENT_INTERRUPTED]: (
    agentUserId: string,
    event: {
      turnID: number
      timestamp: number
    }
  ) => void
  [EConversationalAIAPIEvents.AGENT_METRICS]: (
    agentUserId: string,
    metrics: TAgentMetric
  ) => void
  [EConversationalAIAPIEvents.AGENT_ERROR]: (
    agentUserId: string,
    error: TModuleError
  ) => void
  [EConversationalAIAPIEvents.TRANSCRIPTION_UPDATED]: (
    transcription: ISubtitleHelperItem<
      Partial<IUserTranscription | IAgentTranscription>
    >[]
  ) => void
  [EConversationalAIAPIEvents.DEBUG_LOG]: (message: string) => void
}

// export interface IHelperRTMEvents {
//   [ERTMEvents.MESSAGE]: (message: RTMEvents.MessageEvent) => void
//   [ERTMEvents.PRESENCE]: (message: RTMEvents.PresenceEvent) => void
//   [ERTMEvents.STATUS]: (
//     message: RTMEvents.RTMConnectionStatusChangeEvent
//   ) => void
// }

export interface IHelperRTCEvents {
  [ERTCEvents.NETWORK_QUALITY]: (quality: NetworkQuality) => void
  [ERTCEvents.USER_PUBLISHED]: (
    user: IAgoraRTCRemoteUser,
    mediaType: 'audio' | 'video'
  ) => void
  [ERTCEvents.USER_UNPUBLISHED]: (
    user: IAgoraRTCRemoteUser,
    mediaType: 'audio' | 'video'
  ) => void
  [ERTCEvents.USER_JOINED]: (user: IAgoraRTCRemoteUser) => void
  [ERTCEvents.USER_LEFT]: (user: IAgoraRTCRemoteUser, reason?: string) => void
  [ERTCEvents.CONNECTION_STATE_CHANGE]: (data: {
    curState: ConnectionState
    revState: ConnectionState
    reason?: ConnectionDisconnectedReason
    channel: string
  }) => void
  [ERTCEvents.AUDIO_METADATA]: (metadata: Uint8Array) => void
  [ERTCEvents.STREAM_MESSAGE]: (uid: UID, stream: Uint8Array) => void
}

export class NotFoundError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'NotFoundError'
  }
}

// --- Message ---
export type TDataChunkMessageWord = {
  word: string
  start_ms: number
  duration_ms: number
  stable: boolean
}

export type TSubtitleHelperObjectWord = TDataChunkMessageWord & {
  word_status?: ETurnStatus
}

export enum ETurnStatus {
  IN_PROGRESS = 0,
  END = 1,
  INTERRUPTED = 2,
}

export enum EAgentState {
  IDLE = 'idle',
  LISTENING = 'listening',
  THINKING = 'thinking',
  SPEAKING = 'speaking',
  SILENT = 'silent',
}

export interface ITranscriptionBase {
  object: EMessageType
  text: string
  start_ms: number
  duration_ms: number
  language: string
  turn_id: number
  stream_id: number
  user_id: string
  words: TDataChunkMessageWord[] | null
}

export interface IUserTranscription extends ITranscriptionBase {
  object: EMessageType.USER_TRANSCRIPTION // "user.transcription"
  final: boolean
}

export interface IAgentTranscription extends ITranscriptionBase {
  object: EMessageType.AGENT_TRANSCRIPTION // "assistant.transcription"
  quiet: boolean
  turn_seq_id: number
  turn_status: ETurnStatus
}

export interface IMessageInterrupt {
  object: EMessageType.MSG_INTERRUPTED // "message.interrupt"
  message_id: string
  data_type: 'message'
  turn_id: number
  start_ms: number
  send_ts: number
}

export interface IMessageMetrics {
  object: EMessageType.MSG_METRICS // "message.metrics"
  module: EModuleType
  metric_name: string
  turn_id: number
  latency_ms: number
  send_ts: number // TODO: check if this is correct
}

export interface IMessageError {
  object: EMessageType.MSG_ERROR // "message.error"
  module: EModuleType
  code: number
  message: string
  turn_id: number
  timestamp: number // TODO: check if this is correct
}

export interface IPresenceState
  extends Omit<RTMEvents.PresenceEvent, 'stateChanged'> {
  stateChanged: {
    state: EAgentState
    turn_id: string
  }
}

export type TQueueItem = {
  turn_id: number
  text: string
  words: TSubtitleHelperObjectWord[]
  status: ETurnStatus
  stream_id: number
  uid: string
}

export interface ISubtitleHelperItem<T> {
  uid: string
  stream_id: number
  turn_id: number
  _time: number
  text: string
  status: ETurnStatus
  metadata: T | null
}

// --- rtc ---
export interface IUserTracks {
  videoTrack?: ICameraVideoTrack
  audioTrack?: IMicrophoneAudioTrack
}
