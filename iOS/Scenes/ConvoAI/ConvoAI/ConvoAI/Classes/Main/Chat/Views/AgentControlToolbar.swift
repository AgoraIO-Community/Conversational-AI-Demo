//
//  ChatBottomView.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/7.
//

import UIKit
import Common

enum AgentControlStyle {
    case startButton
    case controlButtons
}

protocol AgentControlToolbarDelegate: AnyObject {
    func hangUp()
    func getStart() async
    func mute(selectedState: Bool) -> Bool
    func switchCaptions(selectedState: Bool)
}

class AgentControlToolbar: UIView {
    weak var delegate: AgentControlToolbarDelegate?
    private let buttonWidth = 76.0
    private let buttonHeight = 76.0
    private let startButtonHeight = 68.0
    private var _style: AgentControlStyle = .startButton
    private var startButtonGradientLayer: CAGradientLayer?
    private var loadingViewGradientLayer: CAGradientLayer?

    var style: AgentControlStyle {
        get {
            return _style
        }
        set {
            _style = newValue
            switch newValue {
            case .startButton:
                startButtonContentView.isHidden = false
                buttonControlContentView.isHidden = true
            case .controlButtons:
                startButtonContentView.isHidden = true
                buttonControlContentView.isHidden = false
            }
        }
    }

    lazy var startButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Join.buttonTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.setTitleColor(UIColor.themColor(named: "ai_brand_white10"), for: .normal)
        
        setupStartButton(button: button)
        
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(startAction), for: .touchUpInside)
        button.setImage(UIImage.ag_named("ic_agent_join_button_icon"), for: .normal)
        
        let spacing: CGFloat = 5
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
        button.clipsToBounds = true
        return button
    }()
    
    private lazy var pointAnimateView: PointAnimationView = {
        let view = PointAnimationView()
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        setupPointAnimateView(view: view)
        view.isHidden = true
        return view
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(hangUpAction), for: .touchUpInside)
        button.layerCornerRadius = buttonWidth / 2.0
        button.clipsToBounds = true
        button.setImage(UIImage.ag_named("ic_agent_close"), for: .normal)
        button.setBackgroundColor(color: UIColor.themColor(named: "ai_block1"), forState: .normal)
        
        return button
    }()
    
    private lazy var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(muteAction(_ :)), for: .touchUpInside)
        button.titleLabel?.textAlignment = .center
        button.layerCornerRadius = buttonWidth / 2.0
        button.clipsToBounds = true
        button.setImage(UIImage.ag_named("ic_agent_unmute"), for: .normal)
        button.setImage(UIImage.ag_named("ic_agent_mute"), for: .selected)
        button.setBackgroundColor(color: UIColor.themColor(named: "ai_block1"), forState: .normal)
        button.setBackgroundColor(color: UIColor.themColor(named: "ai_brand_white10"), forState: .selected)
        return button
    }()
    
    lazy var micProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor.themColor(named: "ai_brand_lightbrand7")
        progressView.trackTintColor = UIColor.themColor(named: "ai_icontext1")
        progressView.layer.cornerRadius = 14.74 * 0.5
        progressView.clipsToBounds = true
        progressView.isUserInteractionEnabled = false
        progressView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        return progressView
    }()
    
    lazy var captionsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(switchCaptionsAction(_ :)), for: .touchUpInside)
        button.titleLabel?.textAlignment = .center
        button.layerCornerRadius = buttonWidth / 2.0
        button.clipsToBounds = true
        button.setImage(UIImage.ag_named("ic_captions_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        if let color = UIColor(hex: 0x333333) {
            button.setBackgroundImage(UIImage(color: color, size: CGSize(width: 1, height: 1)), for: .normal)
        }
        button.tintColor = UIColor.themColor(named: "ai_icontext1")
        button.setBackgroundColor(color: UIColor.themColor(named: "ai_block1"), forState: .normal)

        return button
    }()
    
    private lazy var buttonControlContentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var startButtonContentView: UIView = {
        let view = UIView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
        style = .startButton
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetState() {
        startButton.isEnabled = true
        captionsButton.isEnabled = true
        muteButton.isEnabled = true
        closeButton.isEnabled = true

        captionsButton.isSelected = false
        muteButton.isSelected = false
        captionsButton.isSelected = false
        setTintColor(state: captionsButton.isSelected)
    }
    
    func setEnable(enable: Bool) {
        if style == .startButton {
            startButton.isEnabled = enable
        } else {
            captionsButton.isEnabled = enable
            muteButton.isEnabled = enable
            closeButton.isEnabled = enable
        }
    }
    
    func setVolumeProgress(value: Float) {
        micProgressView.progress = value/255
    }
    
    func setMircophoneButtonSelectState(state: Bool) {
        muteButton.isSelected = state
        micProgressView.isHidden = state
    }
    
    func startLoadingAnimation() {
        pointAnimateView.isHidden = false
        pointAnimateView.startAnimating()
    }
    
    func stopLoadingAnimation() {
        pointAnimateView.stopAnimating()
        pointAnimateView.isHidden = true
    }
    
    private func setupViews() {
        addSubview(buttonControlContentView)
        [captionsButton, muteButton, micProgressView, closeButton].forEach { button in
            buttonControlContentView.addSubview(button)
        }

        addSubview(startButtonContentView)
        startButtonContentView.addSubview(startButton)
        startButtonContentView.addSubview(pointAnimateView)
    }
    
    private func setupConstraints() {
        startButtonContentView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        startButton.snp.makeConstraints { make in
            make.centerY.equalTo(startButtonContentView)
            make.centerX.equalToSuperview()
            make.width.equalTo(startButtonContentView).multipliedBy(0.8)
            make.height.equalTo(startButton.snp.width).multipliedBy(1/5.8)
        }
        
        startButton.layoutIfNeeded()
        
        pointAnimateView.snp.makeConstraints { make in
            make.left.right.bottom.top.equalTo(startButton)
        }
        
        pointAnimateView.layoutIfNeeded()
        
        buttonControlContentView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        muteButton.snp.makeConstraints { make in
            make.left.equalTo(buttonControlContentView).offset(34)
            make.centerY.equalTo(buttonControlContentView)
            make.width.equalTo(buttonWidth)
            make.height.equalTo(buttonHeight)
        }
        micProgressView.snp.makeConstraints { make in
            make.centerX.equalTo(muteButton)
            make.top.equalTo(26)
            make.width.equalTo(21)
            make.height.equalTo(15)
        }
        closeButton.snp.makeConstraints { make in
            make.center.equalTo(buttonControlContentView)
            make.width.equalTo(buttonWidth)
            make.height.equalTo(buttonHeight)
        }
        captionsButton.snp.makeConstraints { make in
            make.right.equalTo(buttonControlContentView).offset(-34)
            make.centerY.equalTo(buttonControlContentView)
            make.width.equalTo(buttonWidth)
            make.height.equalTo(buttonHeight)
        }
    }
    
    private func setupPointAnimateView(view: UIView) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hexString: "#1186B2")?.cgColor as Any,
            UIColor(hexString: "#2342B2")?.cgColor as Any,
            UIColor(hexString: "#223FA7")?.cgColor as Any
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.frame = CGRectMake(0, 0, UIScreen.main.bounds.width - 40, startButtonHeight)
        view.layer.addSublayer(gradientLayer)
        gradientLayer.zPosition = -0.1
        self.loadingViewGradientLayer = gradientLayer
        
        CATransaction.commit()
    }
    
    private func setupStartButton(button: UIButton) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hexString: "#17C5FF")?.cgColor as Any,
            UIColor(hexString: "#315DFF")?.cgColor as Any,
            UIColor(hexString: "#446CFF")?.cgColor as Any
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.frame = CGRectMake(0, 0, UIScreen.main.bounds.width - 40, startButtonHeight)
        button.layer.addSublayer(gradientLayer)
        gradientLayer.zPosition = -0.1
        self.startButtonGradientLayer = gradientLayer
        
        CATransaction.commit()
    }
    
    @objc private func startAction() {
        Task {
            await delegate?.getStart()
        }
    }
    
    @objc private func hangUpAction() {
        resetState()
        delegate?.hangUp()
    }
    
    @objc func muteAction(_ sender: UIButton) {
        let result = delegate?.mute(selectedState: sender.isSelected) ?? false
        sender.isSelected = result
        micProgressView.isHidden = sender.isSelected
    }

    @objc private func switchCaptionsAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        setTintColor(state: sender.isSelected)
        delegate?.switchCaptions(selectedState: sender.isSelected)
    }
    
    private func setTintColor(state: Bool) {
        captionsButton.tintColor = state ? UIColor.themColor(named: "ai_brand_lightbrand6") : UIColor.themColor(named: "ai_icontext1")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if startButtonContentView.frame.width > 0 {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            startButtonGradientLayer?.frame = startButton.bounds
            loadingViewGradientLayer?.frame = pointAnimateView.bounds
            CATransaction.commit()
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        DispatchQueue.main.async {
            self.startButtonContentView.layoutIfNeeded()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
}
