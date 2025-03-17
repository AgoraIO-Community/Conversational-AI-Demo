package io.agora.scene.convoai.iot.ui

import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.InputType
import android.text.Spannable
import android.text.SpannableString
import android.text.TextWatcher
import android.text.style.ForegroundColorSpan
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.TextView
import androidx.core.content.ContextCompat
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getStatusBarHeight
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.iot.CovLogger
import io.agora.scene.convoai.iot.R
import io.agora.scene.convoai.iot.databinding.CovActivityWifiSelectBinding
import io.agora.scene.convoai.iot.manager.CovScanBleDeviceManager
import io.iot.dn.ble.model.BleDevice
import io.iot.dn.wifi.manager.WifiManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class CovWifiSelectActivity : BaseActivity<CovActivityWifiSelectBinding>() {


    companion object {
        private const val TAG = "CovWifiSelectActivity"
        private const val EXTRA_DEVICE_ID = "extra_device_id"

        fun startActivity(activity: BaseActivity<*>, deviceId: String) {
            val intent = Intent(activity, CovWifiSelectActivity::class.java).apply {
                putExtra(EXTRA_DEVICE_ID, deviceId)
            }
            activity.startActivity(intent)

            // Add log to confirm if device object is correctly passed
            CovLogger.d("CovWifiSelectActivity", "Starting Wi-Fi selection page, passing device: $deviceId")
        }
    }

    // Create coroutine scope for asynchronous operations
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Current connected Wi-Fi network
    private var currentWifi: String? = null

    // Whether password is visible
    private var isPasswordVisible = false

    private lateinit var bleDevice: BleDevice

    // Add WiFi manager
    private lateinit var wifiManager: WifiManager

    override fun getViewBinding(): CovActivityWifiSelectBinding {
        return CovActivityWifiSelectBinding.inflate(layoutInflater)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize WiFi manager
        wifiManager = WifiManager(this)

        // Get device ID
        val deviceId = intent.getStringExtra(EXTRA_DEVICE_ID) ?: ""

        // Get device from device manager
        val device = CovScanBleDeviceManager.getDevice(deviceId)
        if (device == null) {
            // Device doesn't exist, show error and return
            finish()
            return
        }

        // Save device information
        bleDevice = device

        // Continue initialization
        initData()
    }

    override fun initView() {
        setupView()
        setupPasswordToggle()
        setupWifiSelection()
        setupNextButton()
        setupTitleWithColoredText()
    }

    private fun setupTitleWithColoredText() {
        mBinding?.apply {
            // Get the three parts of text
            val part1 = getString(R.string.cov_iot_wifi_title_part1)
            val part2 = getString(R.string.cov_iot_wifi_title_part2)
            val part3 = getString(R.string.cov_iot_wifi_title_part3)

            // Create full text
            val fullText = part1 + part2 + part3

            // Create SpannableString
            val spannableString = SpannableString(fullText)

            // Set color for the second part
            val part1Length = part1.length
            val part2Length = part2.length
            spannableString.setSpan(
                ForegroundColorSpan(ContextCompat.getColor(this@CovWifiSelectActivity, io.agora.scene.common.R.color.ai_green6)),
                part1Length,
                part1Length + part2Length,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
            )

            // Set color for the first and third parts
            spannableString.setSpan(
                ForegroundColorSpan(ContextCompat.getColor(this@CovWifiSelectActivity, io.agora.scene.common.R.color.ai_icontext1)),
                0,
                part1Length,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
            )
            spannableString.setSpan(
                ForegroundColorSpan(ContextCompat.getColor(this@CovWifiSelectActivity, io.agora.scene.common.R.color.ai_icontext1)),
                part1Length + part2Length,
                fullText.length,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
            )

            // Set text to TextView
            tvTitleWifi.text = spannableString
        }
    }

    override fun onDestroy() {
        coroutineScope.cancel()
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        // Get current Wi-Fi information every time the page resumes
        getCurrentWifi()
    }

    private fun setupView() {
        mBinding?.apply {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            val statusBarHeight = getStatusBarHeight() ?: 25.dp.toInt()
            CovLogger.d(TAG, "statusBarHeight $statusBarHeight")
            val layoutParams = clTitleBar.layoutParams as ViewGroup.MarginLayoutParams
            layoutParams.topMargin = statusBarHeight
            clTitleBar.layoutParams = layoutParams

            // Set back button click event
            ivBack.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    finish()
                }
            })
        }
    }

    private fun setupPasswordToggle() {
        mBinding?.apply {
            // Set password visibility toggle
            ivTogglePassword.setOnClickListener {
                isPasswordVisible = !isPasswordVisible

                // Update password input field type
                if (isPasswordVisible) {
                    etWifiPassword.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
                    ivTogglePassword.setImageResource(R.drawable.cov_iot_show_pw)
                } else {
                    etWifiPassword.inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
                    ivTogglePassword.setImageResource(R.drawable.cov_iot_hide_pw)
                }

                // Move cursor to the end of text
                etWifiPassword.setSelection(etWifiPassword.text.length)
            }

            // Monitor password input changes
            etWifiPassword.addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}

                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}

                override fun afterTextChanged(s: Editable?) {
                    // Enable or disable next button based on password length
                    val isEnabled = !s.isNullOrEmpty() && s.length >= 8
                    btnNext.isEnabled = isEnabled
                    // Set alpha value based on button state
                    btnNext.alpha = if (isEnabled) 1.0f else 0.5f
                }
            })
        }
    }

    private fun setupWifiSelection() {
        mBinding?.apply {
            // Set current Wi-Fi name
            currentWifi?.let {
                tvWifiName.text = it
            }

            // Set change Wi-Fi button click event - open system Wi-Fi settings
            btnChangeWifi.setOnClickListener {
                openWifiSettings()
            }
        }
    }

    private fun setupNextButton() {
        mBinding?.apply {
            // Disable next button in initial state
            btnNext.isEnabled = false
            // Set initial alpha value
            btnNext.alpha = 0.5f

            // Set next button click event
            btnNext.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    val password = etWifiPassword.text.toString()

                    if (password.length < 8) {
                        ToastUtil.show("Wi-Fi password must be at least 8 characters")
                        return
                    }

                    // Save Wi-Fi information and proceed to next step
                    currentWifi?.let {
                        startDeviceConnectActivity(password)
                    } ?: run {
                        ToastUtil.show("Please select a Wi-Fi network first")
                    }
                }
            })
        }
    }

    private fun initData() {
        // Add log output to check if device is null
        CovLogger.d(TAG, "Configuring device Wi-Fi: ${bleDevice.name}")

        // Get currently connected Wi-Fi
        getCurrentWifi()
    }

    // Get current Wi-Fi information
    private fun getCurrentWifi() {
        coroutineScope.launch(Dispatchers.IO) {
            try {
                // Use WifiManager to get current Wi-Fi information
                val wifiInfo = wifiManager.getCurrentWifiInfo()

                if (wifiInfo != null) {
                    currentWifi = wifiInfo.ssid

                    // Check WiFi frequency band
                    val is5GHz = !wifiManager.is24GHzWifi(wifiInfo.frequency)

                    launch(Dispatchers.Main) {
                        mBinding?.tvWifiName?.text = currentWifi ?: ""

                        if (is5GHz) {
                            // 5G WiFi - show in red and disable password input
                            mBinding?.tvWifiName?.setTextColor(resources.getColor(io.agora.scene.common.R.color.ai_red6, null))
                            mBinding?.etWifiPassword?.isEnabled = false
                            mBinding?.btnNext?.isEnabled = false
                            mBinding?.btnNext?.alpha = 0.5f
                            mBinding?.tvWifiWarning?.visibility = View.VISIBLE
                        } else {
                            // 2.4G WiFi - normal display
                            mBinding?.tvWifiName?.setTextColor(resources.getColor(io.agora.scene.common.R.color.ai_icontext1, null))
                            mBinding?.etWifiPassword?.isEnabled = true
                            mBinding?.tvWifiWarning?.visibility = View.GONE

                            // Update UI state, ensure next button is enabled when Wi-Fi is connected (if password is entered)
                            val isEnabled = !mBinding?.etWifiPassword?.text.isNullOrEmpty() &&
                                    (mBinding?.etWifiPassword?.text?.length ?: 0) >= 8
                            mBinding?.btnNext?.isEnabled = isEnabled
                            // Set alpha value based on button state
                            mBinding?.btnNext?.alpha = if (isEnabled) 1.0f else 0.5f
                        }
                    }
                } else {
                    launch(Dispatchers.Main) {
                        mBinding?.tvWifiName?.text = ""
                        mBinding?.btnNext?.isEnabled = false
                        mBinding?.btnNext?.alpha = 0.5f
                        mBinding?.tvWifiWarning?.visibility = View.GONE
                        ToastUtil.show("No Wi-Fi connection detected, please connect to Wi-Fi first")
                    }
                }
            } catch (e: Exception) {
                CovLogger.e(TAG, "Failed to get Wi-Fi information: ${e.message}")

                launch(Dispatchers.Main) {
                    ToastUtil.show("Failed to get Wi-Fi information")
                }
            }
        }
    }

    // Open system Wi-Fi settings page
    private fun openWifiSettings() {
        try {
            val intent = Intent(android.provider.Settings.ACTION_WIFI_SETTINGS)
            startActivity(intent)
        } catch (e: Exception) {
            CovLogger.e(TAG, "Failed to open Wi-Fi settings: ${e.message}")
            ToastUtil.show("Unable to open Wi-Fi settings")
        }
    }

    // Start device connection page
    private fun startDeviceConnectActivity(wifiPassword: String) {
        // Pass Wi-Fi information to device connection page
        CovDeviceConnectActivity.startActivity(this, bleDevice.address, currentWifi ?: "", wifiPassword)
    }
}