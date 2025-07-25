//
//  TranscriptionController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/6/10.
//

import Foundation
import AgoraRtcKit
import AgoraRtmKit

private struct TranscriptionMessage: Codable {
    let data_type: String?
    var publish_id: String?
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
        if let publish_id = publish_id { dict["publish_id"] = publish_id }
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

private class TurnMessageInfo {
    var agentUserId:String = "-1"
    var turnId = 0
    var userId: String = "0"
    var text: String = ""
    var start_ms: Int64 = 0
    var words: [TurnWordInfo] = []
    var bufferState: TranscriptionStatus = .inprogress
}

private struct TurnWordInfo {
    let text: String
    let start_ms: Int64
    var status: TranscriptionStatus = .inprogress
}

/// Interface for receiving transcription update events
/// Implemented by UI components that need to display transcriptions
protocol TranscriptionDelegate: AnyObject {
    /// Called when a transcription is updated and needs to be displayed
    ///
    /// - Parameter transcription: The updated transcription message
    func onTranscriptionUpdated(agentUserId: String, transcription: Transcription)
    
    func onInterrupted(agentUserId: String, event: InterruptEvent)
    
    func onDebugLog(_ txt: String)
}

extension TranscriptionDelegate {
    func onTranscriptionUpdated(agentUserId: String, transcription: Transcription) {}
    func onInterrupted(agentUserId: String, event: InterruptEvent) {}
    func onDebugLog(_ txt: String) {}
}

/// Configuration class for transcription rendering
///
/// - Properties:
///   - rtcEngine: The RTC engine instance used for real-time communication
///   - renderMode: The mode of transcription rendering (Auto, Text, or Word)
///   - callback: Callback interface for transcription updates
@objc public class TranscriptionRenderConfig: NSObject {
    weak var rtcEngine: AgoraRtcEngineKit?
    weak var rtmEngine: AgoraRtmClientKit?
    weak var delegate: TranscriptionDelegate?
    let renderMode: TranscriptionRenderMode

    init(rtcEngine: AgoraRtcEngineKit, rtmEngine: AgoraRtmClientKit, renderMode: TranscriptionRenderMode, delegate: TranscriptionDelegate?) {
        self.rtmEngine = rtmEngine
        self.rtcEngine = rtcEngine
        self.renderMode = renderMode
        self.delegate = delegate
    }
}

// MARK: - CovSubRenderController

/// transcription Rendering Controller
/// Manages the processing and rendering of transcriptions in conversation
///
@objc public class TranscriptionController: NSObject {
    public static let version: String = "1.4.0"
    static let tag = "[Transcription]"
    static let uiTag = "[Transcription-UI]"


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
    private var traceId: String {
        get {
            return "\(UUID().uuidString.prefix(8))"
        }
    }
    
    private weak var delegate: TranscriptionDelegate?
    private var messageQueue: [TurnMessageInfo] = []
    private var renderMode: TranscriptionRenderMode? = nil
    
    private var lastMessage: Transcription? = nil
    private var lastPublish: String? = nil
    private var lastFinishMessage: Transcription? = nil
    
    private var renderConfig: TranscriptionRenderConfig? = nil
    
    private var stateMessage: TranscriptionMessage? = nil
    
    deinit {
        callMessagePrint(tag: TranscriptionController.tag, msg: "deinit: \(self)")
    }
    
    func callMessagePrint(tag: String, msg: String) {
        print("\(tag) \(msg)")
        delegate?.onDebugLog("\(tag) \(msg)")
    }
    
    private let queue = DispatchQueue(label: "com.voiceagent.messagequeue", attributes: .concurrent)
    
    private func handleMessage(_ message: TranscriptionMessage) {
        if message.object == MessageType.user.rawValue {
            let text = message.text ?? ""
            let userId = message.user_id ?? "0"
            let turnId = message.turn_id ?? 0
            let transcriptionMessage = Transcription(turnId: turnId,
                                                     userId: userId,
                                                  text: text,
                                                     status: (message.final == true) ? .end : .inprogress, type: .user)
            let agentUserId = message.publish_id ?? "-1"
            callMessagePrint(tag: TranscriptionController.uiTag, msg: "<<< [user message] pts: \(audioTimestamp), \(transcriptionMessage), publisher:\(agentUserId)")

            self.delegate?.onTranscriptionUpdated(agentUserId: agentUserId, transcription: transcriptionMessage)
        } else {
            let renderMode = getMessageMode(message)
            if renderMode == .words {
                handleWordsMessage(message)
            } else if renderMode == .text && message.turn_status != TranscriptionStatus.interrupted.rawValue {
                handleTextMessage(message)
            }
        }
    }
    
    private func getMessageMode(_ message: TranscriptionMessage) -> TranscriptionRenderMode? {
        if let mode = renderMode {
            return mode
        }
        let messageType = MessageType(rawValue: message.object ?? "string") ?? .unknown
        guard messageType == .string || messageType == .assistant else {
            return nil
        }
        if renderConfig?.renderMode == .words {
            if let words = message.words, !words.isEmpty {
                //TODO:
                renderMode = .words
                timer?.invalidate()
                timer = nil
                timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
            } else {
                renderMode = .text
                timer?.invalidate()
                timer = nil
            }
        } else if (renderConfig?.renderMode == .text) {
            renderMode = .text
        }
        callMessagePrint(tag: TranscriptionController.tag, msg: "\(self) version \(TranscriptionController.version) renderMode: \(renderMode?.rawValue ?? -1), publisher:\(message.publish_id ?? "-1")")

        return renderMode
    }
    
    private func handleTextMessage(_ message: TranscriptionMessage) {
        guard let text = message.text, !text.isEmpty else {
            callMessagePrint(tag: TranscriptionController.tag, msg: "<<< [Text Mode] text is nil")
            return
        }
        var messageState: TranscriptionStatus = .inprogress
        if let turnStatus = message.turn_status {
            var state = TranscriptionStatus(rawValue: turnStatus) ?? .inprogress
            if state == .interrupted {
                state = .end
            }
            messageState = state
        }
        let userId = message.user_id ?? "0"
        let turnId = message.turn_id ?? 0
        let transcriptionMessage = Transcription(turnId: turnId,
                                                 userId: userId,
                                                   text: text,
                                                 status: messageState,
                                                   type: .agent)
        let agentUserId = message.publish_id ?? "-1"
        callMessagePrint(tag: TranscriptionController.uiTag, msg: "[Text Mode] pts: \(audioTimestamp), \(agentUserId), \(transcriptionMessage)")
        self.delegate?.onTranscriptionUpdated(agentUserId: agentUserId, transcription: transcriptionMessage)
    }
    
    private func handleWordsMessage(_ message: TranscriptionMessage) {
        queue.async(flags: .barrier) {
            // handle new agent message
            if message.object == MessageType.assistant.rawValue {
                if let lastFinishId = self.lastFinishMessage?.turnId,
                   lastFinishId >= (message.turn_id ?? 0) {
                    self.callMessagePrint(tag: TranscriptionController.tag, msg: "<<< Discarding old turn: received=\(String(describing: message.turn_id))  lateset=\(lastFinishId), publisher:\(message.publish_id ?? "-1")")
                    return
                }
                if let queueLastTurnId = self.messageQueue.last?.turnId,
                   queueLastTurnId > (message.turn_id ?? 0) {
                    self.callMessagePrint(tag: TranscriptionController.tag, msg: "<<< Discarding the turn has already been processed: received=\(message.turn_id ?? -1) lateset=\(queueLastTurnId), publisher:\(message.publish_id ?? "-1")")
                    return
                }
                guard let turnStatus = TranscriptionStatus(rawValue: message.turn_status ?? 0) else {
                    self.callMessagePrint(tag: TranscriptionController.tag, msg: "<<< Discarding the turn unKnow state received=\(message.turn_id ?? -1) turnStatus=\(message.turn_status ?? -1), publisher:\(message.publish_id ?? "-1")")
                    return
                }

                let curBuffer: TurnMessageInfo = self.messageQueue.first { $0.turnId == message.turn_id } ?? {
                    let newTurn = TurnMessageInfo()
                    newTurn.turnId = message.turn_id ?? 0
                    newTurn.userId = message.user_id ?? "0"
                    newTurn.agentUserId = message.publish_id ?? "0"
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
                        let addWords = uniqueWords.compactMap { word -> TurnWordInfo? in
                            guard let wordText = word.word, let startTime = word.start_ms else {
                                return nil
                            }
                            return TurnWordInfo(text: wordText,
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
                }
            } else if (message.object == MessageType.interrupt.rawValue) {// handle interrupt
                if let interruptTime = message.start_ms,
                   let buffer: TurnMessageInfo = self.messageQueue.first(where: { $0.turnId == message.turn_id })
                {
                    let interruptedEvent = InterruptEvent(turnId: buffer.turnId, timestamp: TimeInterval(buffer.start_ms))
                    let agentUserId = buffer.agentUserId
                    self.callMessagePrint(tag: TranscriptionController.tag, msg: "<<< [onInterrupted], pts: \(self.audioTimestamp), \(agentUserId), \(message), \(interruptedEvent) ")

                    var lastIndex: Int = 0
                    let interruptMarkMs = min(interruptTime, self.audioTimestamp)
                    self.callMessagePrint(tag: TranscriptionController.tag, msg: "interruptMarkMs: \(interruptMarkMs), startMs: \(interruptTime), pts: \(self.audioTimestamp)")
                    for index in buffer.words.indices {
                        if buffer.words[index].start_ms >= interruptMarkMs {
                            buffer.words[index].status = .interrupted
                        }
                        
                        if buffer.words[index].start_ms < interruptMarkMs {
                            lastIndex = index
                        }
                    }
                    
                    if !buffer.words.isEmpty {
                        buffer.words[lastIndex].status = .interrupted
                    }

                    self.delegate?.onInterrupted(agentUserId: agentUserId, event: interruptedEvent)
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
                    callMessagePrint(tag: TranscriptionController.tag, msg: "remove interrupte turn: \(buffer.turnId)")
                    continue
                }
                // if last turn is interrupte by this buffer
                if let lastMessage = lastMessage,
                   lastMessage.status == .inprogress,
                   buffer.turnId > lastMessage.turnId  {
                    // interrupte last turn
                    lastMessage.status = .interrupted
            
                    let publish = lastPublish ?? "-1"
                    callMessagePrint(tag: TranscriptionController.uiTag, msg: "<<< [interrupt2] pts: \(audioTimestamp), \(lastMessage), publisher:\(publish)")
                    self.delegate?.onTranscriptionUpdated(agentUserId: publish, transcription: lastMessage)
                    interrupte = true
                }
                // get turn sub range
                
                let availableWords = buffer.words.filter { $0.start_ms <= audioTimestamp }
                
                if availableWords.isEmpty { continue }
                
                guard let lastWord = availableWords.last else {
                    continue
                }
                
                callMessagePrint(tag: TranscriptionController.uiTag, msg: "last word===3, pts: \(self.audioTimestamp), word: \(lastWord), status: \(lastWord.status), turnId: \(buffer.turnId)， word start_ms: \(lastWord.start_ms)")
                var transcriptionMessage: Transcription
                if lastWord.status == .interrupted {
                    transcriptionMessage = Transcription(turnId: buffer.turnId,
                                                         userId: buffer.userId,
                                                         text: availableWords.map { $0.text }.joined(),
                                                         status: .interrupted,
                                                         type: .agent)
                    // remove finished turn
                    self.messageQueue.remove(at: index)
                    lastFinishMessage = transcriptionMessage
                    callMessagePrint(tag: TranscriptionController.uiTag, msg: "<<< [interrupt1] pts: \(audioTimestamp), message: \(transcriptionMessage), publisher:\(buffer.agentUserId)")
                } else if lastWord.status == .end {
                    transcriptionMessage = Transcription(turnId: buffer.turnId,
                                                      userId: buffer.userId,
                                                      text: buffer.text,
                                                         status: .end, type: .agent)
                    // remove finished turn
                    self.messageQueue.remove(at: index)
                    lastFinishMessage = transcriptionMessage
                    callMessagePrint(tag: TranscriptionController.uiTag, msg: "[end] pts: \(audioTimestamp), message: \(transcriptionMessage), publisher:\(buffer.agentUserId)")
                } else {
                    transcriptionMessage = Transcription(turnId: buffer.turnId,
                                                      userId: buffer.userId,
                                                      text: availableWords.map { $0.text }.joined(),
                                                         status: .inprogress, type: .agent)
                    callMessagePrint(tag: TranscriptionController.uiTag, msg: "<<< [progress] pts: \(audioTimestamp), message: \(transcriptionMessage), publisher:\(buffer.agentUserId)")
                }
                
                if !transcriptionMessage.text.isEmpty {
                    lastMessage = transcriptionMessage
                    lastPublish = buffer.agentUserId
                    let agentUserId = buffer.agentUserId
                    self.delegate?.onTranscriptionUpdated(agentUserId: agentUserId, transcription: transcriptionMessage)
                }
            }
        }
    }
}

// MARK: - AgoraAudioFrameDelegate
extension TranscriptionController: AgoraAudioFrameDelegate {
    
    public func onPlaybackAudioFrame(beforeMixing frame: AgoraAudioFrame, channelId: String, uid: UInt) -> Bool {
        audioTimestamp = frame.presentationMs
        return true
    }
    
    public func getObservedAudioFramePosition() -> AgoraAudioFramePosition {
        return .beforeMixing
    }
}
// MARK: - CovSubRenderControllerProtocol
extension TranscriptionController {
    @objc public func setupWithConfig(_ config: TranscriptionRenderConfig) {
        renderConfig = config
        
        guard let rtcEngine = config.rtcEngine, let rtmEngine = config.rtmEngine else {
            return
        }
        
        self.delegate = config.delegate
        
        rtcEngine.setAudioFrameDelegate(self)
        rtcEngine.setPlaybackAudioFrameBeforeMixingParametersWithSampleRate(44100, channel: 1)
        
        rtmEngine.addDelegate(self)
        callMessagePrint(tag: TranscriptionController.tag, msg: ">>> [setupWithConfig]")
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
    
    private func inputRtmMessage(message: Data?, publisherId: String) {
        guard let data = message else { return }
        do {
            var transcription = try JSONDecoder().decode(TranscriptionMessage.self, from: data)
            transcription.publish_id = publisherId
            handleMessage(transcription)
        } catch {
            callMessagePrint(tag: TranscriptionController.tag, msg: "!!!Failed to parse JSON content, error: \(error.localizedDescription)")
            return
        }
    }
}

extension TranscriptionController: AgoraRtmClientDelegate {
    public func rtmKit(_ rtmKit: AgoraRtmClientKit, didReceiveMessageEvent event: AgoraRtmMessageEvent) {
        if let stringData = event.message.stringData {
            guard let data = stringData.data(using: .utf8) else {
                callMessagePrint(tag: TranscriptionController.tag, msg: "!!!inputRtmMessage: Failed to convert string to data")
                return
            }
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
               let cleanData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
               let cleanString = String(data: cleanData, encoding: .utf8) {
                callMessagePrint(tag: TranscriptionController.tag, msg: "<<< rtm data: \(cleanString)")
            } else {
                callMessagePrint(tag: TranscriptionController.tag, msg: "<<< rtm data: \(stringData)")
            }
            inputRtmMessage(message: data, publisherId: event.publisher)
        } else if let rawData = event.message.rawData {
            inputRtmMessage(message: rawData, publisherId: event.publisher)
        }
    }
}

