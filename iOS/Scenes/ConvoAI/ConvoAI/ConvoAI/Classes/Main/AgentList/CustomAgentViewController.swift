//
//  CustomAgentsViewController.swift
//  ConvoAI
//
//  Created by HeZhengQing on 2024/07/25.
//

import UIKit
import Common
import Kingfisher
import CryptoKit
import SVProgressHUD

fileprivate let kCustomPresetSave = "io.agora.customPresets"
class CustomAgentViewController: AgentListViewController {
    private let emptyStateView = CustomAgentEmptyView()
    private let inputContainerView = BottomInputView()
    
    override func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        emptyStateView.isHidden = true
        inputContainerView.textField.isUserInteractionEnabled = false
        inputContainerView.actionButton.addTarget(self, action: #selector(onClickFetch), for: .touchUpInside)
        view.addSubview(inputContainerView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapInputView))
        inputContainerView.addGestureRecognizer(tapGesture)
        
        tableView.addSubview(refreshControl)
    }

    override func setupConstraints() {
        inputContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-17)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalTo(0)
            make.bottom.equalTo(inputContainerView.snp.top).offset(-21)
        }

        emptyStateView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.bottom.equalTo(inputContainerView.snp.top).offset(-21)
            make.left.right.equalToSuperview().inset(12)
        }
    }
    @objc private func onClickFetch() {
        guard let text = inputContainerView.textField.text, !text.isEmpty else { return }
        SVProgressHUD.show()
        agentManager.searchCustomPresets(customPresetIds: [text]) { [weak self] error, result in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            if let err = error {
                if err.code == 1800 {
                    self.remove(presetId: text)
                    self.fetchData()
                    ConvoAILogger.error(ResourceManager.L10n.Error.agentOffline)
                    SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Error.agentOffline)
                } else {
                    ConvoAILogger.error(err.localizedDescription)
                    SVProgressHUD.showInfo(withStatus: err.localizedDescription)
                }
                
                return
            }
            if let presets = result, !presets.isEmpty {
                self.save(presetId: text)
                self.fetchData()
            } else {
                SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Error.agentNotFound)
                ConvoAILogger.error(ResourceManager.L10n.Error.agentNotFound)
            }
        }
    }
    
    override func refreshHandler() {
        fetchData()
    }
    
    override func fetchData() {
        guard UserCenter.shared.isLogin() else {
            self.presets.removeAll()
            self.tableView.reloadData()
            return
        }
        let ids = getSavedPresetIds()
        if ids.isEmpty {
            self.presets.removeAll()
            self.tableView.reloadData()
            return
        }
        SVProgressHUD.show()
        agentManager.searchCustomPresets(customPresetIds: ids) { [weak self] error, result in
            self?.refreshControl.endRefreshing()
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            if let err = error {
                ConvoAILogger.error(err.localizedDescription)
                return
            }
            
            if let presets = result, !presets.isEmpty {
                for e in presets {
                    self.save(presetId: e.name.stringValue())
                }
                self.presets = presets
                self.tableView.reloadData()
                self.refreshSubView()
            }
        }
    }
    
    private func getCacheKey() -> String {
        let rawKey = AppContext.shared.appId + AppContext.shared.baseServerUrl
        let inputData = Data(rawKey.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    private func getSavedPresetIds() -> [String] {
        let key = getCacheKey()
        let saved = UserDefaults.standard.dictionary(forKey: kCustomPresetSave) as? [String: [String]]
        return saved?[key] ?? []
    }
    
    private func save(presetId: String) {
        let key = getCacheKey()
        var saved = UserDefaults.standard.dictionary(forKey: kCustomPresetSave) as? [String: [String]] ?? [:]
        var ids = saved[key] ?? []
        if !ids.contains(presetId) {
            ids.append(presetId)
        }
        saved[key] = ids
        UserDefaults.standard.set(saved, forKey: kCustomPresetSave)
    }
    
    private func remove(presetId: String) {
        let key = getCacheKey()
        var saved = UserDefaults.standard.dictionary(forKey: kCustomPresetSave) as? [String: [String]] ?? [:]
        var ids = saved[key] ?? []
        ids.removeAll { $0 == presetId }
        saved[key] = ids
        UserDefaults.standard.set(saved, forKey: kCustomPresetSave)
    }

    @objc private func didTapInputView() {
        let vc = BottomInputViewController()
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = { [weak self] fetch, text in
            guard let self = self else { return }
            self.inputContainerView.textField.text = text
            if fetch {
                self.onClickFetch()
            }
        }
        present(vc, animated: true)
    }
    
    private func refreshSubView() {
        emptyStateView.isHidden = presets.count != 0
    }
}

extension CustomAgentViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let preset = presets[indexPath.row]
        let id = preset.name.stringValue()
        SVProgressHUD.show()
        agentManager.searchCustomPresets(customPresetIds: [id]) { [weak self] error, result in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            if let err = error {
                if err.code == 1800 {
                    self.remove(presetId: id)
                    self.fetchData()
                    ConvoAILogger.error(ResourceManager.L10n.Error.agentOffline)
                    SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Error.agentOffline)
                } else {
                    ConvoAILogger.error(err.localizedDescription)
                    SVProgressHUD.showInfo(withStatus: err.localizedDescription)
                }
                
                return
            }
            if let presets = result, !presets.isEmpty {
                AppContext.preferenceManager()?.updatePreset(preset)
                let chatViewController = ChatViewController()
                chatViewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(chatViewController, animated: true)
            } else {
                SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Error.agentNotFound)
                ConvoAILogger.error(ResourceManager.L10n.Error.agentNotFound)
            }
        }
    }
}
