//
//  ChatViewController+NavigatorBarControl.swift
//  ConvoAI
//
//  Created by qinhui on 2025/7/1.
//

import Foundation
import Common
import SVProgressHUD

extension ChatViewController {
    @objc internal func onClickInformationButton() {
        AgentInformationViewController.show(in: self)
    }
    
    @objc internal func onClickWifiInfoButton() {
        let settingVC = AgentSettingViewController()
        settingVC.agentManager = agentManager
        settingVC.rtcManager = rtcManager
        settingVC.currentTabIndex = 1
        let navigationController = UINavigationController(rootViewController: settingVC)
        navigationController.modalPresentationStyle = .overFullScreen
        present(navigationController, animated: false)
    }
    
    @objc internal func onClickSettingButton() {
        let settingVC = AgentSettingViewController()
        settingVC.agentManager = agentManager
        settingVC.rtcManager = rtcManager
        settingVC.currentTabIndex = 0
        let navigationController = UINavigationController(rootViewController: settingVC)
        navigationController.modalPresentationStyle = .overFullScreen
        present(navigationController, animated: false)
    }
    
    @objc internal func onClickTranscriptionButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        showTranscription(state: sender.isSelected)
    }
    
    @objc internal func onCharacterButton() {
        let currentTime = Date()
        if let lastTime = lastClickTime, currentTime.timeIntervalSince(lastTime) > 1.0 {
            clickCount = 0
        }
        lastClickTime = currentTime
        clickCount += 1
        if clickCount >= 5 {
            onThresholdReached()
            clickCount = 0
        }
    }
    
    @objc internal func onCloseButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    internal func onThresholdReached() {
        if !DeveloperConfig.shared.isDeveloperMode {
            devModeButton.isHidden = false
            sendMessageButton.isHidden = false
            DeveloperConfig.shared.isDeveloperMode = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
