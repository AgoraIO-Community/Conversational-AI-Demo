//
//  SearchingView.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/6.
//

import UIKit
import Common

protocol SearchingViewDelegate: AnyObject {
    func searchTimeout()
}

class SearchingView: UIView {
    weak var delegate: SearchingViewDelegate?
    
    private var timer: Timer?
    private var timeInteval = 0
    private let count = 20
    
    private lazy var searchAnimateView:RippleAnimationView = {
        let diameter = self.bounds.width
        let rippleFrame = CGRect(
            x: 0,
            y: self.bounds.height - diameter/2 + 20,
            width: diameter,
            height: diameter
        )
        
        let rippleView = RippleAnimationView(frame: rippleFrame)
        
        return rippleView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.text = ResourceManager.L10n.Iot.deviceScanningTitle
        label.textAlignment = .center
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = ResourceManager.L10n.Iot.deviceScanningDescription
        label.textAlignment = .center
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.text = "\(count) s"
        label.textAlignment = .center
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [titleLabel, descriptionLabel, searchAnimateView, timeLabel].forEach { addSubview($0) }
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(70)
            make.left.equalTo(40)
            make.right.equalTo(-40)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.left.right.equalTo(titleLabel)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.bottom.equalTo(-75)
            make.centerX.equalToSuperview()
        }
    }
    
    private func searchTimeout() {
        stopSearch()
        
        delegate?.searchTimeout()
    }
    
    func hideTextView(isHidden: Bool) {
        titleLabel.isHidden = isHidden
        descriptionLabel.isHidden = isHidden
    }
}

extension SearchingView {
    func startSearch() {
        timer?.invalidate()
        timer = nil
        
        timeInteval = count
        timeLabel.text = "\(count) s"
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }
            self.timeInteval -= 1
            timeLabel.text = "\(self.timeInteval) s"
            
            if self.timeInteval <= 0 {
                self.searchTimeout()
            }
        })
        RunLoop.current.add(timer!, forMode: .common)
        
        searchAnimateView.startAnimation()
    }
    
    func stopSearch() {
        timer?.invalidate()
        timer = nil
        searchAnimateView.stopAnimation()
    }
}

