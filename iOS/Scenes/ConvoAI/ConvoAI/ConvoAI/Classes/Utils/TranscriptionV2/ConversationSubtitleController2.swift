//
//  CovSubRenderController.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/18.
//

import Foundation
import AgoraRtcKit

private struct TranscriptionMessage2: Codable {
    let data_type: String?
    let stream_id: Int?
    let text: String?
    let message_id: String?
    let quiet: Bool?
    let final: Bool?
    let is_final: Bool?
    let object: String?
    let turn_id: Int?
    let turn_seq_id: Int?
    let turn_status: Int?
    let language: String?
    let user_id: String?
    let words: [Word]?
    let duration_ms: Int64?
    let start_ms: Int64?
    let latency_ms: Int?
    let send_ts: Int64?
    let module: String?
    let metric_name: String?
    let state: String?
    
    func description() -> String {
        var dict: [String: Any] = [:]
        
        if let data_type = data_type { dict["data_type"] = data_type }
        if let stream_id = stream_id { dict["stream_id"] = stream_id }
        if let text = text { dict["text"] = text }
        if let message_id = message_id { dict["message_id"] = message_id }
        if let quiet = quiet { dict["quiet"] = quiet }
        if let final = final { dict["final"] = final }
        if let is_final = is_final { dict["is_final"] = is_final }
        if let object = object { dict["object"] = object }
        if let turn_id = turn_id { dict["turn_id"] = turn_id }
        if let turn_seq_id = turn_seq_id { dict["turn_seq_id"] = turn_seq_id }
        if let turn_status = turn_status { dict["turn_status"] = turn_status }
        if let language = language { dict["language"] = language }
        if let user_id = user_id { dict["user_id"] = user_id }
        if let words = words { dict["words"] = words.map { $0.dict() } }
        if let duration_ms = duration_ms { dict["duration_ms"] = duration_ms }
        if let start_ms = start_ms { dict["start_ms"] = start_ms }
        if let latency_ms = latency_ms { dict["latency_ms"] = latency_ms }
        if let send_ts = send_ts { dict["send_ts"] = send_ts }
        if let module = module { dict["module"] = module }
        if let metric_name = metric_name { dict["metric_name"] = metric_name }
        if let state = state { dict["state"] = state }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }
}

private struct Word: Codable {
    let duration_ms: Int?
    let stable: Bool?
    let start_ms: Int64?
    let word: String?
    
    func dict() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let duration_ms = duration_ms { dict["duration_ms"] = duration_ms }
        if let stable = stable { dict["stable"] = stable }
        if let start_ms = start_ms { dict["start_ms"] = start_ms }
        if let word = word { dict["word"] = word }
        return dict
    }
}

private class TurnBuffer {
    var turnId = 0
    var text: String = ""
    var start_ms: Int64 = 0
    var words: [WordBuffer] = []
    var bufferState: SubtitleStatus2 = .inprogress
}

private struct WordBuffer {
    let text: String
    let start_ms: Int64
    var status: SubtitleStatus2 = .inprogress
}
/// Defines different modes for subtitle rendering
///
/// - Auto: auto detect mode
/// - Text: Full text subtitles are rendered
/// - Word: Word-by-word subtitles are rendered
@objc public enum SubtitleRenderMode2: Int {
    case words = 0
    case text = 1
}
/// Represents the current status of a subtitle
///
/// - Progress: Subtitle is still being generated or spoken
/// - End: Subtitle has completed normally
/// - Interrupted: Subtitle was interrupted before completion
@objc public enum SubtitleStatus2: Int {
    case inprogress = 0
    case end = 1
    case interrupt = 2
}

/// Message State
@objc public enum MessageState2: Int {
    case idle = 0
    case silent = 1      // AI is in idle state
    case listening = 2   // AI is receiving user voice input
    case thinking = 3    // AI is processing and understanding
    case speaking = 4    // AI is generating response
    
    init?(rawValue: String) {
        switch rawValue {
        case "idle": self = .idle
        case "silent": self = .silent
        case "listening": self = .listening
        case "thinking": self = .thinking
        case "speaking": self = .speaking
        default: return nil
        }
    }
}
private typealias TurnState = SubtitleStatus2
/// Consumer-facing data class representing a complete subtitle message
/// Used for rendering in the UI layer
///
/// - Parameters:
///   - turnId: Unique identifier for the conversation turn
///   - userId: User identifier associated with this subtitle
///   - text: The actual subtitle text content
///   - status: Current status of the subtitle
@objc public class SubtitleMessage2: NSObject {
    let turnId: Int
    let userId: UInt
    let text: String
    var status: SubtitleStatus2
    
    init(turnId: Int, userId: UInt, text: String, status: SubtitleStatus2) {
        self.turnId = turnId
        self.userId = userId
        self.text = text
        self.status = status
    }
}
/// Agent State Message
/// Used for rendering in the UI layer
///
/// - Parameters:
///   - turnId: Unique identifier for the conversation turn
///   - state: Current state of the agent
///   - timestamp: Timestamp of the message
@objc public class AgentStateMessage2: NSObject {
    let turnId: Int
    let state: MessageState2
    let timestamp: Int64
    let messageId: String
    
    init(turnId: Int, state: MessageState2, timestamp: Int64, messageId: String) {
        self.turnId = turnId
        self.state = state
        self.timestamp = timestamp
        self.messageId = messageId
    }
}
/// Interface for receiving subtitle update events
/// Implemented by UI components that need to display subtitles
@objc public protocol ConversationSubtitleDelegate2: AnyObject {
    /// Called when a subtitle is updated and needs to be displayed
    ///
    /// - Parameter subtitle: The updated subtitle message
    @objc func onSubtitleUpdated(subtitle: SubtitleMessage2)

    /// Called when the message state is updated
    ///
    /// - Parameter messageState: The updated message state
    @objc func onAgentStateChanged(stateMessage: AgentStateMessage2)
    
    @objc optional func onDebugLog(_ txt: String)
}
/// Configuration class for subtitle rendering
///
/// - Properties:
///   - rtcEngine: The RTC engine instance used for real-time communication
///   - renderMode: The mode of subtitle rendering (Auto, Text, or Word)
///   - callback: Callback interface for subtitle updates
@objc public class SubtitleRenderConfig2: NSObject {
    let rtcEngine: AgoraRtcEngineKit
    let renderMode: SubtitleRenderMode2
    weak var delegate: ConversationSubtitleDelegate2?
    
    @objc public init(rtcEngine: AgoraRtcEngineKit, renderMode: SubtitleRenderMode2, delegate: ConversationSubtitleDelegate2?) {
        self.rtcEngine = rtcEngine
        self.renderMode = renderMode
        self.delegate = delegate
    }
}

// MARK: - CovSubRenderController

/// Subtitle Rendering Controller
/// Manages the processing and rendering of subtitles in conversation
///
@objc public class ConversationSubtitleController2: NSObject {
    
    public static let version: String = "1.4.0"
    public static let localUserId: UInt = 0
    public static let remoteUserId: UInt = 99
    
    enum MessageType: String {
        case assistant = "assistant.transcription"
        case user = "user.transcription"
        case interrupt = "message.interrupt"
        case state = "message.state"
        case unknown = "unknown"
        case string = "string"
    }
    
    private let jsonEncoder = JSONEncoder()
    private var timer: Timer?
    private var audioTimestamp: Int64 = 0
    private lazy var messageParser: MessageParser = {
        let parser = MessageParser()
        parser.onDebugLog = { [weak self] tag, txt in
            self?.addLog("\(tag) \(txt)")
        }
        return parser
    }()
    
    private weak var delegate: ConversationSubtitleDelegate2?
    private var messageQueue: [TurnBuffer] = []
    private var renderMode: SubtitleRenderMode2? = nil
    
    private var lastMessage: SubtitleMessage2? = nil
    private var lastFinishMessage: SubtitleMessage2? = nil
    
    private var renderConfig: SubtitleRenderConfig2? = nil
    
    private var stateMessage: TranscriptionMessage2? = nil
    
    deinit {
        addLog("[CovSubRenderController] deinit: \(self)")
    }
    
    private func addLog(_ txt: String) {
        delegate?.onDebugLog?(txt)
    }
    
    private let queue = DispatchQueue(label: "com.voiceagent.messagequeue", attributes: .concurrent)
    
    private func inputStreamMessageData(data: Data) {
        guard let jsonData = messageParser.parseStreamMessage(data) else {
            return
        }
        do {
            let transcription = try JSONDecoder().decode(TranscriptionMessage2.self, from: jsonData)
            handleMessage(transcription)
            addLog("✅[CovSubRenderController] input: \(transcription.description())")
        } catch {
            let string = String(data: jsonData, encoding: .utf8) ?? ""
            addLog("⚠️[CovSubRenderController] input: Failed to parse JSON content \(string) error: \(error.localizedDescription)")
            return
        }
    }
    
    private func handleMessage(_ message: TranscriptionMessage2) {
        if message.object == MessageType.user.rawValue {
            let text = message.text ?? ""
            let subtitleMessage = SubtitleMessage2(turnId: message.turn_id ?? 0,
                                                  userId: ConversationSubtitleController2.localUserId,
                                                  text: text,
                                                  status: (message.final == true) ? .end : .inprogress)
            self.delegate?.onSubtitleUpdated(subtitle: subtitleMessage)
        } else if message.object == MessageType.state.rawValue {
            handleStateMessage(message)
        } else {
            let renderMode = getMessageMode(message)
            if renderMode == .words {
                handleWordsMessage(message)
            } else if renderMode == .text {
                handleTextMessage(message)
            }
        }
    }
    
    private func getMessageMode(_ message: TranscriptionMessage2) -> SubtitleRenderMode2? {
        if let mode = renderMode {
            return mode
        }
        let messageType = MessageType(rawValue: message.object ?? "string") ?? .unknown
        guard messageType == .string || messageType == .assistant else {
            return nil
        }
        if renderConfig?.renderMode == .words {
            if let words = message.words, !words.isEmpty {
                renderMode = .words
                timer?.invalidate()
                timer = nil
                timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
                addLog("✅[CovSubRenderController] render mode: words, version \(ConversationSubtitleController2.version), \(self)")
            } else {
                renderMode = .text
                timer?.invalidate()
                timer = nil
                addLog("✅[CovSubRenderController] render mode: text, version \(ConversationSubtitleController2.version), \(self)")
            }
        } else if (renderConfig?.renderMode == .text) {
            renderMode = .text
        }
        return renderMode
    }
    
    private func handleStateMessage(_ message: TranscriptionMessage2) {
        guard let turnId = message.turn_id,
              let messageId = message.message_id,
              let messageTS = message.send_ts
        else {
            return
        }
        if let currentState = self.stateMessage {
            guard let currentTurnId = currentState.turn_id,
                  let currentMessageId = currentState.message_id,
                  let currentTS = currentState.send_ts,
                  messageId != currentMessageId,
                  turnId >= currentTurnId,
                  messageTS > currentTS else {
                addLog("[CovSubRenderController] handleStateMessage return message: \(messageTS)")
                return
            }
        }
        self.stateMessage = message
        // call back state
        if let stateString = message.state,
           let state = MessageState2(rawValue: stateString) {
            addLog("[CovSubRenderController] handleStateMessage update \(stateString)")
            let stateMessage = AgentStateMessage2(turnId: turnId, state: state, timestamp: message.send_ts ?? 0, messageId: messageId)
            self.delegate?.onAgentStateChanged(stateMessage: stateMessage)
        }
    }
    
    private func handleTextMessage(_ message: TranscriptionMessage2) {
        guard let text = message.text, !text.isEmpty else {
            return
        }
        let messageState: SubtitleStatus2
        if let turnStatus = message.turn_status {
            var state = TurnState(rawValue: turnStatus) ?? .inprogress
            if state == .interrupt {
                state = .end
            }
            messageState = state
        } else {
            let isFinal = message.is_final ?? message.final ?? false
            messageState = isFinal ? .end : .inprogress
        }
        var userId: UInt
        if let messageObject = message.object {
            if messageObject == MessageType.user.rawValue {
                userId = ConversationSubtitleController2.localUserId
            } else {
                userId = ConversationSubtitleController2.remoteUserId
            }
        } else {
            if message.stream_id == 0 {
                userId = ConversationSubtitleController2.remoteUserId
            } else {
                userId = ConversationSubtitleController2.localUserId
            }
        }
        let turnId = message.turn_id ?? -1
        let subtitleMessage = SubtitleMessage2(turnId: turnId,
                                              userId: userId,
                                              text: text,
                                              status: messageState)
        self.delegate?.onSubtitleUpdated(subtitle: subtitleMessage)
        if userId == 0 {
            print("🙋🏻‍♀️[CovSubRenderController] send user text: \(text), state: \(messageState)")
        } else {
            print("🌍[CovSubRenderController] send agent text: \(text), state: \(messageState)")
        }
    }
    
    private func handleWordsMessage(_ message: TranscriptionMessage2) {
        queue.async(flags: .barrier) {
            // handle new agent message
            if message.object == MessageType.assistant.rawValue {
                if let lastFinishId = self.lastFinishMessage?.turnId,
                   lastFinishId >= (message.turn_id ?? 0) {
                    return
                }
                if let queueLastTurnId = self.messageQueue.last?.turnId,
                   queueLastTurnId > (message.turn_id ?? 0) {
                    return
                }
                guard let turnStatus = TurnState(rawValue: message.turn_status ?? 0) else {
                    return
                }
                print("🔔[CovSubRenderController] turn_id: \(message.turn_id ?? 0), status: \(turnStatus)")
                let curBuffer: TurnBuffer = self.messageQueue.first { $0.turnId == message.turn_id } ?? {
                    let newTurn = TurnBuffer()
                    newTurn.turnId = message.turn_id ?? 0
                    self.messageQueue.append(newTurn)
                    print("[CovSubRenderController] new turn")
                    return newTurn
                }()
                // if this message time is later than current buffer time, update buffer
                if let msgMS = message.start_ms,
                   msgMS >= curBuffer.start_ms
                {
                    curBuffer.start_ms = message.start_ms ?? 0
                    curBuffer.text = message.text ?? ""
                    print("[CovSubRenderController] update turn")
                }
                // update buffer
                if let words = message.words, !words.isEmpty
                {
                    let bufferWords = curBuffer.words
                    let uniqueWords = words.filter { newWord in
                        return !bufferWords.contains { firstWord in firstWord.start_ms == newWord.start_ms}
                    }
                    // if diffrent ms words received, add new words to buffer
                    if !uniqueWords.isEmpty
                    {
                        // if the last message is final sign, reset it
                        if var lastWord = bufferWords.last, (lastWord.status == .end)
                        {
                            lastWord.status = .inprogress
                            curBuffer.words.removeLast()
                            curBuffer.words.append(lastWord)
                        }
                        // add new words to buffer and resort
                        let addWords = uniqueWords.compactMap { word -> WordBuffer? in
                            guard let wordText = word.word, let startTime = word.start_ms else {
                                return nil
                            }
                            return WordBuffer(text: wordText,
                                           start_ms: startTime)
                        }
                        curBuffer.words.append(contentsOf: addWords)
                        // sort words by timestamp
                        curBuffer.words.sort { $0.start_ms < $1.start_ms }
                    }
                }
                // if the message state is end, sign last word finished
                if turnStatus == .end, var lastWord = curBuffer.words.last, lastWord.status != .end {
                    lastWord.status = .end
                    // sign last word
                    curBuffer.words.removeLast()
                    curBuffer.words.append(lastWord)
                    self.addLog("🔔[CovSubRenderController] add end sign turn: \(curBuffer.turnId) last word: \(lastWord.text)")
                }
            } else if (message.object == MessageType.interrupt.rawValue) {// handle interrupt
                if let interruptTime = message.start_ms,
                   let buffer: TurnBuffer = self.messageQueue.first(where: { $0.turnId == message.turn_id })
                {
                    print("🚧[CovSubRenderController] interrupt: \(buffer.turnId) after \(buffer.words.first(where: {$0.start_ms > interruptTime})?.text ?? "")")
                    for index in buffer.words.indices {
                        if buffer.words[index].start_ms > interruptTime {
                            buffer.words[index].status = .interrupt
                        }
                    }
                }
            }
        }
    }
    
    @objc func eventLoop() {
        queue.sync {
            guard self.messageQueue.isEmpty == false else {
                return
            }
            //message dequeue
            var interrupte = false
            for (index, buffer) in self.messageQueue.enumerated().reversed() {
                if interrupte {
                    self.messageQueue.remove(at: index)
                    self.addLog("🔔[CovSubRenderController] remove interrupte turn: \(buffer.turnId)")
                    continue
                }
                // if last turn is interrupte by this buffer
                if let lastMessage = lastMessage,
                   lastMessage.status == .inprogress,
                   buffer.turnId > lastMessage.turnId  {
                    // interrupte last turn
                    lastMessage.status = .interrupt
                    self.delegate?.onSubtitleUpdated(subtitle: lastMessage)
                    interrupte = true
                }
                // get turn sub range
                let inprogressSub = buffer.words.firstIndex(where: { $0.start_ms > audioTimestamp} )
                let interruptSub = buffer.words.firstIndex(where: { $0.status == .interrupt} )
                let endSub = buffer.words.firstIndex(where: { $0.status == .end} )
                self.addLog("🔔[CovSubRenderController] get min subrange turn: \(buffer.turnId) range \(buffer.words.count) audioTimestamp: \(audioTimestamp) inprogress: \(inprogressSub ?? -1) interrupt: \(interruptSub ?? -1) end: \(endSub ?? -1)")
                let minIndex = [inprogressSub, interruptSub, endSub].compactMap { $0 }.min()
                guard let minRange = minIndex else {
                    return
                }
                let currentWords = Array(buffer.words[0...minRange])
                self.addLog("🔔[CovSubRenderController] get minRange: \(minRange) words: \(buffer.words.count) current: \(currentWords.count)")
                // send turn with state
                var subtitleMessage: SubtitleMessage2
                if minRange == interruptSub {
                    subtitleMessage = SubtitleMessage2(turnId: buffer.turnId,
                                                      userId: ConversationSubtitleController2.remoteUserId,
                                                      text: currentWords.map { $0.text }.joined(),
                                                      status: .interrupt)
                    // remove finished turn
                    self.messageQueue.remove(at: index)
                    self.addLog("🔔[CovSubRenderController] remove signed interrupte turn: \(buffer.turnId)")
                    lastFinishMessage = subtitleMessage
                } else if minRange == endSub {
                    subtitleMessage = SubtitleMessage2(turnId: buffer.turnId,
                                                      userId: ConversationSubtitleController2.remoteUserId,
                                                      text: buffer.text,
                                                      status: .end)
                    // remove finished turn
                    self.messageQueue.remove(at: index)
                    self.addLog("🔔[CovSubRenderController] remove signed end turn: \(buffer.turnId)")
                    lastFinishMessage = subtitleMessage
                } else {
                    subtitleMessage = SubtitleMessage2(turnId: buffer.turnId,
                                                      userId: ConversationSubtitleController2.remoteUserId,
                                                      text: currentWords.map { $0.text }.joined(),
                                                      status: .inprogress)
                }
                print("📊 [CovSubRenderController] message flush turn: \(buffer.turnId) state: \(subtitleMessage.status)")
//                print("📊 [CovSubRenderController] turn: \(buffer.turnId) range \(buffer.words.count) Subrange: \(minRange) words: \(currentWords.map { $0.text }.joined())")
                if !subtitleMessage.text.isEmpty {
                    lastMessage = subtitleMessage
                    self.delegate?.onSubtitleUpdated(subtitle: subtitleMessage)
                }
            }
        }
    }
}
// MARK: - AgoraRtcEngineDelegate
extension ConversationSubtitleController2: AgoraRtcEngineDelegate {
    public func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        inputStreamMessageData(data: data)
    }
}

// MARK: - AgoraAudioFrameDelegate
extension ConversationSubtitleController2: AgoraAudioFrameDelegate {
    
    public func onPlaybackAudioFrame(beforeMixing frame: AgoraAudioFrame, channelId: String, uid: UInt) -> Bool {
        audioTimestamp = frame.presentationMs+20
        return true
    }
    
    public func getObservedAudioFramePosition() -> AgoraAudioFramePosition {
        return .beforeMixing
    }
}
// MARK: - CovSubRenderControllerProtocol
extension ConversationSubtitleController2 {
    
    @objc public func setupWithConfig(_ config: SubtitleRenderConfig2) {
        renderConfig = config
        self.delegate = config.delegate
        config.rtcEngine.setAudioFrameDelegate(self)
        config.rtcEngine.addDelegate(self)
        config.rtcEngine.setPlaybackAudioFrameBeforeMixingParametersWithSampleRate(44100, channel: 1)
        addLog("[CovSubRenderController] setupWithConfig: \(self)")
    }
        
    @objc public func reset() {
        timer?.invalidate()
        timer = nil
        renderMode = nil
        lastMessage = nil
        lastFinishMessage = nil
        stateMessage = nil
        audioTimestamp = 0
        messageQueue.removeAll()
    }
}
