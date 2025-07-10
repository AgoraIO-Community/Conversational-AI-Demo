package io.agora.scene.common.util.toast

import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.widget.Toast
import androidx.annotation.StringRes
import io.agora.scene.common.AgentApp
import io.agora.scene.common.util.dp

object ToastUtil {

    private val mMainHandler by lazy {
        Handler(Looper.getMainLooper())
    }

    @JvmStatic
    fun show(@StringRes resId: Int, duration: Int = Toast.LENGTH_SHORT) {
        show(AgentApp.instance().getString(resId), duration)
    }

    @JvmStatic
    fun show(@StringRes resId: Int, duration: Int = Toast.LENGTH_SHORT, vararg formatArgs: String?) {
        show(AgentApp.instance().getString(resId, *formatArgs), duration)
    }

    @JvmStatic
    fun show(@StringRes resId: Int, vararg formatArgs: String?) {
        show(AgentApp.instance().getString(resId, *formatArgs))
    }

    @JvmStatic
    fun show(msg: String, duration: Int = Toast.LENGTH_SHORT) {
        show(msg, InternalToast.COMMON, duration)
    }

    @JvmStatic
    fun showCenter(@StringRes resId: Int, duration: Int = Toast.LENGTH_SHORT) {
        show(AgentApp.instance().getString(resId), InternalToast.COMMON, duration, Gravity.CENTER, 0)
    }

    @JvmStatic
    fun showCenter(msg: String, duration: Int = Toast.LENGTH_SHORT) {
        show(msg, InternalToast.COMMON, duration, Gravity.CENTER, 0)
    }

    @JvmStatic
    fun showTips(@StringRes resId: Int, duration: Int = Toast.LENGTH_SHORT) {
        show(AgentApp.instance().getString(resId), InternalToast.TIPS, duration)
    }

    @JvmStatic
    fun showTips(msg: String, duration: Int = Toast.LENGTH_SHORT) {
        show(msg, InternalToast.TIPS, duration)
    }

    @JvmStatic
    fun showError(@StringRes resId: Int, duration: Int = Toast.LENGTH_SHORT) {
        show(AgentApp.instance().getString(resId), InternalToast.ERROR, duration)
    }

    @JvmStatic
    fun showError(msg: String, duration: Int = Toast.LENGTH_SHORT) {
        show(msg, InternalToast.ERROR, duration)
    }

    @JvmStatic
    fun showByPosition(
        msg: String, gravity: Int = Gravity.BOTTOM, offsetY: Int = 200.dp.toInt(),
        duration: Int = Toast.LENGTH_SHORT,
    ) {
        show(msg = msg, duration = duration, gravity = gravity, offsetY = offsetY)
    }

    @JvmStatic
    fun showByPosition(
        @StringRes resId: Int, gravity: Int = Gravity.BOTTOM, offsetY: Int = 200.dp.toInt(),
        duration: Int = Toast.LENGTH_SHORT
    ) {
        show(msg = AgentApp.instance().getString(resId), duration = duration, gravity = gravity, offsetY = offsetY)
    }

    @JvmStatic
    private fun show(msg: String, toastType: Int = InternalToast.COMMON, duration: Int = Toast.LENGTH_SHORT) {
        if (Looper.getMainLooper().thread == Thread.currentThread()) {
            InternalToast.init(AgentApp.instance())
            InternalToast.show(msg, toastType, duration, Gravity.BOTTOM, 200.dp.toInt())
        } else {
            mMainHandler.post {
                InternalToast.init(AgentApp.instance())
                InternalToast.show(msg, toastType, duration, Gravity.BOTTOM, 200.dp.toInt())
            }
        }
    }

    @JvmStatic
    private fun show(
        msg: String, toastType: Int = InternalToast.COMMON, duration: Int = Toast.LENGTH_SHORT,
        gravity: Int, offsetY: Int
    ) {
        if (Looper.getMainLooper().thread == Thread.currentThread()) {
            InternalToast.init(AgentApp.instance())
            InternalToast.show(msg, toastType, duration, gravity, offsetY)
        } else {
            mMainHandler.post {
                InternalToast.init(AgentApp.instance())
                InternalToast.show(msg, toastType, duration, gravity, offsetY)
            }
        }
    }
}