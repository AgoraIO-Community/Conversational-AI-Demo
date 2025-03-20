//
//  AgentSelectTableView.swift
//  Agent
//
//  Created by HeZhengQing on 2024/10/1.
//

import UIKit
import Common

class AgentSelectTableView: UIView {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var dataSource = [String]()
    private var onSelected: ((Int) -> Void)?
    private var selectedIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init(items: [String], selected: @escaping ((Int) -> Void)) {
        super.init(frame: CGRect(x: 0, y: 0, width: 250.0, height: CGFloat(dataSource.count) * 44.0))
        dataSource = items
        onSelected = selected
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func getWith() -> CGFloat {
        return 250.0
    }
    
    func getHeight() -> CGFloat {
        if CGFloat(dataSource.count) * 56.0 > 200 {
            return 200
        }
        return CGFloat(dataSource.count) * 56.0
    }

    private func setup() {
        self.layerCornerRadius = 12
        backgroundColor = UIColor.themColor(named: "ai_line1")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellWithClass: AgentSettingSubOptionCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = 56
        tableView.bounces = false
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }

    func setSelectedIndex(_ index: Int) {
        selectedIndex = index
        tableView.reloadData()
    }
}
// MARK: - UITableViewDelegate
extension AgentSelectTableView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: AgentSettingSubOptionCell.self)
        let title = dataSource[indexPath.row]
        cell.configure(with: title, isSelected: indexPath.row == selectedIndex)
        // if the cell is last cell, hide the bottom line
        cell.bottomLine.isHidden = (indexPath.row == dataSource.count - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndex = indexPath.row
        tableView.reloadData()
        onSelected?(indexPath.row)
    }
}
