//
//  IotDeviceCardView.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/4.
//

import UIKit
import SnapKit
import Common
import SwifterSwift

class IotDeviceCardView: UIView {
    var onTitleButtonTapped: (() -> Void)?
    var onSettingsTapped: (() -> Void)?
    
    private lazy var titleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(.black, for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var editButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.ag_named("ic_iot_name_edit_icon"), for: .normal)
        button.isHidden = true // Hidden by default
        button.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 25
        if let image = UIImage.ag_named("ic_iot_card_edit_icon") {
            button.setImage(image, for: .normal)
        }
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        button.setBackgroundColor(color: UIColor.themColor(named: "ai_brand_white6"), forState: .normal)
        return button
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    var settingsIcon: UIImage? {
        didSet {
            settingsButton.setImage(settingsIcon, for: .normal)
        }
    }
    
    var backgroundImage: UIImage? {
        didSet {
            backgroundImageView.image = backgroundImage
        }
    }
    
    var settingsButtonBackgroundColor: UIColor? {
        didSet {
            settingsButton.backgroundColor = settingsButtonBackgroundColor
        }
    }
    
    var titleFont: UIFont? {
        didSet {
            titleButton.titleLabel?.font = titleFont
        }
    }
    
    var titleColor: UIColor? {
        didSet {
            titleButton.setTitleColor(titleColor, for: .normal)
        }
    }
    
    var subtitleFont: UIFont? {
        didSet {
            subtitleLabel.font = subtitleFont
        }
    }
    
    var subtitleColor: UIColor? {
        didSet {
            subtitleLabel.textColor = subtitleColor
        }
    }
    
    var showEditIcon: Bool = false {
        didSet {
            editButton.isHidden = !showEditIcon
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(backgroundImageView)
        addSubview(titleButton)
        addSubview(editButton)
        addSubview(subtitleLabel)
        addSubview(settingsButton)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleButton.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(-20)
        }
        
        editButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleButton)
            make.left.equalTo(titleButton.snp.right).offset(5)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleButton.snp.bottom).offset(8)
            make.left.equalTo(titleButton)
        }
        
        settingsButton.snp.makeConstraints { make in
            make.bottom.right.equalTo(-20)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }
    }
    
    @objc private func titleButtonTapped() {
        onTitleButtonTapped?()
    }
    
    @objc private func settingsButtonTapped() {
        onSettingsTapped?()
    }
    
    func configure(title: String, subtitle: String) {
        titleButton.setTitle(title, for: .normal)
        subtitleLabel.text = subtitle
    }
}
