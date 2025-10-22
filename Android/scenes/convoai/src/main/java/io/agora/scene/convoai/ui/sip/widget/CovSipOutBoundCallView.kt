package io.agora.scene.convoai.ui.sip.widget

import android.content.Context
import android.graphics.Typeface
import android.text.Editable
import android.text.TextWatcher
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import androidx.core.content.ContextCompat
import androidx.core.widget.doAfterTextChanged
import androidx.fragment.app.FragmentActivity
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.R
import io.agora.scene.convoai.api.CovAgentPreset
import io.agora.scene.convoai.api.CovSipCallee
import io.agora.scene.convoai.databinding.CovOutboundCallLayoutBinding
import io.agora.scene.convoai.ui.sip.CallState
import io.agora.scene.convoai.ui.sip.CovSipRegionSelectionDialog

/**
 * SIP Outbound Call View with three states: IDLE, CALLING, CALLED
 * Manages UI state transitions for outbound phone calls
 */
class CovSipOutBoundCallView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val binding: CovOutboundCallLayoutBinding =
        CovOutboundCallLayoutBinding.inflate(LayoutInflater.from(context), this, true)

    private var currentState: CallState = CallState.IDLE
    private var phoneNumber: String = ""

    // Region data
    private var availableRegions = mutableListOf<CovSipCallee>()
    private var selectedRegion: CovSipCallee? = null

    // Error state management
    private var isErrorState = false

    // Unified callback interface
    var onCallActionListener: ((CallAction, String) -> Unit)? = null

    /**
     * Call actions enum
     */
    enum class CallAction {
        JOIN_CALL,    // User clicked join call button
        END_CALL,     // User clicked end call button
    }

    init {
        setupClickListeners()
        setupTextWatcher()
        setupRegionSelector()
        updateUIForState(CallState.IDLE)
    }

    /**
     * Set available regions from CovAgentPreset's sip_vendor_callee_numbers
     * This method dynamically updates the region selector based on the agent's supported regions
     */
    fun setPhoneNumbersFromPreset(preset: CovAgentPreset) {
        if (!preset.sip_vendor_callee_numbers.isNullOrEmpty()) {
            // Convert sip callees to region configs
            val availableRegionsFromPreset = preset.sip_vendor_callee_numbers

            if (availableRegionsFromPreset.isNotEmpty()) {
                // Update available regions list and recreate adapter
                updateAvailableRegions(availableRegionsFromPreset)
            }
        }
    }

    /**
     * Set the current call state and update UI accordingly
     */
    fun setCallState(state: CallState, phoneNumber: String = "") {
        if (currentState != state) {
            currentState = state
            if (phoneNumber.isNotEmpty()) {
                this.phoneNumber = phoneNumber
            }
            updateUIForState(state)
        }
    }

    /**
     * Toggle call information visibility for transcript display
     * When showing transcript: calling info (number + status) moves down and fades out over 0.5s
     * When hiding transcript: calling info moves back up and fades in over 0.5s
     * 
     * @param showTranscript true to hide call info and show transcript, false to restore call info
     */
    fun toggleTranscriptUpdate(showTranscript: Boolean) {
        if (currentState != CallState.CALLED && currentState != CallState.HANGUP) {
            // Only allow toggle during active call states
            return
        }

        if (showTranscript) {
            // Animate call info container out (includes phone number and calling status)
            binding.layoutCallingNumber.animate()
                .translationY(50f)
                .alpha(0f)
                .setDuration(500)
                .withEndAction {
                    binding.layoutCallingNumber.visibility = GONE
                }
                .start()
        } else {
            // Animate call info container back in
            binding.layoutCallingNumber.visibility = VISIBLE
            binding.layoutCallingNumber.animate()
                .translationY(0f)
                .alpha(1f)
                .setDuration(500)
                .start()
        }
    }

    /**
     * Get current phone number with region code
     */
    fun getFullPhoneNumber(): String {
        val number = getPhoneNumber()
        return if (number.isNotEmpty() && selectedRegion != null) "${selectedRegion!!.region_code}$number" else ""
    }

    /**
     * Get current entered phone number without region code
     */
    private fun getPhoneNumber(): String {
        return binding.etPhoneNumber.text.toString().trim()
    }

    /**
     * Update UI based on current state
     */
    private fun updateUIForState(state: CallState) {
        when (state) {
            CallState.IDLE -> {
                binding.layoutNotJoin.visibility = VISIBLE
                binding.layoutJoined.visibility = GONE
                binding.btnJoinCall.isEnabled = binding.etPhoneNumber.text.toString().trim().isNotEmpty()
                binding.layoutCallingNumber.visibility = VISIBLE
                binding.layoutCallingNumber.alpha = 1f
                binding.tvCallingNumber.stopShimmer()
            }

            CallState.CALLING -> {
                binding.layoutNotJoin.visibility = GONE
                binding.layoutJoined.visibility = VISIBLE

                // Update calling number display
                binding.tvCallingNumber.text = phoneNumber
                binding.tvCalling.setText(R.string.cov_sip_outbound_calling)
                binding.tvCallingNumber.startShimmer()
            }

            CallState.CALLED -> {
                binding.layoutNotJoin.visibility = GONE
                binding.layoutJoined.visibility = VISIBLE

                // Update connected number display
                binding.tvCallingNumber.text = phoneNumber
                binding.tvCalling.setText(R.string.cov_sip_call_in_progress)
                binding.tvCallingNumber.stopShimmer()
            }

            CallState.HANGUP -> {
                binding.layoutNotJoin.visibility = GONE
                binding.layoutJoined.visibility = VISIBLE

                // Update connected number display
                binding.tvCallingNumber.text = phoneNumber
                binding.tvCalling.setText(R.string.cov_sip_call_ended)
                binding.tvCallingNumber.stopShimmer()
            }
        }
    }

    /**
     * Setup click listeners
     */
    private fun setupClickListeners() {
        binding.btnJoinCall.setOnClickListener {
            sendCall()
        }

        binding.btnEndCall.setOnClickListener {
            setCallState(CallState.IDLE)
            onCallActionListener?.invoke(CallAction.END_CALL, "")
        }

        binding.ivClearInput.setOnClickListener {
            binding.etPhoneNumber.setText("")
        }

        binding.llRegionCode.setOnClickListener {
            showRegionDialog()
        }
    }

    private fun sendCall(){
        val phoneNumber = getPhoneNumber()
        if (phoneNumber.length >= 4 && phoneNumber.length <= 14) {
            clearErrorState()
            val fullNumber = getFullPhoneNumber()
            if (fullNumber.isNotEmpty()) {
                setCallState(CallState.CALLING, fullNumber)
                onCallActionListener?.invoke(CallAction.JOIN_CALL, fullNumber)
            }
        } else {
            showErrorState()
        }
    }

    private fun showRegionDialog() {
        val context = this.context
        if (context is FragmentActivity) {
            val dialog = CovSipRegionSelectionDialog.newInstance(
                data = availableRegions,
                onDismiss = {

                },
                onRegionSelected = { region ->
                    selectedRegion = availableRegions.firstOrNull {
                        it.region_name == region.name
                    }
                    updateRegionUI()
                }
            )
            dialog.show(context.supportFragmentManager, "region_selection_dialog")
        }
    }

    /**
     * Setup text watcher for phone number input
     */
    private fun setupTextWatcher() {
        binding.etPhoneNumber.apply {
            textSize = 14f
            doAfterTextChanged { text: Editable? ->
                val hasText = !text.isNullOrEmpty()
                binding.btnJoinCall.isEnabled = hasText && currentState == CallState.IDLE
                binding.ivClearInput.visibility = if (hasText) VISIBLE else GONE

                // Change text size and font weight based on content
                if (hasText) {
                    binding.etPhoneNumber.textSize = 18f
                    binding.etPhoneNumber.setTypeface(null, Typeface.BOLD)
                } else {
                    binding.etPhoneNumber.textSize = 14f
                    binding.etPhoneNumber.setTypeface(null, Typeface.NORMAL)
                }

                // Clear error state when user starts typing
                if (isErrorState && hasText) {
                    clearErrorState()
                }
            }
            setOnEditorActionListener { _, actionId, _ ->
                if (actionId == android.view.inputmethod.EditorInfo.IME_ACTION_SEND) {
                    hideKeyboard()
                    sendCall()
                    true
                } else {
                    false
                }

            }
        }
    }

    /**
     * Setup region selector with initial selection
     */
    private fun setupRegionSelector() {
        // Initialize with empty state - will be updated when setPhoneNumbersFromPreset is called
        updateRegionUI()
    }

    /**
     * Update available regions list and recreate adapter
     */
    private fun updateAvailableRegions(newRegions: List<CovSipCallee>) {
        availableRegions.clear()
        availableRegions.addAll(newRegions)

        // Set selected region to first available region if none selected or current selection is not in new list
        if (selectedRegion == null || selectedRegion !in availableRegions) {
            selectedRegion = availableRegions.firstOrNull()
            updateRegionUI()
        }
    }

    /**
     * Update region UI based on current selection
     */
    private fun updateRegionUI() {
        selectedRegion?.let { region ->
            binding.tvRegionFlag.text = region.flag_emoji
            binding.tvRegionCode.text = region.region_code
        } ?: run {
            // Show default/empty state when no region is selected
            binding.tvRegionFlag.text = "🌍"
            binding.tvRegionCode.text = "+"
        }
    }


    /**
     * Show error state with red border and error message
     */
    private fun showErrorState() {
        if (!isErrorState) {
            isErrorState = true
            binding.llInputContainer.setBackgroundResource(R.drawable.cov_sip_call_input_bg_error)
            binding.tvErrorHint.visibility = VISIBLE
            binding.etPhoneNumber.setTextColor(ContextCompat.getColor(context, io.agora.scene.common.R.color.ai_red6))
        }
    }

    /**
     * Clear error state and restore normal appearance
     */
    private fun clearErrorState() {
        if (isErrorState) {
            isErrorState = false
            binding.llInputContainer.setBackgroundResource(R.drawable.cov_sip_call_input_bg)
            binding.tvErrorHint.visibility = INVISIBLE
            binding.etPhoneNumber.setTextColor(
                ContextCompat.getColor(
                    context,
                    io.agora.scene.common.R.color.ai_brand_white10
                )
            )
        }
    }

    /**
     * Hide soft keyboard
     */
    private fun hideKeyboard() {
        binding.etPhoneNumber.clearFocus()
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.hideSoftInputFromWindow(binding.etPhoneNumber.windowToken, 0)
    }

    /**
     * Clean up popup when view is detached
     */
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
    }
}