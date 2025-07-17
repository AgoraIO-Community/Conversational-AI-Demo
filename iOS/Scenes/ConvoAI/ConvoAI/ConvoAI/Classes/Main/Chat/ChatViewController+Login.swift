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
        welcomeMessageView.isHidden = loginState
        topBar.updateButtonVisible(loginState)
        if !loginState {
            SSOWebViewController.clearWebViewCache()
            stopLoading()
            stopAgent()
        }
    }
    
    func userLoginSessionExpired() {
        addLog("[Call] userLoginSessionExpired")
        welcomeMessageView.isHidden = false
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
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .overFullScreen
            loginVC.loginAction = { [weak self] in
                let baseUrl = AppContext.shared.baseServerUrl
                self?.goToSSO(urlString: "\(baseUrl)/v1/convoai/sso/login")
            }
            loginVC.signupAction = { [weak self] in
                SSOWebViewController.clearWebViewCache()
                let baseUrl = AppContext.shared.baseServerUrl
                self?.goToSSO(urlString: "\(baseUrl)/v1/convoai/sso/signup")
            }
            self.present(loginVC, animated: false)
        }
    }
    
    private func goToSSO(urlString: String) {
        let ssoWebVC = SSOWebViewController()
        ssoWebVC.urlString = urlString
        ssoWebVC.completionHandler = { [weak self] token in
            guard let self = self else { return }
            if let token = token {
                self.addLog("SSO token: \(token)")
                let model = LoginModel()
                model.token = token
                AppContext.loginManager()?.updateUserInfo(userInfo: model)
                let localToken = UserCenter.user?.token ?? ""
                self.addLog("local token: \(localToken)")
                self.bottomBar.startLoadingAnimation()
                LoginApiService.getUserInfo { [weak self] error in
                    self?.bottomBar.stopLoadingAnimation()
                    if let err = error {
                        AppContext.loginManager()?.logout()
                        SVProgressHUD.showInfo(withStatus: err.localizedDescription)
                    }
                }
            }
        }
        self.navigationController?.pushViewController(ssoWebVC, animated: false)
    }
}
