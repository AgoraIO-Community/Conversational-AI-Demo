//
//  OfficialAgentViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/8/12.
//

import UIKit
import Common
import SVProgressHUD

class OfficialAgentViewController: AgentListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func fetchData() {
        guard UserCenter.shared.isLogin() else {
            return
        }
        
        if AppContext.shared.isOpenSource, let data = AppContext.shared.loadLocalPreset() {
            do {
                let presets = try JSONDecoder().decode([AgentPreset].self, from: data)
                self.presets = presets
                AppContext.preferenceManager()?.setPresets(presets: presets)
                tableView.reloadData()
            } catch {
                ConvoAILogger.error("JSON decode error: \(error)")
            }
            return
        }
        
        if let p = AppContext.preferenceManager()?.allPresets() {
            presets = p
            refreshControl.endRefreshing()
            return
        }
        
        requestAgentPresets()
    }
    
    private func requestAgentPresets() {
        agentManager.fetchAgentPresets(appId: AppContext.shared.appId) {[weak self] error, result in
            self?.refreshControl.endRefreshing()
            if let error = error {
                SVProgressHUD.showInfo(withStatus: error.localizedDescription)
                return
            }
            
            guard let result = result else {
                SVProgressHUD.showInfo(withStatus: "result is empty")
                return
            }
            
            AppContext.preferenceManager()?.setPresets(presets: result)
            self?.presets = result
            self?.tableView.reloadData()
        }
    }
}
