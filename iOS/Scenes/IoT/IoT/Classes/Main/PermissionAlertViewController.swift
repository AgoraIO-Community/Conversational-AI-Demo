//
//  PermissionAlertViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/5.
//

import UIKit
import Common

class PermissionAlertViewController: UIViewController {
    
    // MARK: - Properties
    
    private var permissions: [Permission] = []
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_block2")
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private lazy var warningIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.ag_named("ic_iot_warning_icon")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var warningCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_line2")
        view.layer.cornerRadius = 125 / 2.0
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.permissionTitle
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.permissionDescription
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var permissionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_iot_close_icon"), for: .normal)
        button.backgroundColor = UIColor.themColor(named: "ai_fill2")
        button.layer.cornerRadius = 15  // Will be a 30x30 circle
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    
    init(title: String = ResourceManager.L10n.Iot.permissionTitle,
         description: String = ResourceManager.L10n.Iot.permissionDescription,
         permissions: [Permission]) {
        self.permissions = permissions
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        
        // Update labels
        titleLabel.text = title
        descriptionLabel.text = description
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPermissionCards()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        view.addSubview(containerView)
        containerView.addSubview(warningCircleView)
        warningCircleView.addSubview(warningIconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(permissionsStackView)
        containerView.addSubview(closeButton)
        
        containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
        
        warningCircleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(56)
            make.size.equalTo(CGSize(width: 125, height: 125))
        }
        
        warningIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-27)
            make.size.equalTo(CGSize(width: 70, height: 70))
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.right.equalTo(-16)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(warningCircleView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
        }
        
        permissionsStackView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(-50)
        }
    }
    
    private func setupPermissionCards() {
        permissions.forEach { permission in
            let cardView = createPermissionCard(permission: permission)
            permissionsStackView.addArrangedSubview(cardView)
        }
    }
    
    private func createPermissionCard(permission: Permission) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = permission.cardBackgroundColor
        cardView.layer.cornerRadius = 12
        
        let iconBackground = UIView()
        iconBackground.backgroundColor = permission.iconBackgroundColor
        iconBackground.layer.cornerRadius = 20
        
        let iconImageView = UIImageView()
        iconImageView.image = permission.icon
        iconImageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = permission.title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let goButton = UIButton(type: .custom)
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        configuration.baseForegroundColor = permission.cardBackgroundColor
        configuration.background.backgroundColor = .white
        
        var container = AttributeContainer()
        container.font = .systemFont(ofSize: 14, weight: .semibold)
        configuration.attributedTitle = AttributedString(ResourceManager.L10n.Iot.permissionGoButton, attributes: container)
        
        goButton.configuration = configuration
        goButton.layer.cornerRadius = 7
        goButton.addTarget(self, action: #selector(goButtonTapped(_:)), for: .touchUpInside)
        goButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        goButton.setContentHuggingPriority(.required, for: .horizontal)
        
        cardView.addSubview(iconBackground)
        iconBackground.addSubview(iconImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(goButton)
        
        iconBackground.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        goButton.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconBackground.snp.right).offset(12)
            make.right.equalTo(goButton.snp.left).offset(-12)
            make.centerY.equalToSuperview()
        }
        
        cardView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(72)
        }
        
        return cardView
    }
    
    // MARK: - Animations
    
    private func animateIn() {
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.3) {
            self.containerView.transform = .identity
        }
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        }, completion: { _ in
            completion()
        })
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
        }
    }
    
    @objc private func goButtonTapped(_ sender: UIButton) {
        // Handle permission request
        if let index = permissionsStackView.arrangedSubviews.firstIndex(where: { $0.subviews.contains(sender) }) {
            let permission = permissions[index]
            permission.action()
        }
    }
}

// MARK: - Permission Model

extension PermissionAlertViewController {
    struct Permission {
        let icon: UIImage?
        let iconBackgroundColor: UIColor
        let cardBackgroundColor: UIColor
        let title: String
        let action: () -> Void
    }
}
