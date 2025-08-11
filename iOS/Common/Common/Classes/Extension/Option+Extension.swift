//
//  Option+Extension.swift
//  ConvoAI
//
//  Created by qinhui on 2025/8/11.
//

import Foundation

extension Optional where Wrapped == String {
    func stringValue() -> String {
        if let res = self {
            return res
        }
        
        return ""
    }
}

extension Optional where Wrapped == Bool {
    func boolValue() -> Bool {
        if let res = self {
            return res
        }
        
        return false
    }
}

extension Optional where Wrapped == Int {
    func intValue() -> Int {
        if let res = self {
            return res
        }
        
        return 0
    }
}
