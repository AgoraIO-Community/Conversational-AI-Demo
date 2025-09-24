package io.agora.scene.convoai.ui.widget

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import androidx.constraintlayout.widget.ConstraintLayout
import kotlinx.coroutines.Job
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import io.agora.scene.convoai.constant.AgentConnectionState
import android.view.animation.Animation
import androidx.annotation.DrawableRes
import androidx.core.view.isVisible
import io.agora.scene.common.R
import io.agora.scene.common.util.GlideImageLoader
import io.agora.scene.convoai.databinding.CovActivityLivingTopSipBinding

/**
 * Top bar view for living activity, encapsulating info/settings/net buttons, ViewFlipper switching, and timer logic.
 */
class CovLivingTopSipView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : ConstraintLayout(context, attrs, defStyleAttr) {

    private val binding: CovActivityLivingTopSipBinding =
        CovActivityLivingTopSipBinding.inflate(LayoutInflater.from(context), this, true)

    private var onbackClick: (() -> Unit)? = null
    private var isTitleAnimRunning = false
    private var connectionState: AgentConnectionState = AgentConnectionState.IDLE
    private var titleAnimJob: Job? = null
    private var countDownJob: Job? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main)
    private var onTimerEnd: (() -> Unit)? = null

    init {
        binding.btnBack.setOnClickListener { onbackClick?.invoke() }

        // Set animation listener to show tv_cc only after ll_timer is fully displayed
        binding.viewFlipper.inAnimation?.setAnimationListener(object : Animation.AnimationListener {
            override fun onAnimationStart(animation: Animation?) {
            }

            override fun onAnimationEnd(animation: Animation?) {
            }

            override fun onAnimationRepeat(animation: Animation?) {}
        })
    }

    /**
     * Set callback for back button click.
     */
    fun setOnBackClickListener(listener: (() -> Unit)?) {
        onbackClick = listener
    }

    fun updateTitleName(name: String, url: String, @DrawableRes defaultImage:Int) {
        binding.tvPresetName.text = name
        if (url.isEmpty()) {
            binding.ivPreset.setImageResource(defaultImage)
        } else {
            GlideImageLoader.load(
                binding.ivPreset,
                url,
                defaultImage,
                defaultImage
            )
        }
    }

    /**
     * Set agent connect state
     */
    fun updateAgentState(state: AgentConnectionState) {
        connectionState = state
    }


    /**
     * Show the title animation with simplified 2-element ViewFlipper.
     * ViewFlipper switches: ll_limit_tips (0) -> ll_timer (1)
     */
    fun showTitleAnim(sessionLimitMode: Boolean, roomExpireTime: Long, tipsText: String? = null) {
        stopTitleAnim()
        val tips = tipsText ?: if (sessionLimitMode) {
            context.getString(R.string.common_limit_time, (roomExpireTime / 60).toInt())
        } else {
            context.getString(R.string.common_limit_time_none)
        }
        binding.tvLimitTips.text = tips
        isTitleAnimRunning = true

        titleAnimJob = coroutineScope.launch {
            binding.viewFlipper.isVisible = true
            // Ensure start at ll_limit_tips (index 0)
            while (binding.viewFlipper.displayedChild != 0) {
                binding.viewFlipper.showPrevious()
            }
            delay(3000)
            if (!isActive || !isTitleAnimRunning) return@launch
            if (connectionState != AgentConnectionState.IDLE) {
                binding.viewFlipper.showNext() // to ll_timer (index 1)
            } else {
                while (binding.viewFlipper.displayedChild != 0) {
                    binding.viewFlipper.showPrevious()
                }
            }
        }
    }

    /**
     * Stop the title animation and reset state.
     */
    fun stopTitleAnim() {
        isTitleAnimRunning = false
        titleAnimJob?.cancel()
        titleAnimJob = null
        binding.viewFlipper.isVisible = false
        // Reset ViewFlipper to first child (ll_limit_tips)
        while (binding.viewFlipper.displayedChild != 0) {
            binding.viewFlipper.showPrevious()
        }
        binding.tvTimer.setTextColor(context.getColor(R.color.ai_brand_white10))
    }

    /**
     * Start the countdown or count-up timer.
     * @param sessionLimitMode Whether session limit mode is enabled
     * @param roomExpireTime Room expire time in seconds
     * @param onTimerEnd Callback when countdown ends (only for countdown mode)
     */
    fun startCountDownTask(
        sessionLimitMode: Boolean,
        roomExpireTime: Long,
        onTimerEnd: (() -> Unit)? = null
    ) {
        stopCountDownTask()
        this.onTimerEnd = onTimerEnd
        countDownJob = coroutineScope.launch {
            if (sessionLimitMode) {
                var remainingTime = roomExpireTime * 1000L
                while (remainingTime > 0 && isActive) {
                    onTimerTick(remainingTime, false)
                    delay(1000)
                    remainingTime -= 1000
                }
                if (remainingTime <= 0) {
                    onTimerTick(0, false)
                    onTimerEnd?.invoke()
                }
            } else {
                var elapsedTime = 0L
                while (isActive) {
                    onTimerTick(elapsedTime, true)
                    delay(1000)
                    elapsedTime += 1000
                }
            }
        }
    }

    /**
     * Stop the countdown/count-up timer.
     */
    fun stopCountDownTask() {
        countDownJob?.cancel()
        countDownJob = null
    }

    /**
     * Update timer text and color based on time and mode.
     */
    private fun onTimerTick(timeMs: Long, isCountUp: Boolean) {
        val hours = (timeMs / 1000 / 60 / 60).toInt()
        val minutes = (timeMs / 1000 / 60 % 60).toInt()
        val seconds = (timeMs / 1000 % 60).toInt()
        val timeText = if (hours > 0) {
            String.format("%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format("%02d:%02d", minutes, seconds)
        }
        binding.tvTimer.text = timeText
        if (isCountUp) {
            binding.tvTimer.setTextColor(context.getColor(R.color.ai_brand_white10))
        } else {
            when {
                timeMs <= 20000 -> binding.tvTimer.setTextColor(context.getColor(R.color.ai_red6))
                timeMs <= 60000 -> binding.tvTimer.setTextColor(context.getColor(R.color.ai_green6))
                else -> binding.tvTimer.setTextColor(context.getColor(R.color.ai_brand_white10))
            }
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        stopTitleAnim()
        stopCountDownTask()
    }
} 