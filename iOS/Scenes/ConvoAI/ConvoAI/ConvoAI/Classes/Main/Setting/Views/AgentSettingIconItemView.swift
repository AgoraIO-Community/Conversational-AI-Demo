//
//  AgentSettingView.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/30.
//

import UIKit
import Common
import SVProgressHUD

class AgentSettingIconItemView: UIView {
    let titleLabel = UILabel()
    let imageView = UIImageView(image: UIImage.ag_named("ic_agent_setting_tab"))
    let bottomLine = UIView()
    let button = UIButton(type: .custom)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createViews()
        createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onClickButton(_ sender: UIButton) {
        print("click button")
    }
    
    public func startLoading() {
        // loadingImageView start rotating
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(value: Double.pi * 2)
        rotationAnimation.duration = 1
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = Float.greatestFiniteMagnitude
        imageView.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    public func stopLoading() {
        imageView.layer.removeAllAnimations()
    }
    
    public func setEnabled(isEnabled: Bool) {
        if isEnabled {
            button.isEnabled = true
            titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
            imageView.tintColor = UIColor.themColor(named: "ai_icontext1")
        } else {
            button.isEnabled = false
            titleLabel.textColor = UIColor.themColor(named: "ai_icontext3")
            imageView.tintColor = UIColor.themColor(named: "ai_icontext3")
        }
    }
}

extension AgentSettingIconItemView {
    private func createViews() {
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.themColor(named: "ai_block2")

        titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        addSubview(titleLabel)
        
        addSubview(imageView)
        
        bottomLine.backgroundColor = UIColor.themColor(named: "ai_line1")
        addSubview(bottomLine)
        
        addSubview(button)
    }
    
    private func createConstrains() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        bottomLine.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalToSuperview()
        }
        button.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
}
