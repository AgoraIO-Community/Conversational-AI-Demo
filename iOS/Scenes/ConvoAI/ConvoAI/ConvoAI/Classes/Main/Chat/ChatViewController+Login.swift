//
//  ChatViewController+Login.swift
//  ConvoAI
//
//  Created by qinhui on 2025/7/1.
//

import Foundation
import Common
import SVProgressHUD

extension ChatViewController: LoginManagerDelegate {
    func loginManager(_ manager: LoginManager, userInfoDidChange userInfo: LoginModel?, loginState: Bool) {
        topBar.updateButtonVisible(loginState)
        if loginState {
            // setup presets
            Task {
                do {
                    try await self.fetchPresetsIfNeeded()
                } catch {
                    self.addLog("[PreloadData error - presets]: \(error)")
                }
            }
        } else {
            SSOWebViewController.clearWebViewCache()
            stopLoading()
            stopAgent()
            // clean presets
            deleteAllPresets()
            AppContext.preferenceManager()?.updateAvatar(nil)
        }
    }
    
    func userLoginSessionExpired() {
        addLog("[Call] userLoginSessionExpired")
        topBar.updateButtonVisible(false)
        SSOWebViewController.clearWebViewCache()
        stopLoading()
        stopAgent()
        
        SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Login.sessionExpired)
    }
    
    func clickTheStartButton() async {
        addLog("[Call] clickTheStartButton()")
        let loginState = UserCenter.shared.isLogin()

        if loginState {
            await MainActor.run {
                let needsShowMicrophonePermissionAlert = PermissionManager.getMicrophonePermission() == .denied
                if needsShowMicrophonePermissionAlert {
                    self.bottomBar.setMircophoneButtonSelectState(state: true)
                }
            }
            
            PermissionManager.checkMicrophonePermission { res in
                Task {
                    await self.prepareToStartAgent()
                    await MainActor.run {
                        if !res {
                            self.bottomBar.setMircophoneButtonSelectState(state: true)
                        }
                    }
                }
            }
            
            return
        }
        
        await MainActor.run {
            LoginViewController.start(from: self)
        }
    }
}
