//
//  TypewriterLabel.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/25.
//

import UIKit
import Common

class TypewriterLabel: UILabel {
    private var text1 = ResourceManager.L10n.Conversation.appHello
    private var text2 = ResourceManager.L10n.Conversation.appWelcomeTitle
    private var text3 = ResourceManager.L10n.Conversation.appWelcomeDescription
    private let cursor = "●"
    
    private let speed: Double = 12
    private let pauseTime1: Double = 0.5
    private let pauseTime2: Double = 1.5
    private let blinkSpeed: Double = 1
    
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    
    private var typeTime1: Double { Double(text1.count) / speed }
    private var typeTime2: Double { Double(text2.count) / speed }
    private var typeTime3: Double { Double(text3.count) / speed }
    private var deleteTime1: Double { Double(text1.count) / speed }
    private var deleteTime2: Double { Double(text2.count) / speed }
    private var deleteTime3: Double { Double(text3.count) / speed }
    private var totalTime: Double {
        typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 +
        typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 +
        typeTime3 + pauseTime2 + deleteTime3 + pauseTime1
    }
    
    private var gradientColors: [UIColor] = [
        UIColor(hex: "#1787FF")!,
        UIColor(hex: "#5A6BFF")!,
        UIColor(hex: "#17B2FF")!,
        UIColor(hex: "#446CFF")!
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        numberOfLines = 0
        textAlignment = .center
    }
    
    override func drawText(in rect: CGRect) {
        let actualRect = textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
        let topAlignedRect = CGRect(x: actualRect.origin.x,
                                  y: rect.origin.y,
                                  width: actualRect.width,
                                  height: actualRect.height)
        super.drawText(in: topAlignedRect)
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        textRect.origin.y = bounds.origin.y
        return textRect
    }
    
    func startAnimation() {
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update() {
        let currentTime = CACurrentMediaTime() - startTime
        let cycleTime = currentTime.truncatingRemainder(dividingBy: totalTime)
        
        var visibleText = ""
        
        if cycleTime < typeTime1 {
            let charCount = Int(cycleTime * speed)
            visibleText = String(text1.prefix(charCount))
        }
        else if cycleTime < typeTime1 + pauseTime2 {
            visibleText = text1
        }
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 {
            let charCount = text1.count - Int((cycleTime - typeTime1 - pauseTime2) * speed)
            visibleText = String(text1.prefix(max(0, charCount)))
        }
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 {
            visibleText = ""
        }
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 {
            let charCount = Int((cycleTime - typeTime1 - pauseTime2 - deleteTime1 - pauseTime1) * speed)
            visibleText = String(text2.prefix(charCount))
        }
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 {
            visibleText = text2
        }
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 {
            let charCount = text2.count - Int((cycleTime - typeTime1 - pauseTime2 - deleteTime1 - pauseTime1 - typeTime2 - pauseTime2) * speed)
            visibleText = String(text2.prefix(max(0, charCount)))
        }
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 {
            visibleText = ""
        }
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 + typeTime3 {
            let charCount = Int((cycleTime - typeTime1 - pauseTime2 - deleteTime1 - pauseTime1 - typeTime2 - pauseTime2 - deleteTime2 - pauseTime1) * speed)
            visibleText = String(text3.prefix(charCount))
        }
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 + typeTime3 + pauseTime2 {
            visibleText = text3
        }
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 + typeTime3 + pauseTime2 + deleteTime3 {
            let charCount = text3.count - Int((cycleTime - typeTime1 - pauseTime2 - deleteTime1 - pauseTime1 - typeTime2 - pauseTime2 - deleteTime2 - pauseTime1 - typeTime3 - pauseTime2) * speed)
            visibleText = String(text3.prefix(max(0, charCount)))
        }
        
        if cycleTime < typeTime1 ||
            (cycleTime >= typeTime1 && cycleTime < typeTime1 + pauseTime2) ||
            (cycleTime >= typeTime1 + pauseTime2 && cycleTime < typeTime1 + pauseTime2 + deleteTime1) ||
            (cycleTime >= typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 && cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2) ||
            (cycleTime >= typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 && cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2) ||
            (cycleTime >= typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 && cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2) ||
            (cycleTime >= typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 && cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 + typeTime3) ||
            (cycleTime >= typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 + typeTime3 && cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 + typeTime3 + pauseTime2) ||
            (cycleTime >= typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 + typeTime3 + pauseTime2 && cycleTime < totalTime) {
            
            let isVisible = sin(currentTime * .pi * 2 * blinkSpeed) >= 0
            if isVisible {
                visibleText += cursor
            }
        }
        
        let attributedText = createGradientAttributedString(from: visibleText)
        self.attributedText = attributedText
    }
    
    private func createGradientAttributedString(from text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        guard text.count > 0 else { return attributedString }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center
        
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))
        
        for i in 0..<text.count {
            let percent = CGFloat(i) / CGFloat(max(1, text.count - 1))
            let color = interpolateColor(percent: percent)
            
            let range = NSRange(location: i, length: 1)
            attributedString.addAttribute(.foregroundColor, value: color, range: range)
        }
        
        return attributedString
    }
    
    private func interpolateColor(percent: CGFloat) -> UIColor {
        guard !gradientColors.isEmpty else { return .white }
        
        if gradientColors.count == 1 {
            return gradientColors[0]
        }
        
        let segmentCount = gradientColors.count - 1
        let segmentPercent = percent * CGFloat(segmentCount)
        let segmentIndex = Int(floor(segmentPercent))
        let segmentOffset = segmentPercent - CGFloat(segmentIndex)
        
        let startIndex = min(segmentIndex, segmentCount)
        let endIndex = min(startIndex + 1, gradientColors.count - 1)
        
        let startColor = gradientColors[startIndex]
        let endColor = gradientColors[endIndex]
        
        return interpolateColor(from: startColor, to: endColor, with: segmentOffset)
    }
    
    private func interpolateColor(from: UIColor, to: UIColor, with percent: CGFloat) -> UIColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        
        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * percent
        let g = fromG + (toG - fromG) * percent
        let b = fromB + (toB - fromB) * percent
        let a = fromA + (toA - fromA) * percent
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    deinit {
        stopAnimation()
    }
}


