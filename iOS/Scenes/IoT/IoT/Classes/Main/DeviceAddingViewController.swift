//
//  DeviceAddingViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/6.
//

import UIKit
import Common
import SVProgressHUD
import BLEManager

class DeviceAddingViewController: BaseViewController {
    var wifiName: String = ""
    var password: String = ""
    var deviceId: String = ""
    var deviceName: String = ""
    
    private let apiManger = IOTApiManager()
    private var bluetoothManager: AIBLEManager = .shared

    private var rotatingGradientLayer: CAGradientLayer?
    
    private lazy var circleBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_block1")
        view.layer.cornerRadius = 225 / 2.0
        view.layer.masksToBounds = false
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage.ag_named("ic_iot_mascot_icon")
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupConstraints()
        setupRotatingBorder()
        startRotationAnimation()
        prepareToAddDevice()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bluetoothManager.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bluetoothManager.delegate = nil
    }
    
    private func setupView() {
        navigationTitle = ResourceManager.L10n.Iot.deviceAddTitle
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        [circleBackgroundView, iconImageView].forEach { view.addSubview($0) }
    }
    
    private func setupConstraints() {
        circleBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom).offset(121)
            make.width.height.equalTo(225)
            make.centerX.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalTo(circleBackgroundView)
            make.width.equalTo(119)
            make.height.equalTo(168)
        }
    }
    
    private func setupRotatingBorder() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: -2, y: -2, width: 229, height: 229)
        gradientLayer.cornerRadius = 229 / 2.0
        
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(0.8).cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor
        ]
        
        gradientLayer.locations = [0.0, 0.2, 0.4, 1.0]
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = gradientLayer.bounds
        maskLayer.path = UIBezierPath(ovalIn: gradientLayer.bounds).cgPath
        maskLayer.lineWidth = 4
        maskLayer.strokeColor = UIColor.white.cgColor
        maskLayer.fillColor = UIColor.clear.cgColor
        
        gradientLayer.mask = maskLayer
        
        circleBackgroundView.layer.addSublayer(gradientLayer)
        rotatingGradientLayer = gradientLayer
    }
    
    private func startRotationAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 2.0
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        
        rotatingGradientLayer?.add(rotation, forKey: "rotationAnimation")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let gradientLayer = rotatingGradientLayer {
            gradientLayer.position = CGPoint(x: circleBackgroundView.bounds.midX, y: circleBackgroundView.bounds.midY)
        }
    }
    
    private func prepareToAddDevice() {
        addLog("[Call] prepareToAddDevice")
        SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Iot.deviceAddProgress)
        bluetoothManager.getDeviceId {[weak self] deviceId in
            guard let self = self else { return }
            self.addLog("device id: \(deviceId ?? "")")
            if let deviceId = deviceId {
                self.addDevice(deviceId: deviceId)
            }
        }
    }
    
    private func updateSettings(deviceId: String, presetName: String, asrLanguage: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            apiManger.updateSettings(deviceId: deviceId, presetName: presetName, asrLanguage: asrLanguage, aivad: false) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func requestToken(deviceId: String) async throws -> CovIotTokenModel {
        return try await withCheckedThrowingContinuation { continuation in
            apiManger.generatorToken(deviceId: deviceId) { tokenModel, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let tokenModel = tokenModel else {
                    let error = NSError(
                        domain: "DeviceAddingViewController",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Token generation failed, token is empty"]
                    )
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: tokenModel)
            }
        }
    }
    
    private func showSuccessAlert() {
        addLog("[Call] showSuccessAlert, add device success")
        TimeoutAlertView.show(
            in: view,
            image: UIImage.ag_named("ic_alert_success_icon"),
            title: ResourceManager.L10n.Iot.deviceAddSuccessTitle,
            description: ResourceManager.L10n.Iot.deviceAddSuccessDescription
        ) { [weak self] in
            guard let self = self else { return }
            
            // Find and pop to IOTListViewController
            if let targetVC = self.navigationController?.viewControllers.first(where: { $0 is IOTListViewController }) {
                self.navigationController?.popToViewController(targetVC, animated: true)
            }
        }
    }
    
    private func showErrorAlert() {
        addLog("[Call] showErrorAlert, add device failed")
        let errorAlert = IOTErrorAlertViewController { [weak self] in
            guard let self = self else { return }
            self.goToDeviceViewController()
        } onClose: { [weak self] in
            guard let self = self else { return }
            self.goToDeviceViewController()
        }

        present(errorAlert, animated: false)
    }
    
    private func goToDeviceViewController() {
        if let targetVC = self.navigationController?.viewControllers.first(where: { $0 is IOTListViewController }) {
            self.navigationController?.popToViewController(targetVC, animated: true)
        }
    }
    
    private func addDevice(deviceId: String) {
        Task {
            do {
                let tokenModel = try await requestToken(deviceId: deviceId)
                
                guard let preset = AppContext.iotPresetsManager()?.allPresets()?.first,
                      let defaultLanguage = preset.support_languages.first(where: { $0.isDefault }) else {
                    return
                }
                
                try await updateSettings(deviceId: deviceId, presetName: preset.preset_name, asrLanguage: defaultLanguage.code)
                addLog("ssid: \(wifiName), pwd: \(password)")
                bluetoothManager.sendWifiInfo(BLENetworkConfigInfo(
                    ssid: wifiName,
                    password: password,
                    url: AppContext.shared.baseServerUrl,
                    authToken: tokenModel.auth_token
                ))
                
                await MainActor.run {
                    AppContext.iotDeviceManager()?.addDevice(device: LocalDevice(
                        name: deviceName,
                        deviceId: deviceId,
                        rssi: wifiName,
                        currentPreset: preset,
                        currentLanguage: defaultLanguage,
                        aiVad: false
                    ))
                    showSuccessAlert()
                }
            } catch {
                addLog("add device error: \(error)")
                showErrorAlert()
            }
        }
    }
}

extension DeviceAddingViewController: BLEManagerDelegate {
    func bleManagerdidUpdateNotification(manager: AIBLEManager, opcode: Int, statusCode: UInt, payload: Data) {
        addLog("[Call] bleManagerdidUpdateNotification optcode: \(opcode), statusCode: \(statusCode)")
    }
    
    func bleManagerOnDevicConfigError(manager: AIBLEManager, error: Error) {
        addLog("[Call] bleManagerOnDevicConfigError: \(error)")
        showErrorAlert()
    }
}
