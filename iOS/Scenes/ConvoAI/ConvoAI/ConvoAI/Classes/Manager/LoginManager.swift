//
//  LoginManager.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/22.
//

import Foundation
import Common

protocol LoginManagerDelegate: AnyObject {
    func loginManager(_ manager: LoginManager, userInfoDidChange userInfo: LoginModel?, loginState: Bool)
    func userLoginSessionExpired()
}

protocol LoginManagerProtocol {
    func addDelegate(_ delegate: LoginManagerDelegate)
    func removeDelegate(_ delegate: LoginManagerDelegate)
    func updateUserInfo(userInfo: LoginModel)
    func logout()
}

class LoginManager {
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(loginSessionExpired), name: .TokenExpired, object: nil)
    }
    
    private func notifyDelegates(_ notification: (LoginManagerDelegate) -> Void) {
        for delegate in delegates.allObjects {
            if let delegate = delegate as? LoginManagerDelegate {
                notification(delegate)
            }
        }
    }
    
    @objc private func loginSessionExpired() {
        if UserCenter.shared.isLogin() {
            UserCenter.shared.logout()
            notifyDelegates { $0.userLoginSessionExpired() }
        }
    }
}

extension LoginManager: LoginManagerProtocol {
    func addDelegate(_ delegate: LoginManagerDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: LoginManagerDelegate) {
        delegates.remove(delegate)
    }
    
    func updateUserInfo(userInfo: LoginModel) {
        UserCenter.shared.storeUserInfo(userInfo)
        let loginState = UserCenter.shared.isLogin()
        notifyDelegates { $0.loginManager(self, userInfoDidChange: userInfo, loginState: loginState)}
    }
    
    func logout() {
        UserCenter.shared.logout()
        let loginState = UserCenter.shared.isLogin()
        notifyDelegates { $0.loginManager(self, userInfoDidChange: nil, loginState: loginState)}
    }
}

extension LoginManagerDelegate {
    func loginManager(_ manager: LoginManager, userInfoDidChange userInfo: LoginModel?, loginState: Bool) {}
    func userLoginSessionExpired() {}
}
