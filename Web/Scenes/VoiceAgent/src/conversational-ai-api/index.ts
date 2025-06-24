import { IAgoraRTCClient } from 'agora-rtc-sdk-ng'
import { RTMClient, RTMEvents, ChannelType } from 'agora-rtm'

import { EventHelper } from '@/conversational-ai-api/utils/event'
import { CovSubRenderController } from '@/conversational-ai-api/utils/sub-render'
import {
  ESubtitleHelperMode,
  ERTMEvents,
  ERTCEvents,
  IConversationalAIAPIEventHandlers,
  EConversationalAIAPIEvents,
  NotFoundError,
  EAgentState,
  ISubtitleHelperItem,
  IUserTranscription,
  IAgentTranscription,
  TStateChangeEvent,
  EMessageType,
  TAgentMetric,
  TModuleError,
} from '@/conversational-ai-api/type'
import { factoryFormatLog } from '@/conversational-ai-api/utils'
import { logger, ELoggerType } from '@/lib/logger'
import { genTranceID } from '@/lib/utils'

const TAG = 'ConversationalAIAPI'
// const CONSOLE_LOG_PREFIX = `[${TAG}]`
const VERSION = '1.6.0'

const formatLog = factoryFormatLog({ tag: TAG })

export interface IConversationalAIAPIConfig {
  rtcEngine: IAgoraRTCClient
  rtmEngine: RTMClient
  renderMode?: ESubtitleHelperMode
  enableLog?: boolean
}

export class ConversationalAIAPI extends EventHelper<IConversationalAIAPIEventHandlers> {
  private static NAME = TAG
  private static VERSION = VERSION
  private static _instance: ConversationalAIAPI | null = null
  private callMessagePrint: (type: ELoggerType, ...args: unknown[]) => void

  protected rtcEngine: IAgoraRTCClient | null = null
  protected rtmEngine: RTMClient | null = null
  protected renderMode: ESubtitleHelperMode = ESubtitleHelperMode.UNKNOWN
  protected channel: string | null = null
  protected covSubRenderController: CovSubRenderController
  protected enableLog: boolean = false

  constructor() {
    super()

    this.callMessagePrint = (
      type: ELoggerType = ELoggerType.debug,
      ...args: unknown[]
    ) => {
      if (!this.enableLog) {
        return
      }
      logger[type](formatLog(...args))
      this.onDebugLog?.(`[${type}] ${formatLog(...args)}`)
    }
    this.callMessagePrint(
      ELoggerType.debug,
      `${ConversationalAIAPI.NAME} initialized, version: ${ConversationalAIAPI.VERSION}`
    )

    this.covSubRenderController = new CovSubRenderController({
      onChatHistoryUpdated: this.onChatHistoryUpdated.bind(this),
      onAgentStateChanged: this.onAgentStateChanged.bind(this),
      onAgentInterrupted: this.onAgentInterrupted.bind(this),
      onDebugLog: this.onDebugLog.bind(this),
      onAgentMetrics: this.onAgentMetrics.bind(this),
      onAgentError: this.onAgentError.bind(this),
    })
  }

  public static getInstance() {
    if (!this._instance) {
      throw new NotFoundError('ConversationalAIAPI is not initialized')
    }
    return this._instance
  }

  public getCfg() {
    if (!this.rtcEngine || !this.rtmEngine) {
      throw new NotFoundError('ConversationalAIAPI is not initialized')
    }
    return {
      rtcEngine: this.rtcEngine,
      rtmEngine: this.rtmEngine,
      renderMode: this.renderMode,
      channel: this.channel,
      enableLog: this.enableLog,
    }
  }

  public static init(cfg: IConversationalAIAPIConfig) {
    this._instance = new ConversationalAIAPI()
    this._instance.rtcEngine = cfg.rtcEngine
    this._instance.rtmEngine = cfg.rtmEngine
    this._instance.renderMode = cfg.renderMode ?? ESubtitleHelperMode.UNKNOWN
    this._instance.enableLog = cfg.enableLog ?? false

    return this._instance
  }

  public subscribeMessage(channel: string) {
    this.bindRtcEvents()
    this.bindRtmEvents()

    this.channel = channel
    this.covSubRenderController.setMode(this.renderMode)
    this.covSubRenderController.run()
  }

  public unsubscribe() {
    this.unbindRtcEvents()
    this.unbindRtmEvents()

    this.channel = null
    this.covSubRenderController.cleanup()
  }

  public destroy() {
    const instance = ConversationalAIAPI.getInstance()
    if (instance) {
      instance.rtcEngine = null
      instance.rtmEngine = null
      instance.renderMode = ESubtitleHelperMode.UNKNOWN
      instance.channel = null
      ConversationalAIAPI._instance = null
    }
    this.callMessagePrint(
      ELoggerType.debug,
      `${ConversationalAIAPI.NAME} destroyed`
    )
  }

  // TODO: Implement chat method
  // public chat() {}

  public async interrupt(agentUserId: string) {
    const traceId = genTranceID()
    this.callMessagePrint(
      ELoggerType.debug,
      `>>> [trancID:${traceId}] [interrupt]`,
      agentUserId
    )

    const { rtmEngine } = this.getCfg()

    const options = {
      channelType: 'USER' as ChannelType,
      customType: EMessageType.MSG_INTERRUPTED,
    }
    const messageStr = JSON.stringify({
      customType: EMessageType.MSG_INTERRUPTED,
    })

    try {
      const result = await rtmEngine.publish(agentUserId, messageStr, options)
      this.callMessagePrint(
        ELoggerType.debug,
        `>>> [trancID:${traceId}] [interrupt]`,
        'sucessfully sent interrupt message',
        result
      )
    } catch (error: unknown) {
      this.callMessagePrint(
        ELoggerType.error,
        `>>> [trancID:${traceId}] [interrupt]`,
        'failed to send interrupt message',
        error
      )
      throw new Error('failed to send interrupt message')
    }
  }

  private onChatHistoryUpdated(
    chatHistory: ISubtitleHelperItem<
      Partial<IUserTranscription | IAgentTranscription>
    >[]
  ) {
    this.callMessagePrint(
      ELoggerType.debug,
      `>>> ${EConversationalAIAPIEvents.TRANSCRIPTION_UPDATED}`,
      chatHistory
    )
    this.emit(EConversationalAIAPIEvents.TRANSCRIPTION_UPDATED, chatHistory)
  }
  private onAgentStateChanged(agentUserId: string, event: TStateChangeEvent) {
    this.callMessagePrint(
      ELoggerType.debug,
      `>>> ${EConversationalAIAPIEvents.AGENT_STATE_CHANGED}`,
      agentUserId,
      event
    )
    this.emit(
      EConversationalAIAPIEvents.AGENT_STATE_CHANGED,
      agentUserId,
      event
    )
  }
  private onAgentInterrupted(
    agentUserId: string,
    event: { turnID: number; timestamp: number }
  ) {
    this.callMessagePrint(
      ELoggerType.debug,
      `>>> ${EConversationalAIAPIEvents.AGENT_INTERRUPTED}`,
      agentUserId,
      event
    )
    this.emit(EConversationalAIAPIEvents.AGENT_INTERRUPTED, agentUserId, event)
  }
  private onDebugLog(message: string) {
    this.emit(EConversationalAIAPIEvents.DEBUG_LOG, message)
  }
  private onAgentMetrics(agentUserId: string, metrics: TAgentMetric) {
    this.callMessagePrint(
      ELoggerType.debug,
      `>>> ${EConversationalAIAPIEvents.AGENT_METRICS}`,
      agentUserId,
      metrics
    )
    this.emit(EConversationalAIAPIEvents.AGENT_METRICS, agentUserId, metrics)
  }
  private onAgentError(agentUserId: string, error: TModuleError) {
    this.callMessagePrint(
      ELoggerType.error,
      `>>> ${EConversationalAIAPIEvents.AGENT_ERROR}`,
      agentUserId,
      error
    )
    this.emit(EConversationalAIAPIEvents.AGENT_ERROR, agentUserId, error)
  }

  private bindRtcEvents() {
    this.getCfg().rtcEngine.on(
      ERTCEvents.AUDIO_METADATA,
      this._handleRtcAudioMetadata.bind(this)
    )
  }
  private unbindRtcEvents() {
    this.getCfg().rtcEngine.off(
      ERTCEvents.AUDIO_METADATA,
      this._handleRtcAudioMetadata.bind(this)
    )
  }
  private bindRtmEvents() {
    // - message
    this.getCfg().rtmEngine.addEventListener(
      ERTMEvents.MESSAGE,
      this._handleRtmMessage.bind(this)
    )
    // - presence
    this.getCfg().rtmEngine.addEventListener(
      ERTMEvents.PRESENCE,
      this._handleRtmPresence.bind(this)
    )
    // - status
    this.getCfg().rtmEngine.addEventListener(
      ERTMEvents.STATUS,
      this._handleRtmStatus.bind(this)
    )
  }
  private unbindRtmEvents() {
    // - message
    this.getCfg().rtmEngine.removeEventListener(
      ERTMEvents.MESSAGE,
      this._handleRtmMessage.bind(this)
    )
    // - presence
    this.getCfg().rtmEngine.removeEventListener(
      ERTMEvents.PRESENCE,
      this._handleRtmPresence.bind(this)
    )
    // - status
    this.getCfg().rtmEngine.removeEventListener(
      ERTMEvents.STATUS,
      this._handleRtmStatus.bind(this)
    )
  }

  private _handleRtcAudioMetadata(metadata: Uint8Array) {
    try {
      const pts64 = Number(new DataView(metadata.buffer).getBigUint64(0, true))
      this.callMessagePrint(
        ELoggerType.debug,
        `<<<< ${ERTCEvents.AUDIO_METADATA}`,
        pts64
      )
      this.covSubRenderController.setPts(pts64)
    } catch (error) {
      this.callMessagePrint(
        ELoggerType.error,
        `<<<< ${ERTCEvents.AUDIO_METADATA}`,
        metadata,
        error
      )
    }
  }

  private _handleRtmMessage(message: RTMEvents.MessageEvent) {
    const traceId = genTranceID()
    this.callMessagePrint(
      ELoggerType.debug,
      `>>> [trancID:${traceId}] ${ERTMEvents.MESSAGE}`,
      `Publisher: ${message.publisher}, type: ${message.messageType}`
    )
    // Handle the message
    try {
      const messageData = message.message
      // if string, parse it
      if (typeof messageData === 'string') {
        const parsedMessage = JSON.parse(messageData)
        this.callMessagePrint(
          ELoggerType.debug,
          `>>> [trancID:${traceId}] ${ERTMEvents.MESSAGE}`,
          parsedMessage
        )
        this.covSubRenderController.handleMessage(parsedMessage, {
          publisher: message.publisher,
        })
        return
      }
      // if Uint8Array, convert to string
      if (messageData instanceof Uint8Array) {
        const decoder = new TextDecoder('utf-8')
        const messageString = decoder.decode(messageData)
        const parsedMessage = JSON.parse(messageString)
        this.callMessagePrint(
          ELoggerType.debug,
          `>>> [trancID:${traceId}] ${ERTMEvents.MESSAGE}`,
          parsedMessage
        )
        this.covSubRenderController.handleMessage(parsedMessage, {
          publisher: message.publisher,
        })
        return
      }
      this.callMessagePrint(
        ELoggerType.warn,
        `>>> [trancID:${traceId}] ${ERTMEvents.MESSAGE}`,
        'Unsupported message type received'
      )
    } catch (error) {
      this.callMessagePrint(
        ELoggerType.error,
        `>>> [trancID:${traceId}] ${ERTMEvents.MESSAGE}`,
        'Failed to parse message',
        error
      )
    }
  }
  private _handleRtmPresence(presence: RTMEvents.PresenceEvent) {
    const traceId = genTranceID()
    this.callMessagePrint(
      ELoggerType.debug,
      `>>> [trancID:${traceId}] ${ERTMEvents.PRESENCE}`,
      `Publisher: ${presence.publisher}`
    )
    // Handle the presence event
    const stateChanged = presence.stateChanged
    if (stateChanged?.state && stateChanged?.turn_id) {
      this.callMessagePrint(
        ELoggerType.debug,
        `>>> [trancID:${traceId}] ${ERTMEvents.PRESENCE}`,
        `State changed: ${stateChanged.state}, Turn ID: ${stateChanged.turn_id}, timestamp: ${presence.timestamp}`
      )
      this.covSubRenderController.handleAgentStatus(
        presence as Omit<RTMEvents.PresenceEvent, 'stateChanged'> & {
          stateChanged: {
            state: EAgentState
            turn_id: string
          }
        }
      )
    }
    this.callMessagePrint(
      ELoggerType.debug,
      `>>> [trancID:${traceId}] ${ERTMEvents.PRESENCE}`,
      'No state change detected, skipping handling presence event'
    )
  }
  private _handleRtmStatus(
    status:
      | RTMEvents.RTMConnectionStatusChangeEvent
      | RTMEvents.StreamChannelConnectionStatusChangeEvent
  ) {
    const traceId = genTranceID()
    this.callMessagePrint(
      ELoggerType.debug,
      `>>> [trancID:${traceId}] ${ERTMEvents.STATUS}`,
      status
    )
  }
}
