//
//  IOTWifiConfigViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/7.
//

import UIKit
import Common
import CoreBluetooth
import BLEManager

class IOTWifiSettingViewController: BaseViewController {
    
    // MARK: - Properties
    var device: BLEDevice?
    private let wifiManager = WiFiManager()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        let text = ResourceManager.L10n.Iot.wifiSettingsTitle
        let attributedString = NSMutableAttributedString(string: text)
        let range = (text as NSString).range(of: "2.4GHz")
        attributedString.addAttribute(.foregroundColor,
                                    value: UIColor.themColor(named: "ai_green6"),
                                    range: range)
        label.attributedText = attributedString
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.wifiSettingsSubtitle
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.wifiSettingsTip
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_green6")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var wifiImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.ag_named("ic_iot_wifi_tips_icon")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var wifiErrorLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.wifiSettingsError
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.isHidden = true
        return label
    }()
    
    private lazy var wifiNameField: UITextField = {
        let field = UITextField()
        field.backgroundColor = UIColor.themColor(named: "ai_block1")
        field.text = ""
        field.textColor = UIColor.themColor(named: "ai_icontext1")
        field.font = .systemFont(ofSize: 16)
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.layer.cornerRadius = 8
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
        field.isEnabled = false
        return field
    }()
    
    private lazy var switchNetworkButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Iot.wifiSettingsSwitch, for: .normal)
        button.setTitleColor(UIColor.themColor(named: "ai_icontext1"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.backgroundColor = UIColor.themColor(named: "ai_line2")
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(switchNetworkButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var passwordField: UITextField = {
        let field = UITextField()
        field.backgroundColor = UIColor.themColor(named: "ai_block1")
        field.placeholder = ResourceManager.L10n.Iot.wifiSettingsPasswordPlaceholder
        field.textColor = UIColor.themColor(named: "ai_icontext1")
        field.font = .systemFont(ofSize: 16)
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.layer.cornerRadius = 8
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
        field.isSecureTextEntry = true
        field.addTarget(self, action: #selector(passwordFieldDidChange), for: .editingChanged)
        return field
    }()
    
    private lazy var passwordVisibilityButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_password_invisible"), for: .normal)
        button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Iot.wifiSettingsNext, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.themColor(named: "ai_brand_main6")
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var keyboardHeight: CGFloat = 0
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        updateNextButtonState()
        setupKeyboardHandling()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    private func setupViews() {
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        naviBar.backgroundColor = UIColor.themColor(named: "ai_fill1")
        
        view.addSubview(contentView)
        [titleLabel, subtitleLabel, tipLabel, wifiImageView, wifiNameField, switchNetworkButton,
         passwordField, passwordVisibilityButton, nextButton, wifiErrorLabel].forEach { contentView.addSubview($0) }
        
        // Add right view to password field
        let rightViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 48))
        rightViewContainer.addSubview(passwordVisibilityButton)
        passwordVisibilityButton.frame = CGRect(x: 8, y: 12, width: 24, height: 24)
        passwordField.rightView = rightViewContainer
        passwordField.rightViewMode = .always
        view.bringSubviewToFront(naviBar)
    }
    
    private func setupConstraints() {
        contentView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.centerX.equalToSuperview()
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.centerX.equalToSuperview()
        }
        
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }
        
        wifiImageView.snp.makeConstraints { make in
            make.top.equalTo(tipLabel.snp.bottom).offset(20)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.height.equalTo(wifiImageView.snp.width).multipliedBy(199.0 / 315.0)
        }
        
        wifiNameField.snp.makeConstraints { make in
            make.top.equalTo(wifiImageView.snp.bottom).offset(20)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.height.equalTo(48)
        }
        
        switchNetworkButton.snp.makeConstraints { make in
            make.centerY.equalTo(wifiNameField)
            make.right.equalTo(wifiNameField.snp.right).offset(-6)
            make.width.equalTo(56)
            make.height.equalTo(36)
        }
        
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(wifiNameField.snp.bottom).offset(32)
            make.left.right.height.equalTo(wifiNameField)
        }
        
        nextButton.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(40)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.height.equalTo(50)
        }
        
        wifiErrorLabel.snp.makeConstraints { make in
            make.top.equalTo(wifiNameField.snp.bottom).offset(8)
            make.left.equalTo(wifiNameField).offset(16)
        }
    }
    
    private func updateNextButtonState() {
        // let isValidWifi = !is5GWifi(ssid: wifiNameField.text ?? "")
        let password = passwordField.text ?? ""
        let hasValidPassword = password.count >= 8
        nextButton.isEnabled = hasValidPassword
        
        // Update button opacity based on enabled state
        nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.5
    }
    
    private func is5GWifi(ssid: String) -> Bool {
        return ssid.lowercased().contains("5g")
    }
    
    private func updateWifiNameField(with ssid: String) {
        wifiNameField.text = ssid
        wifiNameField.textColor = UIColor.themColor(named: "ai_icontext1")
        updateNextButtonState()
    }
    
    private func setupKeyboardHandling() {
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillShow),
                                             name: UIResponder.keyboardWillShowNotification,
                                             object: nil)
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillHide),
                                             name: UIResponder.keyboardWillHideNotification,
                                             object: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        let passwordFieldBottom = passwordField.convert(passwordField.bounds, to: view).maxY
        let keyboardTop = view.frame.height - keyboardHeight
        
        // Calculate overlap
        let overlap = passwordFieldBottom - keyboardTop + 20 // Add 20pt padding
        
        if overlap > 0 {
            UIView.animate(withDuration: 0.3) {
                self.contentView.transform = CGAffineTransform(translationX: 0, y: -overlap)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.contentView.transform = .identity
        }
    }
    
    // MARK: - Actions
    @objc private func switchNetworkButtonTapped() {
        // Use Settings URL with specific path for WiFi
        if let wifiUrl = URL(string: "App-Prefs:root=WIFI") {
            if UIApplication.shared.canOpenURL(wifiUrl) {
                UIApplication.shared.open(wifiUrl)
            } else {
                // Fallback to general settings if direct WiFi access is not available
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        }
    }
    
    @objc private func togglePasswordVisibility() {
        passwordField.isSecureTextEntry.toggle()
        let image = passwordField.isSecureTextEntry ? "ic_password_invisible" : "ic_password_visible"
        passwordVisibilityButton.setImage(UIImage.ag_named(image), for: .normal)
    }
    
    @objc private func passwordFieldDidChange(_ textField: UITextField) {
        updateNextButtonState()
    }
    
    @objc private func nextButtonTapped() {
        guard let device = self.device else { return }
        // Handle next button tap
        let vc = DeviceAddingViewController()
        vc.wifiName = wifiNameField.text ?? ""
        vc.password = passwordField.text ?? ""
        vc.device = device
        self.navigationController?.pushViewController(vc)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(applicationDidEnterBackground),
                                             name: UIApplication.didEnterBackgroundNotification,
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(applicationWillEnterForeground),
                                             name: UIApplication.willEnterForegroundNotification,
                                             object: nil)
    }
    
    @objc private func applicationDidEnterBackground() {
        // Handle background state if needed in the future
    }
    
    @objc private func applicationWillEnterForeground() {
        // Check WiFi SSID when app comes to foreground
        if let currentSSID = getCurrentWiFiSSID() {
            updateWifiNameField(with: currentSSID)
        } else {
            updateWifiNameField(with: "")
        }
    }
}

// MARK: - WiFi Monitoring
extension IOTWifiSettingViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let currentSSID = getCurrentWiFiSSID() {
            updateWifiNameField(with: currentSSID)
        } else {
            updateWifiNameField(with: "")
        }
    }
    
    private func getCurrentWiFiSSID() -> String? {
        var result: String? = ""
        wifiManager.getWiFiSSID { ssid in
            result = ssid
        }
        return result
    }
}


