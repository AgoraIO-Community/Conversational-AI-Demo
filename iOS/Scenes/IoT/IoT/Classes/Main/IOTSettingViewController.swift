//
//  IOTSettingViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/6.
//

import UIKit
import Common
import SVProgressHUD

class IOTSettingViewController: UIViewController {
    
    // MARK: - Properties
    var deviceId: String = ""
    var reconnectedTap: (() -> ())?
    private var selectedPresetIndex: Int = 0 // Track current selected preset index
    private var currentLanguage: CovIotLanguage?
    private var currentPreset: CovIotPreset?
    private var currentAIVadState: Bool?
    private let iotApiManager = IOTApiManager()

    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill2")
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("iot_setting_close_icon"), for: .normal)
        button.backgroundColor = UIColor.themColor(named: "ai_block1")
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.deviceSettingsTitle
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.bounces = false  // Disable bouncing effect
        scrollView.alwaysBounceVertical = false  // Disable vertical bounce
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
        
    private lazy var presetLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.deviceSettingsPreset
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor.themColor(named: "ai_icontext4")
        return label
    }()
    
    private lazy var presetContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
        return view
    }()
    
    private lazy var presetStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()
    
    private lazy var languageCell: SettingCell = {
        let cell = SettingCell()
        cell.titleLabel.text = ResourceManager.L10n.Iot.deviceSettingsLanguage
        cell.detailLabel.text = "English"  // 默认值
        
        let button = UIButton()
        cell.addSubview(button)
        button.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.top.bottom.equalTo(0)
            make.left.equalTo(cell.detailLabel.snp.left)
        }
        button.showsMenuAsPrimaryAction = true
        
        return cell
    }()
    
    private lazy var advancedLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.deviceSettingsAdvanced
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.themColor(named: "ai_icontext2")
        return label
    }()
    
    private lazy var interruptSwitch: SettingCell = {
        let cell = SettingCell()
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.themColor(named: "ai_icontext1")
        ]
        
        let highlightAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.themColor(named: "ai_brand_lightbrand6")
        ]
        
        let text = ResourceManager.L10n.Iot.deviceSettingsInterrupt
        let attributedString = NSMutableAttributedString(
            string: text,
            attributes: normalAttributes
        )
        
        if text.count >= 4 {
            if let range = text.range(of: ResourceManager.L10n.Iot.deviceSettingsInterruptMatchWord) {
                let nsRange = NSRange(range, in: text)
                attributedString.addAttributes(highlightAttributes, range: nsRange)
            }
        }
        
        cell.titleLabel.attributedText = attributedString
        
        cell.setupAsSwitch()
        
        if let device = AppContext.iotDeviceManager()?.getDevice(deviceId: deviceId) {
            cell.switchControl.isOn = device.aiVad
        }
        
        cell.switchTapCallback = { [weak self] isOn in
            guard let self = self else { return }
            self.currentAIVadState = isOn
        }
        
        return cell
    }()
    
    private lazy var reconnectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Iot.deviceSettingsReconnect, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.backgroundColor = UIColor.themColor(named: "ai_block2")
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(reconnectButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Iot.deviceSettingsDelete, for: .normal)
        button.setTitleColor(UIColor.themColor(named: "ai_brand_white10"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.backgroundColor = UIColor.themColor(named: "ai_red6")
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var grabberView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_line2")
        view.layer.cornerRadius = 1.5
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupPresetModes()
        setupLanguageMenu()
        
        // Disable interactive dismissal
        isModalInPresentation = true
    }
    
    // MARK: - UI Setup
    
    private func setupViews() {
        view.backgroundColor = .clear
                
        view.addSubview(containerView)
        containerView.addSubview(grabberView)
        containerView.addSubview(closeButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scrollView)
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(presetContainerView)
        presetContainerView.addSubview(presetStackView)
        
        [presetLabel, presetContainerView, languageCell, advancedLabel, interruptSwitch, reconnectButton, deleteButton].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(view.snp.height).multipliedBy(0.85)
        }
        
        grabberView.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(36)
            make.height.equalTo(3)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.right.equalTo(-16)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(32)
            make.left.equalTo(20)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        presetLabel.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.left.equalTo(20)
        }
        
        presetContainerView.snp.makeConstraints { make in
            make.top.equalTo(presetLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
        }
        
        presetStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        languageCell.snp.makeConstraints { make in
            make.top.equalTo(presetStackView.snp.bottom).offset(24)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        
        advancedLabel.snp.makeConstraints { make in
            make.top.equalTo(languageCell.snp.bottom).offset(24)
            make.left.equalTo(20)
        }
        
        interruptSwitch.snp.makeConstraints { make in
            make.top.equalTo(advancedLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        
        reconnectButton.snp.makeConstraints { make in
            make.top.equalTo(interruptSwitch.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(reconnectButton.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalTo(-30)
        }
    }
    
    private func setupPresetModes() {
        guard let presets = AppContext.iotPresetsManager()?.allPresets() else { return }
        guard let currentDevice = AppContext.iotDeviceManager()?.getDevice(deviceId: deviceId) else { return }
        for (index, preset) in presets.enumerated() {
            let isSelected = preset.display_name == currentDevice.currentPreset.display_name
            let cell = createPresetModeCell(
                preset: preset,
                isSelected: isSelected,
                isLastCell: index == presets.count - 1,
                index: index
            )
            presetStackView.addArrangedSubview(cell)
            if isSelected {
                selectedPresetIndex = index
            }
        }
    }
    
    private func setupLanguageMenu() {
        guard let currentDevice = AppContext.iotDeviceManager()?.getDevice(deviceId: deviceId) else { return }
        
        languageCell.detailLabel.text = currentDevice.currentLanguage.name
        currentLanguage = currentDevice.currentLanguage
        
        updateLanguageMenu(with: currentDevice.currentPreset)
    }
    
    private func presetDidChange(preset: CovIotPreset) {
        currentPreset = preset
        
        let currentLanguageName = languageCell.detailLabel.text ?? ""
        let isCurrentLanguageSupported = preset.support_languages.contains { $0.name == currentLanguageName }
        
        if !isCurrentLanguageSupported, let defaultLanguage = preset.support_languages.first(where: { $0.isDefault }) {
            languageCell.detailLabel.text = defaultLanguage.name
            currentLanguage = defaultLanguage
        }
        
        updateLanguageMenu(with: preset)
    }
    
    private func updateLanguageMenu(with preset: CovIotPreset) {
        guard let button = languageCell.subviews.first(where: { $0 is UIButton }) as? UIButton else { return }
        let actions = preset.support_languages.map { language in
            let isSelected = language.name == languageCell.detailLabel.text
            return UIAction(
                title: language.name,
                state: isSelected ? .on : .off
            ) { [weak self] _ in
                guard let self = self else { return }
                self.languageCell.detailLabel.text = language.name
                self.currentLanguage = language
            }
        }
        
        button.menu = UIMenu(title: "", options: .singleSelection, children: actions)
    }
    
    private func createPresetModeCell(
        preset: CovIotPreset,
        isSelected: Bool = false,
        isLastCell: Bool = false,
        index: Int
    ) -> PresetModeCell {
        let cell = PresetModeCell()
        cell.configure(title: preset.display_name, description: preset.preset_brief, isSelected: isSelected, isLastCell: isLastCell)
        cell.tag = index
        cell.onCheckChanged = { [weak self] isSelected in
            self?.handlePresetSelection(at: index, isSelected: isSelected)
            self?.presetDidChange(preset: preset)
        }
        return cell
    }
    
    private func handlePresetSelection(at index: Int, isSelected: Bool) {
        guard isSelected else { return } // Only handle selection event, ignore deselection
        
        // Update previously selected cell
        if let previousCell = presetStackView.arrangedSubviews[selectedPresetIndex] as? PresetModeCell {
            previousCell.setSelected(false)
        }
        
        // Update currently selected cell
        if let currentCell = presetStackView.arrangedSubviews[index] as? PresetModeCell {
            currentCell.setSelected(true)
        }
        
        selectedPresetIndex = index
    }
    
    private func updateLocalDevie() {
        if let preset = self.currentPreset {
            AppContext.iotDeviceManager()?.updatePreset(preset: preset, deviceId: self.deviceId)
        }
        if let language = self.currentLanguage {
            AppContext.iotDeviceManager()?.updateLanguage(language: language, deviceId: self.deviceId)
        }
        if let aivad = self.currentAIVadState {
            AppContext.iotDeviceManager()?.updateAIVad(aivad: aivad, deviceId: self.deviceId)
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        guard let device = AppContext.iotDeviceManager()?.getDevice(deviceId: deviceId) else { return }
        
        let hasPresetChange = currentPreset != nil && currentPreset?.display_name != device.currentPreset.display_name
        let hasLanguageChange = currentLanguage != nil && currentLanguage?.name != device.currentLanguage.name
        let hasAivadChange = currentAIVadState != nil && currentAIVadState != device.aiVad
        
        if !hasPresetChange && !hasLanguageChange && !hasAivadChange {
            dismiss(animated: true)
            return
        }
        
        AgentAlertView.show(
            in: view,
            title: ResourceManager.L10n.Iot.deviceSettingsSaveTitle,
            content: ResourceManager.L10n.Iot.deviceSettingsSaveDescription,
            cancelTitle: ResourceManager.L10n.Iot.deviceSettingsSaveDiscard,
            confirmTitle: ResourceManager.L10n.Iot.deviceSettingsSaveConfirm
        ) { [weak self] in
            guard let self = self else { return }
            
            var presetName = device.currentPreset.preset_name
            var languageCode = device.currentLanguage.code
            var aivadState = device.aiVad
            
            if hasPresetChange, let preset = self.currentPreset {
                presetName = preset.preset_name
            }
            
            if hasLanguageChange, let language = self.currentLanguage {
                languageCode = language.code
            }
            
            if hasAivadChange, let aivad = self.currentAIVadState {
                aivadState = aivad
            }
            
            SVProgressHUD.show()
            self.iotApiManager.updateSettings(deviceId: self.deviceId, presetName: presetName, asrLanguage: languageCode, aivad: aivadState) { [weak self] error in
                SVProgressHUD.dismiss()
                guard let self = self else { return }
                if let error = error {
                    SVProgressHUD.showError(withStatus: error.message)
                } else {
                    self.updateLocalDevie()
                }
                
                self.dismiss(animated: true)
            }
            
        } onCancel: { [weak self] in
            self?.dismiss(animated: true)
        }
    }
    
    @objc private func reconnectButtonTapped() {
        // Handle reconnect
        self.dismiss(animated: false)
        reconnectedTap?()
    }
    
    @objc private func deleteButtonTapped() {
        guard let device = AppContext.iotDeviceManager()?.getDevice(deviceId: deviceId) else { return }
        
        AgentAlertView.show(
            in: view,
            title: String(format: ResourceManager.L10n.Iot.deviceSettingsDeleteTitle, "\"\(device.name)\""),
            content: ResourceManager.L10n.Iot.deviceSettingsDeleteDescription,
            cancelTitle: "取消",
            confirmTitle: ResourceManager.L10n.Iot.deviceSettingsDeleteConfirm,
            onConfirm: { [weak self] in
                guard let self = self else { return }
                AppContext.iotDeviceManager()?.removeDevice(deviceId: self.deviceId)
                self.dismiss(animated: true)
        })
    }
}

// MARK: - SettingCell
private class SettingCell: UIControl {
    var switchTapCallback: ((Bool) -> Void)?
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.themColor(named: "ai_icontext3")
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
        view.backgroundColor = UIColor.themColor(named: "ai_block2")

        return view
    }()
    
    let switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor.themColor(named: "ai_brand_main6")
        return switchControl
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.ag_named("ic_iot_arrow_right")
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(detailLabel)
        containerView.addSubview(arrowImageView)
        
        containerView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.bottom.equalTo(0)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        
        detailLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowImageView.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
    }
    
    @objc func switcherValueChanged(_ sender: UISwitch) {
        switchTapCallback?(sender.isOn)
    }
    
    func setupAsSwitch() {
        arrowImageView.removeFromSuperview()
        detailLabel.removeFromSuperview()
        
        containerView.addSubview(switchControl)
        switchControl.onTintColor = UIColor.themColor(named: "ai_brand_lightbrand6")
        switchControl.backgroundColor = UIColor.themColor(named: "ai_brand_white10")
        switchControl.layer.cornerRadius = switchControl.frame.height / 2
        switchControl.clipsToBounds = true
        switchControl.addTarget(self, action: #selector(switcherValueChanged(_:)), for: .valueChanged)
        
        switchControl.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupAsDeviceName() {
        arrowImageView.removeFromSuperview()
        detailLabel.removeFromSuperview()
        
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - PresetModeCell
private class PresetModeCell: UIView {
    var onCheckChanged: ((Bool) -> Void)?

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_block2")
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.themColor(named: "ai_icontext3")
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var checkmarkView: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.ag_named("ic_iot_uncheck_icon"), for: .normal)
        button.setImage(UIImage.ag_named("ic_iot_check_icon"), for: .selected)
        button.addTarget(self, action: #selector(cellTapped), for: .touchUpInside)

        return button
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_line1")
        return view
    }()
    
    private lazy var overlayButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(cellTapped), for: .touchUpInside)
        return button
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        [titleLabel, descriptionLabel, checkmarkView, separatorLine].forEach { containerView.addSubview($0) }
        containerView.addSubview(overlayButton)
        
        checkmarkView.isUserInteractionEnabled = false
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(16)
            make.right.equalTo(checkmarkView.snp.left).offset(-8)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(16)
            make.right.equalTo(checkmarkView.snp.left).offset(-8)
            make.bottom.equalTo(-16)
        }
        
        checkmarkView.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        separatorLine.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.left.equalTo(16)
            make.height.equalTo(1)
        }
        
        overlayButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
        
    @objc private func cellTapped() {
        // If already selected, do nothing
        guard !checkmarkView.isSelected else { return }
        
        checkmarkView.isSelected = true
        onCheckChanged?(true)
    }
    
    func setSelected(_ selected: Bool) {
        checkmarkView.isSelected = selected
    }
    
    func configure(title: String, description: String, isSelected: Bool, isLastCell: Bool = false) {
        titleLabel.text = title
        descriptionLabel.text = description
        checkmarkView.isSelected = isSelected
        separatorLine.isHidden = isLastCell
    }
}


