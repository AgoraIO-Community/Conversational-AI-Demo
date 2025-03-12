package io.agora.scene.convoai.iot.animation

import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.util.Log
import android.view.View
import android.view.animation.DecelerateInterpolator
import android.view.animation.LinearInterpolator
import java.util.ArrayList
import kotlin.math.pow

class RippleAnimationView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private val TAG = "RippleAnimationView"
    
    // Number of ripples
    private val rippleCount = 3
    
    // Ripple interval time
    private val rippleDuration = 500L // 0.5 seconds
    
    // Single animation duration
    private val animationDuration = 2500L // 2.5 seconds
    
    // Animation pause time
    private val pauseDuration = 4000L // 4 seconds
    
    // Fade in/out time ratio
    private val fadeRatio = 0.2f
    
    // Scale factor
    var scaleFactor = 1.4f
    
    // Base color #446CFF
    private val baseColor = Color.rgb(68, 108, 255)
    
    // List to store all ripple circles
    private val rippleCircles = ArrayList<RippleCircle>()
    
    // Paint
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    
    // Animation set
    private var animatorSet: AnimatorSet? = null
    
    init {
        // Initialization
        paint.style = Paint.Style.FILL
        Log.d(TAG, "Initializing view")
        
        // Don't start animation in init, wait until view dimensions are determined
        // startRippleAnimation()
    }
    
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        
        Log.d(TAG, "onDraw: width=$width, height=$height, circle count=${rippleCircles.size}")
        
        // Draw all ripple circles - center at bottom middle
        for (circle in rippleCircles) {
            paint.color = circle.color
            // Set circle center position to bottom center
            canvas.drawCircle(width / 2f, height.toFloat(), circle.radius, paint)
            Log.d(TAG, "Drawing circle: radius=${circle.radius}, alpha=${Color.alpha(circle.color)}")
        }
    }
    
    private fun startRippleAnimation() {
        // Clear existing animations
        animatorSet?.cancel()
        rippleCircles.clear()
        
        Log.d(TAG, "Starting animation: width=$width, height=$height")
        
        // Create a circle object for each ripple
        for (i in 0 until rippleCount) {
            rippleCircles.add(RippleCircle())
        }
        
        // Create animation collection
        val animators = ArrayList<ValueAnimator>()
        
        // Create animation for each ripple
        for (i in 0 until rippleCount) {
            val animator = createRippleAnimator(i)
            animators.add(animator)
        }
        
        // Create and start animation set
        animatorSet = AnimatorSet()
        // Use play() and with() methods instead of playTogether()
        if (animators.isNotEmpty()) {
            val builder = animatorSet?.play(animators[0])
            for (i in 1 until animators.size) {
                builder?.with(animators[i])
            }
        }
        animatorSet?.start()
        Log.d(TAG, "Animation started")
    }
    
    private fun createRippleAnimator(index: Int): ValueAnimator {
        val animator = ValueAnimator.ofFloat(0f, 1f)
        // Remove pause time, use pure animation time
        animator.duration = animationDuration
        animator.repeatCount = ValueAnimator.INFINITE
        // Use RESTART mode instead of REVERSE
        animator.repeatMode = ValueAnimator.RESTART
        animator.startDelay = index * rippleDuration
        animator.interpolator = LinearInterpolator()
        
        // Record the last state of the previous cycle for smooth transition
        var lastRadius = 0f
        var lastAlpha = 0
        
        animator.addUpdateListener { animation ->
            val fraction = animation.animatedValue as Float
            
            val circle = rippleCircles[index]
            
            // Prevent cases where width or height is 0
            if (width > 0 && height > 0) {
                // Update radius (scaling animation)
                val minRadius = Math.min(width, height) * 0.1f
                val maxRadius = Math.max(width, height) * scaleFactor
                
                // Calculate current radius
                val targetRadius = minRadius + (maxRadius - minRadius) * fraction
                
                // Handle smooth radius transition at the beginning of the cycle
                if (fraction < 0.05f && lastRadius > targetRadius) {
                    // At the start of a new cycle, keep the opacity of the previous cycle at 0
                    circle.radius = targetRadius
                    circle.color = Color.argb(
                        0,
                        Color.red(baseColor),
                        Color.green(baseColor),
                        Color.blue(baseColor)
                    )
                } else {
                    // Normal radius update
                    circle.radius = targetRadius
                    
                    // Modify transparency calculation logic
                    var alpha = 0f
                    if (fraction < fadeRatio) {
                        // Fade-in stage
                        alpha = (fraction / fadeRatio).pow(2)
                    } else if (fraction < (1 - fadeRatio)) {
                        // Middle stage - decrease transparency faster as the circle grows
                        val progress = (fraction - fadeRatio) / (1 - 2 * fadeRatio)
                        // Use a steeper curve to ensure transparency is close to 0 near the end
                        alpha = (1.0f - progress.pow(2f)) * (1.0f - progress)
                    } else {
                        // Fade-out stage - ensure complete transparency at the end
                        alpha = 0f
                    }
                    
                    // Ensure alpha value is within valid range
                    val alphaInt = (alpha * 255 * 0.8f).toInt().coerceIn(0, 255)
                    
                    circle.color = Color.argb(
                        alphaInt,
                        Color.red(baseColor),
                        Color.green(baseColor),
                        Color.blue(baseColor)
                    )
                    
                    // Save current state for next cycle
                    lastRadius = circle.radius
                    lastAlpha = alphaInt
                }
                
                // Redraw view
                invalidate()
            }
        }
        
        return animator
    }
    
    // Add wave effect (optional)
    fun addWaveEffect() {
        val waveAnimator = ValueAnimator.ofFloat(0.9f, 1.1f)
        waveAnimator.duration = 2000
        waveAnimator.repeatCount = ValueAnimator.INFINITE
        waveAnimator.repeatMode = ValueAnimator.REVERSE
        waveAnimator.interpolator = DecelerateInterpolator()
        
        waveAnimator.addUpdateListener { animation ->
            // Logic for implementing wave effect
            invalidate()
        }
        
        waveAnimator.start()
    }
    
    // Ripple circle class
    private inner class RippleCircle {
        var radius = 0f
        var color = Color.TRANSPARENT
    }
    
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        // Clean up resources
        animatorSet?.cancel()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        Log.d(TAG, "Size changed: w=$w, h=$h, oldw=$oldw, oldh=$oldh")
        // Restart animation when view size changes
        if (w > 0 && h > 0) {
            startRippleAnimation()
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        Log.d(TAG, "View attached to window")
    }

    // Add measurement method to ensure view has dimensions
    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        
        val widthMode = MeasureSpec.getMode(widthMeasureSpec)
        val widthSize = MeasureSpec.getSize(widthMeasureSpec)
        val heightMode = MeasureSpec.getMode(heightMeasureSpec)
        val heightSize = MeasureSpec.getSize(heightMeasureSpec)
        
        var width = widthSize
        var height = heightSize
        
        // If width is wrap_content, set default width
        if (widthMode == MeasureSpec.AT_MOST || widthMode == MeasureSpec.UNSPECIFIED) {
            width = 200
        }
        
        // If height is wrap_content, set default height
        if (heightMode == MeasureSpec.AT_MOST || heightMode == MeasureSpec.UNSPECIFIED) {
            height = 200
        }
        
        // Ensure width and height are equal (optional, if you want the view to be square)
        val size = Math.min(width, height)
        setMeasuredDimension(size, size)
        
        Log.d(TAG, "onMeasure: width=$width, height=$height, final size=$size")
    }
}