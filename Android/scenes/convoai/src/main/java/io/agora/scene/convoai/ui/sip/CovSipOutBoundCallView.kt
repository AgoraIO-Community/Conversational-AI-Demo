package io.agora.scene.convoai.ui.sip

import android.content.Context
import android.text.Editable
import android.text.TextWatcher
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import android.widget.PopupWindow
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovOutboundCallLayoutBinding

/**
 * SIP Outbound Call View with three states: IDLE, CALLING, CALLED
 * Manages UI state transitions for outbound phone calls
 */
class CovSipOutBoundCallView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val binding: CovOutboundCallLayoutBinding = CovOutboundCallLayoutBinding.inflate(LayoutInflater.from(context), this, true)
    
    private var currentState: CallState = CallState.IDLE
    private var phoneNumber: String = ""
    
    // Country data
    private val availableCountries = listOf(
        CountryConfig.IN, // India
        CountryConfig.CL  // Chile
    )
    private var selectedCountry = availableCountries.first() // Default to first country
    
    // Country selector popup and adapter
    private var countryPopup: PopupWindow? = null
    private var countryAdapter: CountrySelectionAdapter? = null
    
    // Callback interfaces
    var onCallStateChangeListener: ((CallState, String) -> Unit)? = null
    var onJoinCallListener: ((String) -> Unit)? = null
    var onEndCallListener: (() -> Unit)? = null
    
    /**
     * Call states enum
     */
    enum class CallState {
        IDLE,    // Not calling, showing input UI
        CALLING, // Dialing/connecting
        CALLED   // Connected and in call
    }
    
    
    init {
        setupClickListeners()
        setupTextWatcher()
        setupCountrySelector()
        updateUIForState(CallState.IDLE)
    }

    /**
     * Set the current call state and update UI accordingly
     */
    fun setCallState(state: CallState, phoneNumber: String = "") {
        if (currentState != state) {
            currentState = state
            this.phoneNumber = phoneNumber
            updateUIForState(state)
            onCallStateChangeListener?.invoke(state, phoneNumber)
        }
    }

    /**
     * Get current phone number with country code
     */
    fun getFullPhoneNumber(): String {
        val number = binding.etPhoneNumber.text.toString().trim()
        return if (number.isNotEmpty()) "${selectedCountry.dialCode}-$number" else ""
    }
    
    /**
     * Get current entered phone number without country code
     */
    fun getPhoneNumber(): String {
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
                binding.tvCalling.visibility = INVISIBLE
            }
            
            CallState.CALLING -> {
                binding.layoutNotJoin.visibility = GONE
                binding.layoutJoined.visibility = VISIBLE
                
                // Update calling number display
                binding.tvCallingNumber.text = phoneNumber
                binding.tvCalling.visibility = VISIBLE
            }
            
            CallState.CALLED -> {
                binding.layoutNotJoin.visibility = GONE
                binding.layoutJoined.visibility = VISIBLE
                
                // Update connected number display
                binding.tvCallingNumber.text = phoneNumber
                binding.tvCalling.visibility = INVISIBLE
            }
        }
    }
    
    /**
     * Setup click listeners
     */
    private fun setupClickListeners() {
        binding.btnJoinCall.setOnClickListener {
            val fullNumber = getFullPhoneNumber()
            if (fullNumber.isNotEmpty()) {
                setCallState(CallState.CALLING, fullNumber)
                onJoinCallListener?.invoke(fullNumber)
            }
        }

        binding.btnEndCall.setOnClickListener {
            setCallState(CallState.IDLE)
            onEndCallListener?.invoke()
        }
        
        binding.ivClearInput.setOnClickListener {
            binding.etPhoneNumber.setText("")
        }
        
        binding.llCountryCode.setOnClickListener {
            showCountrySelector()
        }
    }
    
    /**
     * Setup text watcher for phone number input
     */
    private fun setupTextWatcher() {
        binding.etPhoneNumber.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                val hasText = !s.isNullOrEmpty()
                binding.btnJoinCall.isEnabled = hasText && currentState == CallState.IDLE
                binding.ivClearInput.visibility = if (hasText) VISIBLE else GONE
            }
            
            override fun afterTextChanged(s: Editable?) {}
        })
    }
    
    /**
     * Setup country selector with initial selection
     */
    private fun setupCountrySelector() {
        // Set initial country to first available country
        updateCountryUI()
    }
    
    /**
     * Show country selector popup
     */
    private fun showCountrySelector() {
        if (countryPopup?.isShowing == true) {
            countryPopup?.dismiss()
            return
        }
        
        createCountryPopup()
        countryPopup?.showAsDropDown(binding.llCountryCode, 0, 8)
    }
    
    /**
     * Create country selector popup window
     */
    private fun createCountryPopup() {
        val popupView = LayoutInflater.from(context).inflate(R.layout.cov_country_selector_popup, null)
        
        countryPopup = PopupWindow(
            popupView,
            LayoutParams.WRAP_CONTENT,
            LayoutParams.WRAP_CONTENT,
            true
        ).apply {
            isFocusable = true
            isOutsideTouchable = true
            elevation = 8f
        }
        
        setupRecyclerView(popupView)
    }
    
    /**
     * Setup RecyclerView with country adapter
     */
    private fun setupRecyclerView(popupView: View) {
        val recyclerView = popupView.findViewById<RecyclerView>(R.id.rv_countries)
        
        countryAdapter = CountrySelectionAdapter(availableCountries) { selectedCountryConfig ->
            selectedCountry = selectedCountryConfig
            updateCountryUI()
            countryPopup?.dismiss()
        }
        
        recyclerView.apply {
            layoutManager = LinearLayoutManager(context)
            adapter = countryAdapter
        }
        
        // Update adapter selection to current country
        countryAdapter?.updateSelection(selectedCountry.dialCode)
    }
    
    /**
     * Update country UI based on current selection
     */
    private fun updateCountryUI() {
        binding.tvCountryCode.text = selectedCountry.dialCode
        binding.ivCountryCode.text = selectedCountry.flagEmoji
    }
    
    /**
     * Clean up popup when view is detached
     */
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        countryPopup?.dismiss()
        countryPopup = null
    }
}