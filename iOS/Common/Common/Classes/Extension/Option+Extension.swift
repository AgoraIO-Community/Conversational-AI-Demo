//
//  Option+Extension.swift
//  ConvoAI
//
//  Created by qinhui on 2025/8/11.
//

import Foundation

extension Optional where Wrapped == String {
    public func stringValue() -> String {
        if let res = self {
            return res
        }
        
        return ""
    }
}

extension Optional where Wrapped == Bool {
    public func boolValue() -> Bool {
        if let res = self {
            return res
        }
        
        return false
    }
}

extension Optional where Wrapped == Int {
    public func intValue() -> Int {
        if let res = self {
            return res
        }
        
        return 0
    }
}
