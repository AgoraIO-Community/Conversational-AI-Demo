//
//  ToastView.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/10.
//

import UIKit
import Common

class TextContentView: UIView {
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = .white
        label.text = ResourceManager.L10n.Join.agentConnecting
        label.textColor = UIColor.themColor(named: "ai_red6")
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
//        backgroundColor = .black

        self.addSubview(textLabel)
        
        textLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(12)
            make.bottom.equalTo(-12)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LoadingOvalView: UIView {
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = .white
        label.text = ResourceManager.L10n.Join.agentConnecting
        
        return label
    }()
    
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Subviews
    private let layerMaskView = UIView()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - View Setup
    private func setupView() {
        backgroundColor = .clear
        self.clipsToBounds = true
        
        drawGradientSquare()
        
        layerMaskView.backgroundColor = UIColor.themColor(named: "ai_fill4")
        addSubview(layerMaskView)
        addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
    }
    
    // MARK: - Rotation Animation
    private func startRotationAnimation() {
        guard let gradientLayer = gradientLayer else { return }
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = CGFloat.pi * 2
        rotationAnimation.toValue = 0
        rotationAnimation.duration = 0.5
        rotationAnimation.repeatCount = .infinity
        
        gradientLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
        
        gradientLayer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    func startRotating() {
        startRotationAnimation()
    }
    
    func stopRotating() {
        gradientLayer?.removeAnimation(forKey: "rotationAnimation")
    }
    
    // MARK: - Gradient Square Drawing
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.height / 2
        self.layerMaskView.frame = CGRect(
            x: 2,
            y: 2,
            width: self.bounds.width - 4,
            height: self.bounds.height - 4
        )
        layerMaskView.layer.cornerRadius = layerMaskView.bounds.height / 2
        
        gradientLayer?.frame = CGRect(x: 0,
                                      y: 0,
                                      width: bounds.width,
                                      height: bounds.height)
        
        if gradientLayer == nil {
            drawGradientSquare()
        }
    }
    
    private func drawGradientSquare() {
        gradientLayer?.removeFromSuperlayer()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor(hex: "#00C2FF")!.cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        
        self.layer.addSublayer(gradientLayer)
        
        self.gradientLayer = gradientLayer
    }
}


class ToastView: UIView {
    private lazy var loadingOval: LoadingOvalView = {
        let view = LoadingOvalView(frame: CGRect(x: 0, y: 0, width: 111, height: 40))
        return view
    }()
    
    private lazy var textToast: TextContentView = {
        let view = TextContentView()
        view.layer.cornerRadius = 40 / 2.0
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        return view
    }()
    
    func showLoading() {
        self.isHidden = false
        loadingOval.isHidden = false
        loadingOval.startRotating()
        textToast.isHidden = true
    }
    
    func showToast(text: String) {
        self.isHidden = false
        textToast.textLabel.text = text
        textToast.isHidden = false
        loadingOval.isHidden = true
    }
    
    func dismiss() {
        loadingOval.stopRotating()
        self.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(textToast)
        self.addSubview(loadingOval)
        loadingOval.snp.makeConstraints { make in
            make.width.equalTo(111)
            make.height.equalTo(40)
            make.center.equalTo(self)
        }
        
        textToast.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.center.equalTo(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
