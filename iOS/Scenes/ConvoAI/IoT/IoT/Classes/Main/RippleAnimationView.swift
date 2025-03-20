import UIKit

class RippleAnimationView: UIView {
    
    // Number of ripples (original layer plus copied layers)
    private static let rippleCount: Int = 3
    
    // Interval between ripples
    private static let rippleDuration: Double = 0.5
    
    // Duration of a single animation cycle
    private static let animationDuration: Double = 2.5
    
    // Pause duration between animation cycles
    private static let pauseDuration: Double = 4.0
    
    // Fade in/out time ratio of total animation duration
    private static let fadeRatio: Double = 0.2
    
    // Scale factor for ripple expansion
    var scaleFactor: CGFloat = 3.2
    
    // Store animation layers for control
    private var replicatorLayer: CAReplicatorLayer?
    private var rippleLayer: CALayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        setupAnimationLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // Setup initial animation layers
    private func setupAnimationLayers() {
        replicatorLayer = createReplicatorLayer(frame: frame)
        if let replicatorLayer = replicatorLayer {
            self.layer.addSublayer(replicatorLayer)
        }
    }
    
    // Create replicator layer
    private func createReplicatorLayer(frame: CGRect) -> CAReplicatorLayer {
        let replicatorLayer = CAReplicatorLayer()
        replicatorLayer.instanceCount = RippleAnimationView.rippleCount
        replicatorLayer.instanceDelay = RippleAnimationView.rippleDuration
        
        rippleLayer = createRippleLayer(rect: frame)
        if let rippleLayer = rippleLayer {
            replicatorLayer.addSublayer(rippleLayer)
        }
        return replicatorLayer
    }
    
    // Create base ripple layer
    private func createRippleLayer(rect: CGRect) -> CALayer {
        let rippleLayer = CALayer()
        rippleLayer.frame = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height)
        rippleLayer.cornerRadius = rect.size.height / 2
        return rippleLayer
    }
    
    // Scale animation
    private func createScaleAnimation() -> CABasicAnimation {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.2
        scaleAnimation.toValue = scaleFactor
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        return scaleAnimation
    }
    
    // Background color animation
    private func createColorAnimation() -> CAKeyframeAnimation {
        let colorAnimation = CAKeyframeAnimation(keyPath: "backgroundColor")
        let baseColor = UIColor(red: 68/255.0, green: 108/255.0, blue: 255/255.0, alpha: 1.0)
        
        colorAnimation.values = [
            baseColor.withAlphaComponent(1.0).cgColor,
            baseColor.withAlphaComponent(0.5).cgColor,
            baseColor.withAlphaComponent(0.0).cgColor
        ]
        colorAnimation.keyTimes = [0.0, 0.5, 1.0] as [NSNumber]
        colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return colorAnimation
    }
    
    // Opacity animation for fade in/out effect
    private func createOpacityAnimation() -> CAKeyframeAnimation {
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        let fadeTime = RippleAnimationView.fadeRatio
        
        opacityAnimation.values = [0.0, 1.0, 1.0, 0.0]
        opacityAnimation.keyTimes = [0.0, fadeTime, 1.0 - fadeTime, 1.0] as [NSNumber]
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return opacityAnimation
    }
    
    // Create combined animation group with pause effect
    private func createGroupAnimation() -> CAAnimationGroup {
        let group = CAAnimationGroup()
        group.animations = [
            createScaleAnimation(),
            createColorAnimation(),
            createOpacityAnimation()
        ]
        
        let animationPeriod = RippleAnimationView.animationDuration
        let pausePeriod = RippleAnimationView.pauseDuration
        let totalDuration = animationPeriod + pausePeriod
        
        group.duration = totalDuration
        let activeRatio = animationPeriod / totalDuration
        group.speed = Float(1.0 / activeRatio)
        group.timeOffset = 0
        
        group.repeatCount = .infinity
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards
        
        return group
    }
    
    // Public methods for animation control
    
    func startAnimation() {
        // Remove any existing animations
        rippleLayer?.removeAllAnimations()
        
        // Add new animation with fade in
        let animation = createGroupAnimation()
        rippleLayer?.add(animation, forKey: "rippleAnimation")
        
        // Fade in the entire view
        self.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    func stopAnimation() {
        // Fade out the entire view
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            // Remove animations after fade out
            self.rippleLayer?.removeAllAnimations()
        }
    }
    
    // Optional wave effect
    func addWaveEffect() {
        let waveLayer = CAShapeLayer()
        waveLayer.frame = bounds
        waveLayer.fillColor = UIColor.clear.cgColor
        waveLayer.strokeColor = UIColor(red: 68/255.0, green: 108/255.0, blue: 255/255.0, alpha: 0.3).cgColor
        waveLayer.lineWidth = 1.0
        
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.width/2, y: bounds.height/2),
                               radius: bounds.width/2 * 0.8,
                               startAngle: 0,
                               endAngle: 2 * .pi,
                               clockwise: true)
        waveLayer.path = path.cgPath
        
        layer.addSublayer(waveLayer)
        
        let waveAnimation = CABasicAnimation(keyPath: "transform.scale")
        waveAnimation.fromValue = 0.9
        waveAnimation.toValue = 1.1
        waveAnimation.duration = 2.0
        waveAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        waveAnimation.repeatCount = .infinity
        waveAnimation.autoreverses = true
        
        waveLayer.add(waveAnimation, forKey: "waveAnimation")
    }
}
