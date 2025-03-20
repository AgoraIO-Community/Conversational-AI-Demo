//
//  PointLoadingView.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/25.
//

import Foundation
import UIKit

class PointAnimationView: UIView {
    private var pointViews: [UIView] = []
    private var isAnimating: Bool = false
    
    var pointColor: UIColor = UIColor.themColor(named: "ai_brand_white10") {
        didSet {
            pointViews.forEach { $0.backgroundColor = pointColor }
        }
    }
    var pointSize: CGFloat = 9.0 {
        didSet {
            setupPointViews()
        }
    }
    var pointSpacing: CGFloat = 7.0 {
        didSet {
            setupPointViews()
        }
    }
    var animationDuration: TimeInterval = 0.6
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPointViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPointViews()
    }
    
    private func setupPointViews() {
        pointViews.forEach { $0.removeFromSuperview() }
        pointViews.removeAll()
        
        for _ in 0..<3 {
            let pointView = UIView()
            pointView.backgroundColor = pointColor
            pointView.layer.cornerRadius = pointSize / 2
            addSubview(pointView)
            pointViews.append(pointView)
        }
        
        layoutPointViews()
    }
    
    private func layoutPointViews() {
        let totalWidth = CGFloat(pointViews.count) * pointSize + CGFloat(pointViews.count - 1) * pointSpacing
        let startX = (bounds.width - totalWidth) / 2
        
        for (index, pointView) in pointViews.enumerated() {
            let x = startX + CGFloat(index) * (pointSize + pointSpacing)
            let y = (bounds.height - pointSize) / 2
            pointView.frame = CGRect(x: x, y: y, width: pointSize, height: pointSize)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutPointViews()
    }
    
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        animatePoints()
    }
    
    func stopAnimating() {
        isAnimating = false
        pointViews.forEach { $0.layer.removeAllAnimations() }
    }
    
    private func animatePoints() {
        guard isAnimating else { return }
        
        for (index, pointView) in pointViews.enumerated() {
            let delay = animationDuration * Double(index) / Double(pointViews.count)
            
            UIView.animate(withDuration: animationDuration / 2,
                           delay: delay,
                           options: [.curveEaseInOut],
                           animations: {
                pointView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                pointView.alpha = 1.0
            }) { _ in
                UIView.animate(withDuration: self.animationDuration / 2,
                             animations: {
                    pointView.transform = .identity
                    pointView.alpha = 0.3
                }) { [weak self] _ in
                    if index == (self?.pointViews.count ?? 0) - 1 {
                        self?.animatePoints()
                    }
                }
            }
        }
    }
}
