//
//  OfficialAgentsViewController.swift
//  ConvoAI
//
//  Created by HeZhengQing on 2024/07/25.
//

import UIKit
import Common
import SVProgressHUD
import Kingfisher

protocol AgentScrollViewDelegate: AnyObject {
    func agentScrollViewDidScroll(_ scrollView: UIScrollView)
}

class OfficialAgentsViewController: UIViewController {

    weak var scrollDelegate: AgentScrollViewDelegate?
    
    private lazy var agentManager = AgentManager()
    
    private var presets: [AgentPreset] = [AgentPreset]()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AgentTableViewCell.self, forCellReuseIdentifier: "AgentTableViewCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        
        fetchPresets()
    }
    
    public func fetchPresets() {
        guard UserCenter.shared.isLogin() else {
            return
        }
        if let p = AppContext.preferenceManager()?.allPresets() {
            presets = p
            return
        }
        
        agentManager.fetchAgentPresets(appId: AppContext.shared.appId) { error, result in
            if let error = error {
                SVProgressHUD.showInfo(withStatus: error.localizedDescription)
                return
            }
            
            guard let result = result else {
                SVProgressHUD.showInfo(withStatus: "result is empty")
                return
            }
            
            AppContext.preferenceManager()?.setPresets(presets: result)
            self.presets = result
            self.tableView.reloadData()
        }
    }

    private func setupUI() {
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension OfficialAgentsViewController: UITableViewDataSource, UITableViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.agentScrollViewDidScroll(scrollView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.presets.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 82
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AgentTableViewCell", for: indexPath) as! AgentTableViewCell
        let preset = presets[indexPath.row]
        cell.nameLabel.text = preset.displayName
        cell.avatarImageView.kf.setImage(with: URL(string: preset.avatarUrl.stringValue()), placeholder: UIImage.ag_named("ic_head_ai_sister"))
        cell.descriptionLabel.text = preset.description ?? ""
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let preset = presets[indexPath.row]
        AppContext.preferenceManager()?.updatePreset(preset)
        let chatViewController = ChatViewController()
        chatViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}
