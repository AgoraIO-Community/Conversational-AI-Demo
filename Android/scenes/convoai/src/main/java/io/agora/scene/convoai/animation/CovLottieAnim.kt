package io.agora.scene.convoai.animation

import android.animation.Animator
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.airbnb.lottie.Lottie
import com.airbnb.lottie.LottieAnimationView
import com.airbnb.lottie.LottieCompositionFactory
import com.airbnb.lottie.LottieDrawable
import io.agora.scene.convoai.CovLogger

enum class AgentLottieState {
    NotJoined,
    Ambient,
    Joining,
    Listening,
    Talking,
    Disconnected,
    ScaleDownOnce
}

interface CovLottieAnimCallback {
    fun onError(error: Exception)
}

class CovLottieAnim constructor(
    private val context: Context,
    private val lottieAnimationView: LottieAnimationView,
    private val callback: CovLottieAnimCallback? = null
) {

    companion object {

        private const val TAG = "CovLottieAnim"
        private const val Not_Joined = "Not_Joined.lottie"
        private const val Ambient = "Ambient.lottie"
        private const val Joining = "Joining.lottie"
        private const val Listening = "Listening.lottie"
        private const val Talking = "Talking.lottie"
        private const val Disconnected = "Disconnected.lottie"
        private const val ScaleDownOnce = "Scale_Down_Once.lottie"
    }

    fun setupView() {

        lottieAnimationView.addAnimatorListener(object : Animator.AnimatorListener {
            override fun onAnimationStart(animation: Animator) {
            }

            override fun onAnimationEnd(animation: Animator) {
            }

            override fun onAnimationCancel(animation: Animator) {
            }

            override fun onAnimationRepeat(animation: Animator) {
            }
        })
        currentState = AgentLottieState.NotJoined
    }

    var currentState = AgentLottieState.Ambient
        get() = field
        private set(value) {
            if (field != value) {
                field = value
                when (value) {
                    AgentLottieState.Ambient -> {
                        lottieAnimationView.setAnimation(Ambient)
                    }

                    AgentLottieState.NotJoined -> {
                        lottieAnimationView.setAnimation(Not_Joined)
                    }

                    AgentLottieState.Joining -> {
                        lottieAnimationView.setAnimation(Joining)
                    }

                    AgentLottieState.Listening -> {
                        lottieAnimationView.setAnimation(Listening)
                    }

                    AgentLottieState.Talking -> {
                        lottieAnimationView.setAnimation(Talking)
                    }

                    AgentLottieState.Disconnected -> {
                        lottieAnimationView.setAnimation(Disconnected)
                    }

                    AgentLottieState.ScaleDownOnce -> {
                        lottieAnimationView.setAnimation(ScaleDownOnce)
                    }
                }
            }
        }


    private val mainHandler = Handler(Looper.getMainLooper())

    fun updateAgentState(newState: AgentLottieState, volume: Int = 0) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            updateAgentStateInternal(newState, volume)
        } else {
            mainHandler.post {
                updateAgentStateInternal(newState, volume)
            }
        }
    }

    private fun updateAgentStateInternal(newState: AgentLottieState, volume: Int) {
        currentState = newState
    }

    fun release() {
        CovLogger.d(TAG, "called release")
        lottieAnimationView.removeAllAnimatorListeners()
        currentState = AgentLottieState.NotJoined
    }
}