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
    let emptyStateView = CommonEmptyView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        super.setupUI()
        view.addSubview(emptyStateView)
        emptyStateView.isHidden = true
        emptyStateView.retryAction = { [weak self] in
            guard let self = self else { return }
            self.requestAgentPresets()
        }
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        emptyStateView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalTo(tableView)
        }
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
    
    override func refreshHandler() {
        requestAgentPresets()
    }
    
    private func requestAgentPresets() {
        SVProgressHUD.show()
        agentManager.fetchAgentPresets(appId: AppContext.shared.appId) {[weak self] error, result in
            SVProgressHUD.dismiss()
            self?.refreshControl.endRefreshing()
            if let error = error {
                SVProgressHUD.showInfo(withStatus: error.localizedDescription)
                return
            }
            
            guard let result = result else {
                ConvoAILogger.error("result is empty")
                self?.refreshSubView()
                return
            }
            
            AppContext.preferenceManager()?.setPresets(presets: result)
            self?.presets = result
            self?.tableView.reloadData()
            self?.refreshSubView()
        }
    }
    
    private func refreshSubView() {
        emptyStateView.isHidden = presets.count != 0
    }
}

