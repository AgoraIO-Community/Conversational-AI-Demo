import type { RTMEvents } from 'agora-rtm'
import type {
  IMicrophoneAudioTrack,
  UID,
  NetworkQuality,
  IAgoraRTCRemoteUser,
  ConnectionState,
  ICameraVideoTrack,
  ConnectionDisconnectedReason,
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


/**
 * Event handlers interface for the Conversational AI API module.
 * 会话 AI API 模块的事件处理器接口。
 * 
 * @since 1.0.0
 * 
 * Defines a set of event handlers that can be implemented to respond to various
 * events emitted by the Conversational AI system, including agent state changes,
 * interruptions, metrics, errors, and transcription updates.
 * 定义了一组事件处理器，用于响应会话 AI 系统发出的各种事件，包括代理状态变化、
 * 中断、指标、错误和转录更新。
 * 
 * @remarks
 * - All handlers are required to be implemented when using this interface
 *   使用此接口时必须实现所有处理器
 * - Events are emitted asynchronously and should be handled accordingly
 *   事件异步发出，应相应处理
 * - Event handlers should be lightweight to avoid blocking the event loop
 *   事件处理器应该轻量化以避免阻塞事件循环
 * - Error handling should be implemented within each handler to prevent crashes
 *   每个处理器内部都应实现错误处理以防崩溃
 * 
 * @example
 * ```typescript
 * const handlers: IConversationalAIAPIEventHandlers = {
 *   [EConversationalAIAPIEvents.AGENT_STATE_CHANGED]: (agentUserId, event) => {
 *     console.log(`Agent ${agentUserId} state changed:`, event);
 *   },
 *   // ... implement other handlers
 * };
 * ```
 * 
 * @param agentUserId - The unique identifier of the AI agent / AI 代理的唯一标识符
 * @param event - Event data specific to each event type / 每种事件类型的具体事件数据
 * @param metrics - Performance metrics data for the agent / 代理的性能指标数据
 * @param error - Error information when agent encounters issues / 代理遇到问题时的错误信息
 * @param transcription - Array of transcription items containing user and agent dialogue / 包含用户和代理对话的转录项数组
 * @param message - Debug log message string / 调试日志消息字符串
 * 
 * @see {@link EConversationalAIAPIEvents} for all available event types / 查看所有可用事件类型
 * @see {@link TStateChangeEvent} for state change event structure / 查看状态变更事件结构
 * @see {@link TAgentMetric} for agent metrics structure / 查看代理指标结构
 * @see {@link TModuleError} for error structure / 查看错误结构
 * @see {@link ISubtitleHelperItem} for transcription item structure / 查看转录项结构
 */
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
