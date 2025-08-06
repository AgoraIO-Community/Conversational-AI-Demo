//
//  CustomAgentsViewController.swift
//  ConvoAI
//
//  Created by HeZhengQing on 2024/07/25.
//

import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    @objc private func onClickFetch() {
        guard let text = inputContainerView.textField.text else { return }
        
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
        let count = 0 // Placeholder for actual data count
        emptyStateView.alpha = count > 0 ? 0 : 1
        tableView.alpha = count > 0 ? 1 : 0
        return count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 82
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AgentTableViewCell", for: indexPath) as! AgentTableViewCell
        // Configure cell with placeholder data
        cell.nameLabel.text = "Agent Name"
        cell.descriptionLabel.text = "Agent Description"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
