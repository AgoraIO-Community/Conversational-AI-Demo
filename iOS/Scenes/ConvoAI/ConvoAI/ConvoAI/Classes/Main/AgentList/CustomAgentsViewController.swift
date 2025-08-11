//
//  CustomAgentsViewController.swift
//  ConvoAI
//
//  Created by HeZhengQing on 2024/07/25.
//

import UIKit
import Common

fileprivate let kCustomPresetSave = "io.agora.customPresets"
class CustomAgentsViewController: UIViewController {

    weak var scrollDelegate: AgentScrollViewDelegate?

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AgentTableViewCell.self, forCellReuseIdentifier: "AgentTableViewCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        return tableView
    }()

    private let emptyStateView = CustomAgentEmptyView()
    private let inputContainerView = BottomInputView()
    
    private lazy var agentManager = AgentManager()
    
    private var presets: [AgentPreset] = [AgentPreset]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        fetchSavedPresets()
    }
    
    @objc private func onClickFetch() {
        guard let text = inputContainerView.textField.text, !text.isEmpty else { return }
        agentManager.searchCustomPresets(customPresetIds: [text]) { [weak self] error, result in
            guard let self = self else { return }
            if let err = error {
                ConvoAILogger.error(err.localizedDescription)
                return
            }
            if let presets = result, !presets.isEmpty {
                self.save(presetId: text)
                self.fetchSavedPresets()
            }
        }
    }
    
    public func fetchSavedPresets() {
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
        agentManager.searchCustomPresets(customPresetIds: ids) { [weak self] error, result in
            guard let self = self else { return }
            if let err = error {
                ConvoAILogger.error(err.localizedDescription)
                return
            }
            self.presets = result ?? []
            self.tableView.reloadData()
        }
    }
    
    private func getSavedPresetIds() -> [String] {
        let key = (AppContext.shared.appId + AppContext.shared.baseServerUrl).hashValue.description
        let saved = UserDefaults.standard.dictionary(forKey: kCustomPresetSave) as? [String: [String]]
        return saved?[key] ?? []
    }
    
    private func save(presetId: String) {
        let key = (AppContext.shared.appId + AppContext.shared.baseServerUrl).hashValue.description
        var saved = UserDefaults.standard.dictionary(forKey: kCustomPresetSave) as? [String: [String]] ?? [:]
        var ids = saved[key] ?? []
        if !ids.contains(presetId) {
            ids.append(presetId)
        }
        saved[key] = ids
        UserDefaults.standard.set(saved, forKey: kCustomPresetSave)
    }
    
    private func remove(presetId: String) {
        let key = (AppContext.shared.appId + AppContext.shared.baseServerUrl).hashValue.description
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

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        inputContainerView.textField.isUserInteractionEnabled = false
        inputContainerView.actionButton.addTarget(self, action: #selector(onClickFetch), for: .touchUpInside)
        view.addSubview(inputContainerView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapInputView))
        inputContainerView.addGestureRecognizer(tapGesture)
    }

    private func setupConstraints() {
        inputContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(inputContainerView.snp.top).offset(-10)
        }

        emptyStateView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(inputContainerView.snp.top).offset(-10)
            make.left.right.equalToSuperview().inset(20)
        }
    }
}

extension CustomAgentsViewController: UITableViewDataSource, UITableViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.agentScrollViewDidScroll(scrollView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = presets.count
        emptyStateView.alpha = count > 0 ? 0 : 1
        tableView.alpha = count > 0 ? 1 : 0
        return count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 82
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AgentTableViewCell", for: indexPath) as! AgentTableViewCell
        let preset = presets[indexPath.row]
        cell.nameLabel.text = preset.name
        cell.descriptionLabel.text = preset.description ?? ""
        cell.avatarImageView.kf.setImage(with: URL(string: preset.avatarUrl.stringValue()), placeholder: UIImage(named: "default_avatar"))
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
