package io.agora.scene.convoai.iot.ui.dialog

import android.content.DialogInterface
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.widget.ViewPager2
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.convoai.iot.R
import io.agora.scene.convoai.iot.databinding.CovDeviceConnectionFailedDialogBinding

class CovDeviceConnectionFailedDialog : BaseSheetDialog<CovDeviceConnectionFailedDialogBinding>() {

    private var onDismissCallback: (() -> Unit)? = null
    private var onRescanCallback: (() -> Unit)? = null
    
    // Check step data class
    private data class CheckStep(val imageResId: Int, val text: String)
    
    // Check steps list
    private lateinit var checkSteps: List<CheckStep>
    
    // Current step index
    private var currentStepIndex = 0
    
    // ViewPager adapter
    private inner class CheckStepsAdapter : RecyclerView.Adapter<CheckStepsAdapter.CheckStepViewHolder>() {
        
        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CheckStepViewHolder {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.item_check_step, parent, false)
            return CheckStepViewHolder(view)
        }
        
        override fun onBindViewHolder(holder: CheckStepViewHolder, position: Int) {
            val checkStep = checkSteps[position]
            holder.bind(checkStep)
        }
        
        override fun getItemCount(): Int = checkSteps.size
        
        inner class CheckStepViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
            private val imageView: ImageView = itemView.findViewById(R.id.iv_check_step)
            private val textView: TextView = itemView.findViewById(R.id.tv_check_step)
            
            fun bind(checkStep: CheckStep) {
                imageView.setImageResource(checkStep.imageResId)
                textView.text = checkStep.text
            }
        }
    }

    companion object {
        private const val TAG = "DeviceConnectionFailedDialog"

        fun newInstance(
            onDismiss: () -> Unit,
            onRescan: () -> Unit
        ): CovDeviceConnectionFailedDialog {
            return CovDeviceConnectionFailedDialog().apply {
                this.onDismissCallback = onDismiss
                this.onRescanCallback = onRescan
            }
        }
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        onDismissCallback?.invoke()
    }

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovDeviceConnectionFailedDialogBinding {
        return CovDeviceConnectionFailedDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        // Initialize check steps data
        checkSteps = listOf(
            CheckStep(
                R.drawable.cov_iot_wifi_bg,
                getString(R.string.cov_iot_devices_connect_connect_failed_check_wifi)
            ),
            CheckStep(
                R.drawable.cov_iot_device_bg,
                getString(R.string.cov_iot_devices_connect_connect_failed_check_device)
            ),
            CheckStep(
                R.drawable.cov_iot_router_bg,
                getString(R.string.cov_iot_devices_connect_connect_failed_check_net)
            )
        )

        binding?.apply {
            setOnApplyWindowInsets(root)
            
            // Set close button click event
            btnClose.setOnClickListener {
                dismiss()
            }
            
            // Set rescan button click event
            btnRescan.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onRescanCallback?.invoke()
                    dismiss()
                }
            })
            
            // Set up ViewPager
            setupViewPager()
        }
    }
    
    private fun setupViewPager() {
        binding?.apply {
            // Set ViewPager adapter
            val adapter = CheckStepsAdapter()
            viewpagerCheckSteps.adapter = adapter
            
            // Set page change listener
            viewpagerCheckSteps.registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
                override fun onPageSelected(position: Int) {
                    currentStepIndex = position
                    updateIndicators(position)
                }
            })
            
            // Initial state setup
            viewpagerCheckSteps.setCurrentItem(currentStepIndex, false)
            updateIndicators(currentStepIndex)
        }
    }
    
    private fun updateIndicators(position: Int) {
        binding?.apply {
            // Update indicator states
            indicator1.setBackgroundResource(
                if (position == 0) R.drawable.shape_indicator_selected else R.drawable.shape_indicator_normal)
            indicator2.setBackgroundResource(
                if (position == 1) R.drawable.shape_indicator_selected else R.drawable.shape_indicator_normal)
            indicator3.setBackgroundResource(
                if (position == 2) R.drawable.shape_indicator_selected else R.drawable.shape_indicator_normal)
        }
    }

    override fun disableDragging(): Boolean {
        return true
    }
} 