package io.agora.scene.convoai.ui.mine

import android.app.Activity
import android.content.Intent
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.convoai.databinding.CovActivityProfilePrivacyBinding
import kotlin.apply
import kotlin.jvm.java

class CovProfilePrivacyActivity : BaseActivity<CovActivityProfilePrivacyBinding>() {

    companion object Companion {
        fun startActivity(activity: Activity) {
            val intent = Intent(activity, CovProfilePrivacyActivity::class.java)
            activity.startActivity(intent)
        }
    }

    override fun getViewBinding(): CovActivityProfilePrivacyBinding {
        return CovActivityProfilePrivacyBinding.inflate(layoutInflater)
    }

    override fun initView() {
        mBinding?.apply {
            // Adjust top margin for status bar
            customTitleBar.setDefaultMargin(this@CovProfilePrivacyActivity)
            customTitleBar.setOnBackClickListener {
                onHandleOnBackPressed()
            }

            clAgreement.setOnClickListener {
                TermsActivity.startActivity(this@CovProfilePrivacyActivity, ServerConfig.termsOfServicesUrl)
            }

            clPrivacyPolicy.setOnClickListener {
                TermsActivity.startActivity(this@CovProfilePrivacyActivity, ServerConfig.privacyPolicyUrl)
            }
        }
    }
}
