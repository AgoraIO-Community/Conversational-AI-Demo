//
//  DeviceSearchFailedView.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/6.
//

import UIKit
import Common

protocol DeviceSearchFailedViewDelegate: AnyObject {
    func researchCallback()
}

class DeviceSearchFailedView: UIView {
    weak var delegate: DeviceSearchFailedViewDelegate?
    
    // MARK: - UI Components
    
    private lazy var warningIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.ag_named("ic_iot_warning_icon")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.deviceSearchFailedTitle
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.deviceSearchFailedDescription
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Iot.deviceSearchFailedRetry, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor.themColor(named: "ai_brand_main6")
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.deviceSearchFailedTip
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupViews() {
        backgroundColor = UIColor.themColor(named: "ai_fill2")

        [warningIconView, titleLabel, descriptionLabel, tipLabel, retryButton].forEach { addSubview($0) }
    }
    
    func setupConstraints() {
        warningIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(70)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(warningIconView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
        }
        
        retryButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(30)
            make.bottom.equalTo(-56)
            make.height.equalTo(50)
        }
        
        tipLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(30)
            make.bottom.equalTo(retryButton.snp.top).offset(-24)
        }
    }
    
    // MARK: - Actions
    
    @objc private func retryButtonTapped() {
        // Handle retry button tap
        delegate?.researchCallback()
    }
}
