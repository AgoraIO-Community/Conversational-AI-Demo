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

class AgentListViewController: UIViewController, AgentListProtocol {
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
    
    
    func setupUI() {
        view.addSubview(tableView)
        tableView.addSubview(refreshControl)
    }
    
    func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func fetchData() {
        fatalError("Subclass must implement fetchData()")
    }
    
    @objc func refreshHandler() {
        fatalError("Subclass must implement refreshHandler()")
    }
}

extension AgentListViewController: UITableViewDelegate, UITableViewDataSource {
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
