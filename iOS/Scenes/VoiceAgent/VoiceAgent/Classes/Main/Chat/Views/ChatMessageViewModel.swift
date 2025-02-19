//
//  ChatMessageViewModel.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/19.
//

import Foundation

struct Message {
    var content: String
    let isMine: Bool
    var isFinal: Bool
    let timestamp: Int64
    var turn_id: String
}

protocol ChatMessageViewModelDelegate: AnyObject {
    func startNewMessage()
    func messageUpdated()
    func messageFinished()
}

class ChatMessageViewModel: NSObject {
    var messages: [Message] = []
    var messageMapTable: [String : Message] = [:]
    weak var delegate: ChatMessageViewModelDelegate?
    
    func clearMessage() {
        messages.removeAll()
        messageMapTable.removeAll()
    }
    
    func messageFlush(turnId:String, message: String, timestamp: Int64, owner: MessageOwner, isFinished: Bool) {
        if turnId.isEmpty {
           reduceIndependentMessage(message: message, timestamp: timestamp, owner: owner, isFinished: isFinished)
        } else {
            reduceStandardMessage(turnId: turnId, message: message, timestamp: timestamp, owner: owner, isFinished: isFinished)
        }
    }
}




