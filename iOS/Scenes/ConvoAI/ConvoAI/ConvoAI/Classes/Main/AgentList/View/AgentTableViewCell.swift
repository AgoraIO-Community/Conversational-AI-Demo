//
//  AgentTableViewCell.swift
//  ConvoAI
//
//  Created by Trae AI on 2024/07/25.
//

import UIKit
import Common

class AgentTableViewCell: UITableViewCell {
    
    private let customBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 44/255.0, green: 49/255.0, blue: 58/255.0, alpha: 1.0)
        view.layer.cornerRadius = 16
        return view
    }()

    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 25
        imageView.clipsToBounds = true
        return imageView
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        return label
    }()

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.themColor(named: "ai_icontext3")
        label.numberOfLines = 2
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        UIView.animate(withDuration: 0.3) {
            if selected {
                self.customBackgroundView.backgroundColor = UIColor.themColor(named: "ai_mask3")
            } else {
                self.customBackgroundView.backgroundColor = UIColor.themColor(named: "ai_fill6")
            }
        }
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(customBackgroundView)
        customBackgroundView.addSubview(avatarImageView)
        customBackgroundView.addSubview(nameLabel)
        customBackgroundView.addSubview(descriptionLabel)
    }

    private func setupConstraints() {
        customBackgroundView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.top.equalTo(avatarImageView.snp.top).offset(4)
            make.trailing.equalToSuperview().offset(-20)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.leading)
            make.bottom.equalTo(avatarImageView.snp.bottom).offset(-4)
            make.trailing.equalTo(nameLabel.snp.trailing)
        }
    }

    func configure(with agent: Agent) { // Placeholder
        avatarImageView.image = UIImage(named: agent.avatar)
        nameLabel.text = agent.name
        descriptionLabel.text = agent.description
    }
}

struct Agent { // Placeholder
    let avatar: String
    let name: String
    let description: String
}
