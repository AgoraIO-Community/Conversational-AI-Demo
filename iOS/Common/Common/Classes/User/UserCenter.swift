//
//  UserCenter.swift
//  Common-Common
//
//  Created by qinhui on 2025/2/21.
//

import Foundation

public class LoginModel: Codable {
    public var token: String = ""
    public var uid: String = ""
    
    public init() {
        self.token = ""
        self.uid = ""
    }
}

public class UserCenter {
    
    public class var user: LoginModel? {
        return shared._user
    }
    
    private static let kLocalLoginKey = "kLocalLoginKey"
    
    public static let shared = UserCenter()
    public static var center: UserCenter { return shared }
    
    private var _user: LoginModel? = nil
    
    private init() {
        _user = getUserFromDefaults()
    }
        
    private func getUserFromDefaults() -> LoginModel? {
        guard let jsonString = UserDefaults.standard.string(forKey: UserCenter.kLocalLoginKey),
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(LoginModel.self, from: data)
    }
    
    public func isLogin() -> Bool {
        return _user != nil
    }
    
    public func storeUserInfo(_ user: LoginModel) {
        _user = user
        if let data = try? JSONEncoder().encode(user),
           let jsonString = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: UserCenter.kLocalLoginKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    public func logout() {
        _user = nil
        cleanUserInfo()
    }
    
    private func cleanUserInfo() {
        UserDefaults.standard.removeObject(forKey: UserCenter.kLocalLoginKey)
        UserDefaults.standard.synchronize()
    }
}
