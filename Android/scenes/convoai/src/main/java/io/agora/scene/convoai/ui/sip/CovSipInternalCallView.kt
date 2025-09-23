package io.agora.scene.convoai.ui.sip

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.AttributeSet
import android.view.LayoutInflater
import android.widget.FrameLayout
import android.widget.Toast
import androidx.core.net.toUri
import androidx.fragment.app.FragmentActivity
import io.agora.scene.convoai.api.CovAgentPreset
import io.agora.scene.convoai.databinding.CovInternalCallLayoutBinding

/**
 * SIP Internal Call View for displaying India and Chile phone numbers
 * Provides clickable phone numbers that can initiate calls
 */
class CovSipInternalCallView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val binding: CovInternalCallLayoutBinding = CovInternalCallLayoutBinding.inflate(LayoutInflater.from(context), this, true)
    
    init {
        setupView()
    }

    /**
     * Set the india number
     */
    fun setIndiaNumber(phoneNumber: String) {
        binding.tvIndiaPhone.text = phoneNumber
    }


    /**
     * Set the chile number
     */
    fun setChileNumber(phoneNumber: String) {
        binding.tvChilePhone.text = phoneNumber
    }

    /**
     * Set phone numbers from CovAgentPreset's sip_vendor_callee_numbers
     * This method dynamically sets phone numbers based on the agent's supported regions
     */
    fun setPhoneNumbersFromPreset(preset: CovAgentPreset) {
        if (!preset.sip_vendor_callee_numbers.isNullOrEmpty()) {
            // Find India and Chile numbers from sip callees
            val indiaCallee = preset.sip_vendor_callee_numbers.find { it.region_code == CountryConfig.IN.dialCode }
            val chileCallee = preset.sip_vendor_callee_numbers.find { it.region_code == CountryConfig.CL.dialCode }
            
            indiaCallee?.let {
                setIndiaNumber("+${it.region_code}-${it.phone_number}")
            }
            chileCallee?.let {
                setChileNumber("+${it.region_code}-${it.phone_number}")
            }
        }
    }
    
    /**
     * Setup click listeners for phone numbers
     */
    private fun setupView() {
        binding.tvIndiaEmoji.text = CountryConfig.IN.flagEmoji
        binding.tvIndiaCode.text = CountryConfig.IN.countryCode

        binding.tvChileEmoji.text = CountryConfig.CL.flagEmoji
        binding.tvChileCode.text = CountryConfig.CL.countryCode

        binding.tvIndiaPhone.setOnClickListener {
            val phoneNumber = binding.tvIndiaPhone.text.toString()
            if (phoneNumber.isNotEmpty()) {
                showCallPhoneDialog(phoneNumber)
            }
        }
        
        binding.tvChilePhone.setOnClickListener {
            val phoneNumber = binding.tvChilePhone.text.toString()
            if (phoneNumber.isNotEmpty()) {
                showCallPhoneDialog(phoneNumber)
            }
        }
    }
    
    /**
     * Show call phone dialog
     */
    private fun showCallPhoneDialog(phoneNumber: String) {
//        val callNumber = phoneNumber.replace("+", "").replace("-", "")
        
        val context = this.context
        if (context is FragmentActivity) {
            val dialog = CovSipCallPhoneDialog().apply {
                arguments = Bundle().apply {
                    putString(CovSipCallPhoneDialog.KEY_PHONE, phoneNumber)
                }
            }
            
            dialog.onClickCallPhone = {
                makePhoneCall(phoneNumber)
            }
            
            dialog.show(context.supportFragmentManager, "CallPhoneDialog")
        } else {
            makePhoneCall(phoneNumber)
        }
    }
    
    /**
     * Make a phone call to the specified number
     */
    private fun makePhoneCall(phoneNumber: String) {
        try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = "tel:$phoneNumber".toUri()
            }
            context.startActivity(intent)
        } catch (e: SecurityException) {
            // If no CALL_PHONE permission, fallback to dialer
            showDialer(phoneNumber)
        } catch (e: Exception) {
            Toast.makeText(context, "Unable to make call", Toast.LENGTH_SHORT).show()
        }
    }
    
    /**
     * Show dialer with pre-filled number
     */
    private fun showDialer(cleanNumber: String) {
        try {
            val intent = Intent(Intent.ACTION_DIAL).apply {
                data = "tel:$cleanNumber".toUri()
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(context, "Unable to open dialer", Toast.LENGTH_SHORT).show()
        }
    }
    
}