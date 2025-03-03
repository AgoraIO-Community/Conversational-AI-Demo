package io.agora.scene.common.ui.widget

import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.text.SpannableString
import android.text.SpannableStringBuilder
import android.text.style.ForegroundColorSpan
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatTextView
import io.agora.scene.common.R
import java.util.concurrent.TimeUnit
import kotlin.math.max

class TypewriterTextView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : AppCompatTextView(context, attrs, defStyleAttr) {

    private var text1 = context.getString(R.string.common_login_typing_text1)
    private var text2 = context.getString(R.string.common_login_typing_text2)
    private val cursor = "●"

    private val charsPerSecond: Float get() = 22f

    private val pauseTime1 = TimeUnit.MILLISECONDS.toMillis(500)
    private val pauseTime2 = TimeUnit.SECONDS.toMillis(3)

    private val typeTime1: Long get() = (text1.length / charsPerSecond * 1000).toLong().coerceAtLeast(1000)
    private val typeTime2: Long get() = (text2.length / charsPerSecond * 1000).toLong().coerceAtLeast(1000)
    private val deleteTime1: Long get() = typeTime1 / 2
    private val deleteTime2: Long get() = typeTime2 / 2

    private var startTime: Long = 0
    private var isAnimating = false
    private val handler = Handler(Looper.getMainLooper())

    private val gradientColors = mutableListOf<Int>()

    private val totalTime: Long
        get() = typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 +
                typeTime2 + pauseTime2 + deleteTime2 + pauseTime1

    private val updateRunnable = object : Runnable {
        override fun run() {
            update()
            handler.postDelayed(this, 16)
        }
    }

    private var timePoint1: Long = 0
    private var timePoint2: Long = 0
    private var timePoint3: Long = 0
    private var timePoint4: Long = 0
    private var timePoint5: Long = 0
    private var timePoint6: Long = 0
    private var timePoint7: Long = 0

    init {
        gravity = android.view.Gravity.CENTER
        maxLines = Int.MAX_VALUE

        gradientColors.addAll(
            listOf(
                Color.parseColor("#1787FF"),
                Color.parseColor("#5A6BFF"),
                Color.parseColor("#17B2FF"),
                Color.parseColor("#446CFF")
            )
        )
    }

    fun setTypeText(text1: String, text2: String) {
        this.text1 = text1
        this.text2 = text2
        calculateTimePoints()
    }

    fun startAnimation() {
        if (isAnimating) return
        isAnimating = true
        startTime = System.currentTimeMillis()
        calculateTimePoints()
        handler.post(updateRunnable)
    }

    fun stopAnimation() {
        isAnimating = false
        handler.removeCallbacks(updateRunnable)
    }

    private fun isInCursorPhase(cycleTime: Long): Boolean {
        return cycleTime < timePoint1 ||
                (cycleTime >= timePoint1 && cycleTime < timePoint2) ||
                (cycleTime >= timePoint2 && cycleTime < timePoint3) ||
                (cycleTime >= timePoint4 && cycleTime < timePoint5) ||
                (cycleTime >= timePoint5 && cycleTime < timePoint6) ||
                (cycleTime >= timePoint6 && cycleTime < timePoint7)
    }

    private fun update() {
        val currentTime = System.currentTimeMillis() - startTime
        val cycleTime = currentTime % totalTime

        var visibleText = ""

        when {
            cycleTime < timePoint1 -> {
                val progress = cycleTime.toFloat() / timePoint1.toFloat()
                val charCount = (text1.length * progress).toInt()
                visibleText = text1.take(charCount)
            }

            cycleTime < timePoint2 -> {
                visibleText = text1
            }

            cycleTime < timePoint3 -> {
                val elapsed = cycleTime - timePoint2
                val progress = elapsed.toFloat() / deleteTime1.toFloat()
                val charCount = text1.length - (text1.length * progress).toInt()
                visibleText = text1.take(max(0, charCount))
            }

            cycleTime < timePoint4 -> {
                visibleText = ""
            }

            cycleTime < timePoint5 -> {
                val elapsed = cycleTime - timePoint4
                val progress = elapsed.toFloat() / typeTime2.toFloat()
                val charCount = (text2.length * progress).toInt()
                visibleText = text2.take(charCount)
            }

            cycleTime < timePoint6 -> {
                visibleText = text2
            }

            cycleTime < timePoint7 -> {
                val elapsed = cycleTime - timePoint6
                val progress = elapsed.toFloat() / deleteTime2.toFloat()
                val charCount = text2.length - (text2.length * progress).toInt()
                visibleText = text2.take(max(0, charCount))
            }

            else -> {
                visibleText = ""
            }
        }

        val shouldShowCursor = isInCursorPhase(cycleTime) &&
                !(cycleTime >= timePoint1 && cycleTime < timePoint2) &&
                !(cycleTime >= timePoint5 && cycleTime < timePoint6)

        if (shouldShowCursor) {
            visibleText += cursor
        }

        setGradientText(visibleText)
    }

    private fun setGradientText(text: String) {
        if (text.isEmpty()) {
            setText("")
            return
        }

        val spannableString = SpannableStringBuilder(text)
        text.indices.forEach { i ->
            val percent = i.toFloat() / max(1f, (text.length - 1).toFloat())
            val color = interpolateColor(percent)
            spannableString.setSpan(
                ForegroundColorSpan(color),
                i, i + 1,
                SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }
        setText(spannableString)
    }

    private fun interpolateColor(percent: Float): Int {
        if (gradientColors.isEmpty()) return Color.WHITE
        if (gradientColors.size == 1) return gradientColors[0]

        val segmentCount = gradientColors.size - 1
        val segmentPercent = percent * segmentCount
        val segmentIndex = segmentPercent.toInt()
        val segmentOffset = segmentPercent - segmentIndex

        val startIndex = segmentIndex.coerceAtMost(segmentCount)
        val endIndex = (startIndex + 1).coerceAtMost(gradientColors.size - 1)

        return interpolateColor(
            gradientColors[startIndex],
            gradientColors[endIndex],
            segmentOffset
        )
    }

    private fun interpolateColor(startColor: Int, endColor: Int, fraction: Float): Int {
        val startA = Color.alpha(startColor)
        val startR = Color.red(startColor)
        val startG = Color.green(startColor)
        val startB = Color.blue(startColor)

        val endA = Color.alpha(endColor)
        val endR = Color.red(endColor)
        val endG = Color.green(endColor)
        val endB = Color.blue(endColor)

        return Color.argb(
            (startA + (endA - startA) * fraction).toInt(),
            (startR + (endR - startR) * fraction).toInt(),
            (startG + (endG - startG) * fraction).toInt(),
            (startB + (endB - startB) * fraction).toInt()
        )
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        stopAnimation()
    }

    private fun calculateTimePoints() {
        timePoint1 = typeTime1
        timePoint2 = timePoint1 + pauseTime2
        timePoint3 = timePoint2 + deleteTime1
        timePoint4 = timePoint3 + pauseTime1
        timePoint5 = timePoint4 + typeTime2
        timePoint6 = timePoint5 + pauseTime2
        timePoint7 = timePoint6 + deleteTime2
    }

    fun setGradientColors(colors: List<Int>) {
        this.gradientColors.clear()
        this.gradientColors.addAll(colors)
    }
} 