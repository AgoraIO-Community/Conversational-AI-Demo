package io.agora.scene.convoai.ui

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.text.SpannableString
import android.text.Spanned
import android.text.TextPaint
import android.text.method.LinkMovementMethod
import android.text.style.ClickableSpan
import android.view.View
import android.view.animation.Animation
import android.view.animation.TranslateAnimation
import android.widget.CompoundButton
import android.widget.TextView
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContract
import androidx.core.view.isInvisible
import androidx.core.view.isVisible
import io.agora.scene.common.R
import io.agora.scene.common.constant.SSOUserManager
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.ui.SSOWebViewActivity
import io.agora.scene.common.ui.TermsActivity
import io.agora.scene.convoai.databinding.CovActivityLoginBinding
import kotlin.apply
import kotlin.jvm.java

class CovLoginActivity : BaseActivity<CovActivityLoginBinding>() {

    private val TAG = "CovLoginActivity"

    private lateinit var activityResultLauncher: ActivityResultLauncher<Int>

    private class SSOWebViewContract : ActivityResultContract<Int, String?>() {
        override fun createIntent(context: Context, input: Int): Intent {
            return Intent(context, SSOWebViewActivity::class.java).apply {
                putExtra(SSOWebViewActivity.EXTRA_TYPE, input)
            }
        }

        override fun parseResult(resultCode: Int, intent: Intent?): String? {
            return if (resultCode == Activity.RESULT_OK) {
                intent?.getStringExtra(SSOWebViewActivity.EXTRA_TOKEN)
            } else {
                null
            }
        }
    }

    override fun getViewBinding(): CovActivityLoginBinding = CovActivityLoginBinding.inflate(layoutInflater)

    override fun supportOnBackPressed(): Boolean = false

    override fun initView() {

        activityResultLauncher = registerForActivityResult(SSOWebViewContract()) { token: String? ->
            if (token != null) {
                SSOUserManager.saveToken(token)
                initFirebaseCrashlytics()
                mBinding?.root?.postDelayed({
                    startActivity(Intent(this@CovLoginActivity, CovAgentListActivity::class.java))
                    finish()
                }, 500L)
            }
        }
        mBinding?.apply {
            tvTyping.startAnimation()
            setupRichTextTerms(tvTermsRichText)
            btnLoginSSO.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    if (cbTerms.isChecked) {
                        activityResultLauncher.launch(SSOWebViewActivity.TYPE_LOGIN)
                    } else {
                        animCheckTip()
                    }
                }
            })
            btnSignUp.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    if (cbTerms.isChecked) {
                        activityResultLauncher.launch(SSOWebViewActivity.TYPE_SIGNUP)
                    } else {
                        animCheckTip()
                    }
                }
            })
            cbTerms.setOnCheckedChangeListener { buttonView: CompoundButton?, isChecked: Boolean ->
                if (tvCheckTips.isVisible) {
                    tvCheckTips.isInvisible = true
                }
            }
        }
    }

    private fun setupRichTextTerms(textView: TextView) {
        val acceptText = getString(R.string.common_acceept)
        val termsText = getString(R.string.common_terms_of_services)
        val andText = getString(R.string.common_and)
        val privacyText = getString(R.string.common_privacy_policy)

        // Use StringBuilder to avoid string concatenation issues
        val fullText = StringBuilder().apply {
            append(acceptText)
            append(termsText)
            append(andText)
            append(privacyText)
        }.toString()

        val spannable = SpannableString(fullText)

        val acceptStart = 0
        val acceptEnd = acceptText.length

        val termsOfServicesStart = acceptEnd
        val termsOfServicesEnd = termsOfServicesStart + termsText.length

        val privacyPolicyStart = termsOfServicesEnd + andText.length
        val privacyPolicyEnd = privacyPolicyStart + privacyText.length

        // Accept text span - clickable to toggle checkbox
        spannable.setSpan(object : ClickableSpan() {
            override fun onClick(widget: View) {
                mBinding?.cbTerms?.isChecked = mBinding?.cbTerms?.isChecked != true
            }

            override fun updateDrawState(ds: TextPaint) {
                ds.color = textView.currentTextColor
                ds.isUnderlineText = false
                ds.letterSpacing = 0.0f // Explicitly set letter spacing
            }
        }, acceptStart, acceptEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

        // Terms of services span
        spannable.setSpan(object : ClickableSpan() {
            override fun onClick(widget: View) {
                TermsActivity.startActivity(this@CovLoginActivity, ServerConfig.termsOfServicesUrl)
            }

            override fun updateDrawState(ds: TextPaint) {
                ds.color = textView.currentTextColor
                ds.isUnderlineText = true
                ds.letterSpacing = 0.0f // Explicitly set letter spacing
            }
        }, termsOfServicesStart, termsOfServicesEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

        // Privacy policy span
        spannable.setSpan(object : ClickableSpan() {
            override fun onClick(widget: View) {
                TermsActivity.startActivity(this@CovLoginActivity, ServerConfig.privacyPolicyUrl)
            }

            override fun updateDrawState(ds: TextPaint) {
                ds.color = textView.currentTextColor
                ds.isUnderlineText = true
                ds.letterSpacing = 0.0f // Explicitly set letter spacing
            }
        }, privacyPolicyStart, privacyPolicyEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

        textView.movementMethod = LinkMovementMethod.getInstance()
        textView.text = spannable
    }

    private fun animCheckTip() {
        mBinding?.apply {
            tvCheckTips.visibility = View.VISIBLE
            val animation = TranslateAnimation(
                -10f, 10f, 0f, 0f
            )
            animation.duration = 60
            animation.repeatCount = 4
            animation.repeatMode = Animation.REVERSE
            tvCheckTips.clearAnimation()
            tvCheckTips.startAnimation(animation)
        }
    }
}