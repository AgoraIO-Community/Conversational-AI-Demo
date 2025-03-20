//
//  AgentSettingTopView.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/7.
//

import UIKit
import Common

class AgentSettingTopView: UIView {
    private let leftTitleLabel = UILabel()
    private let closeButton = UIButton(type: .custom)
    
    var onCloseButtonTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createViews()
        createConstrains()
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createViews()
        createConstrains()
    }
    
    private func createViews() {
        backgroundColor = UIColor.themColor(named: "ai_fill2")
        
        leftTitleLabel.textColor = .white
        leftTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        addSubview(leftTitleLabel)
        
        closeButton.setImage(UIImage.ag_named("ic_agent_setting_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(onClickClose(_:)), for: .touchUpInside)
        addSubview(closeButton)
    }
    
    private func createConstrains() {
        leftTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
    }
    
    public func setTitle(title: String) {
        leftTitleLabel.text = title
    }
    
    @objc private func onClickClose(_ sender: UIButton) {
        onCloseButtonTapped?()
    }
}
