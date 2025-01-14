//
//  AgentSettingInfoViewController.swift
//  Agent
//
//  Created by qinhui on 2024/10/31.
//

import UIKit
import Common

class AgentSettingInfoView: UIView {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let content1Title = UILabel()
    private let contentView1 = UIView()
    private let agentItem = AgentSettingTableItemView(frame: .zero)
    private let roomItem = AgentSettingTableItemView(frame: .zero)
    private let roomIDItem = AgentSettingTableItemView(frame: .zero)
    private let idItem = AgentSettingTableItemView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        createViews()
        createConstrains()
        updateStatus()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createViews()
        createConstrains()
        updateStatus()
    }
    
    func updateStatus() {
        let manager = AgentSettingManager.shared
        
        // Update Agent Status
        agentItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.agentStatus
        agentItem.detialLabel.text = manager.agentStatus == .unload ? "" : manager.agentStatus.rawValue
        agentItem.detialLabel.textColor = manager.agentStatus.color
        agentItem.bottomLineStyle2()
        
        // Update Room Status
        roomItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomStatus
        roomItem.detialLabel.text = manager.roomStatus == .unload ? "" : manager.roomStatus.rawValue
        roomItem.detialLabel.textColor = manager.roomStatus.color
        roomItem.bottomLineStyle2()
        
        // Update Room ID
        roomIDItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomId
        roomIDItem.detialLabel.text = manager.roomId
        roomIDItem.detialLabel.textColor = PrimaryColors.c_ffffff_a
        roomIDItem.bottomLineStyle2()
        
        // Update Participant ID
        idItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourId
        idItem.detialLabel.text = manager.agentStatus == .unload ? "" : manager.yourId
        idItem.detialLabel.textColor = PrimaryColors.c_ffffff_a
        idItem.bottomLineStyle2()
    }
    
    private func createViews() {
        backgroundColor = PrimaryColors.c_1d1d1d
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        content1Title.text = ResourceManager.L10n.ChannelInfo.title
        content1Title.textColor = PrimaryColors.c_ffffff_a
        contentView.addSubview(content1Title)
        
        contentView1.backgroundColor = PrimaryColors.c_141414
        contentView1.layerCornerRadius = 10
        contentView1.layer.borderWidth = 1
        contentView1.layer.borderColor = PrimaryColors.c_262626.cgColor
        contentView.addSubview(contentView1)
        
        agentItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.agentStatus
        agentItem.detialLabel.textColor = PrimaryColors.c_36b37e
        agentItem.backgroundColor = PrimaryColors.c_141414
        agentItem.imageView.isHidden = true
        contentView1.addSubview(agentItem)
        
        roomItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomStatus
        roomItem.detialLabel.textColor = PrimaryColors.c_36b37e
        roomItem.backgroundColor = PrimaryColors.c_141414
        roomItem.imageView.isHidden = true

        contentView1.addSubview(roomItem)
        
        roomIDItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomId
        roomIDItem.imageView.isHidden = true
        roomIDItem.backgroundColor = PrimaryColors.c_141414
        contentView1.addSubview(roomIDItem)
        
        idItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourId
        idItem.bottomLine.isHidden = true
        idItem.backgroundColor = PrimaryColors.c_141414
        idItem.imageView.isHidden = true
        contentView1.addSubview(idItem)
    }
    
    private func createConstrains() {
        scrollView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.width.equalTo(self)
            make.left.right.top.bottom.equalToSuperview()
        }
        content1Title.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.left.equalTo(20)
        }
        contentView1.snp.makeConstraints { make in
            make.top.equalTo(content1Title.snp.bottom).offset(8)
            make.left.equalTo(8)
            make.right.equalTo(-8)
        }
        agentItem.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        roomItem.snp.makeConstraints { make in
            make.top.equalTo(agentItem.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        roomIDItem.snp.makeConstraints { make in
            make.top.equalTo(roomItem.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        idItem.snp.makeConstraints { make in
            make.top.equalTo(roomIDItem.snp.bottom)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
    }
}
