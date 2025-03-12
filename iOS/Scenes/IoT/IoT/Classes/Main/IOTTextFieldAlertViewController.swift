//
//  IOTTextFieldAlertViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/11.
//

import Foundation
import Common

class IOTTextFieldAlertViewController: UIViewController {
    
    // MARK: - Properties
    var onConfirm: ((String) -> Void)?
    var onCancel: (() -> Void)?
    var defaultText: String = ""
    var maxLength: Int = 10
    
    // MARK: - UI Components
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_block2")
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.themColor(named: "ai_fill1")
        button.layer.cornerRadius = 15
        button.setImage(UIImage.ag_named("ic_iot_close_icon"), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.deviceRename
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        return label
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = UIColor.themColor(named: "ai_input")
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 0.5
        textField.layer.borderColor = UIColor.themColor(named: "ai_line2").cgColor
        textField.textColor = UIColor.themColor(named: "ai_icontext1")
        textField.font = .systemFont(ofSize: 13)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.delegate = self
        textField.placeholder = ResourceManager.L10n.Iot.deviceRenamePlaceholder
        return textField
    }()
    
    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.deviceRenameTips
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.themColor(named: "ai_red6")
        return label
    }()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.themColor(named: "ai_brand_main6")
        button.setTitle(ResourceManager.L10n.Iot.submit, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupInitialState()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }
    
    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .clear
        view.addSubview(backgroundView)
        view.addSubview(containerView)
        
        [closeButton, titleLabel, textField, tipLabel, confirmButton].forEach {
            containerView.addSubview($0)
        }
                
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(16)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.left.equalToSuperview().offset(20)
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(4)
            make.left.equalTo(textField.snp.left).offset(12)
        }
        
        confirmButton.snp.remakeConstraints { make in
            make.top.equalTo(tipLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
    
    private func setupInitialState() {
        textField.text = defaultText
        updateConfirmButtonState(text: defaultText)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let text = textField.text ?? ""
        updateConfirmButtonState(text: text)
    }
    
    private func updateConfirmButtonState(text: String) {
        let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        confirmButton.isEnabled = !isEmpty
        confirmButton.alpha = isEmpty ? 0.5 : 1.0
        tipLabel.isHidden = !isEmpty
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true) {
            self.onCancel?()
        }
    }
    
    @objc private func confirmButtonTapped() {
        guard confirmButton.isEnabled,
              let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        
        dismiss(animated: true) {
            self.onConfirm?(text)
        }
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            
            containerView.snp.updateConstraints { make in
                make.center.equalToSuperview().offset(-keyboardHeight/4)
            }
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension IOTTextFieldAlertViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        DispatchQueue.main.async {
            self.updateConfirmButtonState(text: updatedText)
        }
        
        return updatedText.count <= maxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        confirmButtonTapped()
        return true
    }
}

// MARK: - Public Interface
extension IOTTextFieldAlertViewController {
    static func show(
        in viewController: UIViewController,
        defaultText: String = "",
        maxLength: Int = 10,
        onConfirm: @escaping (String) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let alertVC = IOTTextFieldAlertViewController()
        alertVC.defaultText = defaultText
        alertVC.maxLength = maxLength
        alertVC.onConfirm = onConfirm
        alertVC.onCancel = onCancel
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve
        viewController.present(alertVC, animated: true)
    }
}
