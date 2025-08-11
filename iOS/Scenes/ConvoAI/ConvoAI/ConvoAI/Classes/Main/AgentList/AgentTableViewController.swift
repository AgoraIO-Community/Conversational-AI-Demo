//
//  AgentTableViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/8/11.
//

import UIKit
import Common
import SVProgressHUD

protocol AgentScrollViewDelegate: AnyObject {
    func agentScrollViewDidScroll(_ scrollView: UIScrollView)
}

protocol AgentListProtocol {
    func setupUI()
    func setupConstraints()
    func fetchData()
    func refreshHandler()
}

class AgentTableViewController: UIViewController, AgentListProtocol {
    var presets: [AgentPreset] = [AgentPreset]()
    weak var scrollDelegate: AgentScrollViewDelegate?
    let agentManager = AgentManager()
    lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        return refresh
    }()
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AgentTableViewCell.self, forCellReuseIdentifier: "AgentTableViewCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        fetchData()
    }
    
    func fetchData() {
        guard UserCenter.shared.isLogin() else {
            return
        }
        if let p = AppContext.preferenceManager()?.allPresets() {
            presets = p
            refreshControl.endRefreshing()
            return
        }
        
        requestAgentPresets()
    }
    
    func setupUI() {
        view.addSubview(tableView)
        tableView.addSubview(refreshControl)
    }
    
    func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func refreshHandler() {
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

extension AgentTableViewController: UITableViewDelegate, UITableViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
        cell.avatarImageView.kf.setImage(with: URL(string: preset.avatarUrl.stringValue()), placeholder: UIImage.ag_named("ic_default_avatar_icon"))
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
