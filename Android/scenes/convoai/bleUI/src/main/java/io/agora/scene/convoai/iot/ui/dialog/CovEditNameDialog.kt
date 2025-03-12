package io.agora.scene.convoai.iot.ui.dialog

import android.app.Dialog
import android.content.Context
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.Gravity
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager
import android.widget.FrameLayout
import io.agora.scene.convoai.iot.R
import io.agora.scene.convoai.iot.databinding.CovEditNameDialogBinding

class CovEditNameDialog(
    context: Context,
    private val initialName: String,
    private val onConfirm: (String) -> Unit
) : Dialog(context) {

    private lateinit var binding: CovEditNameDialogBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        binding = CovEditNameDialogBinding.inflate(layoutInflater)
        setContentView(binding.root)

        window?.apply {
            setGravity(Gravity.BOTTOM)
            
            val leftRightMargin = context.resources.getDimensionPixelSize(R.dimen.dp_20)
            val bottomMargin = context.resources.getDimensionPixelSize(R.dimen.dp_17)
            
            val displayMetrics = context.resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            
            val params = attributes
            params.width = screenWidth - 2 * leftRightMargin
            params.y = bottomMargin
            attributes = params
            
            setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
            
            setBackgroundDrawableResource(android.R.color.transparent)
        }

        setupUI()
        
        setupListeners()
    }

    private fun setupUI() {
        binding.etName.setText(initialName)
        
        val maxLength = 10
        val selectionPosition = minOf(initialName.length, maxLength)
        binding.etName.setSelection(selectionPosition)
        binding.etName.requestFocus()
    }

    private fun setupListeners() {
        binding.ivClose.setOnClickListener {
            dismiss()
        }

        binding.btnConfirm.setOnClickListener {
            val newName = binding.etName.text.toString().trim()
            if (newName.isNotEmpty()) {
                onConfirm(newName)
                dismiss()
            }
        }

        binding.ivClear.setOnClickListener {
            binding.etName.text.clear()
            binding.ivClear.visibility = android.view.View.GONE
        }

        binding.etName.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}

            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}

            override fun afterTextChanged(s: Editable?) {
                val text = s.toString()
                val isEmpty = text.trim().isEmpty()
                
                binding.ivClear.visibility = if (isEmpty) android.view.View.GONE else android.view.View.VISIBLE
                
                binding.tvLimitTip.text = if (isEmpty) {
                    context.getString(R.string.cov_iot_devices_setting_name_limit)
                } else {
                    context.getString(R.string.cov_iot_devices_setting_name_limit)
                }
            }
        })
    }

    companion object {
        fun show(
            context: Context,
            initialName: String,
            onConfirm: (String) -> Unit
        ): CovEditNameDialog {
            val dialog = CovEditNameDialog(context, initialName, onConfirm)
            dialog.window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
            dialog.show()
            return dialog
        }
    }
} 