package io.agora.agent

import android.Manifest
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.ui.BaseActivity
import java.util.Locale
import android.annotation.SuppressLint
import androidx.activity.viewModels
import androidx.core.os.LocaleListCompat
import androidx.appcompat.app.AppCompatDelegate
import io.agora.agent.databinding.WelcomeActivityBinding
import io.agora.scene.common.constant.AgentScenes
import io.agora.scene.common.constant.SSOUserManager
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.common.debugMode.DebugConfigSettings
import io.agora.scene.common.debugMode.DebugButton
import io.agora.scene.common.ui.vm.LoginViewModel
import io.agora.scene.convoai.ui.CovLivingActivity

class WelcomeActivity : BaseActivity<WelcomeActivityBinding>() {


    private val mLoginViewModel: LoginViewModel by viewModels()

    override fun getViewBinding(): WelcomeActivityBinding {
        return WelcomeActivityBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        DebugConfigSettings.init(this, BuildConfig.IS_MAINLAND)
        ServerConfig.initBuildConfig(
            BuildConfig.IS_MAINLAND,
            "",
            BuildConfig.TOOLBOX_SERVER_HOST,
            BuildConfig.AG_APP_ID,
            BuildConfig.AG_APP_CERTIFICATE
        )
        setupLocale()
        super.onCreate(savedInstanceState)
    }

    override fun initView() {
        setupView()
        val tempToken = SSOUserManager.getToken()
        if (tempToken.isNotEmpty()) {
            mLoginViewModel.getUserInfoByToken(tempToken)
            mLoginViewModel.userInfoLiveData.observe(this) { userInfo ->
                goScene(AgentScenes.ConvoAi)
            }
        }else{
            goScene(AgentScenes.ConvoAi)
        }
    }

    private fun goScene(scene: AgentScenes) {
        try {
            val intent = when (scene) {
                AgentScenes.ConvoAi -> Intent(this, CovLivingActivity::class.java)
                else -> Intent()
            }
            startActivity(intent)
            finish()
        } catch (e: Exception) {
            ToastUtil.show(getString(R.string.scenes_coming_soon))
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        setupLocale()
    }

    override fun onResume() {
        super.onResume()
        setupLocale()
    }

    override fun onPause() {
        super.onPause()
        // Clear debug callback when activity is paused
        DebugButton.setDebugCallback(null)
    }

    private fun setupView() {
        mBinding?.apply {
            setOnApplyWindowInsetsListener(root)
            // Set logo based on region
            if (ServerConfig.isMainlandVersion) {
                ivLogo.setImageResource(R.drawable.app_main_logo_cn)
                ivLogo.setColorFilter(Color.WHITE)
            } else {
                ivLogo.setImageResource(R.drawable.app_main_logo)
                ivLogo.clearColorFilter()
            }
        }
    }

    private fun setupLocale() {
        val lang = if (ServerConfig.isMainlandVersion) "zh" else "en"
        val locale = Locale(lang)

        AppCompatDelegate.setApplicationLocales(LocaleListCompat.create(locale))

        updateActivityLocale(locale)
    }

    @SuppressLint("ObsoleteSdkInt")
    private fun updateActivityLocale(locale: Locale) {
        Locale.setDefault(locale)

        val config = resources.configuration
        config.setLocale(locale)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            createConfigurationContext(config)
        } else {
            @Suppress("DEPRECATION")
            resources.updateConfiguration(config, resources.displayMetrics)
        }
    }
}