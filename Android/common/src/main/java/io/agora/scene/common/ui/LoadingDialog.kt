package io.agora.scene.common.ui

import android.app.Dialog
import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import io.agora.scene.common.R
import io.agora.scene.common.databinding.LoadingDialogBinding

class LoadingDialog(context: Context) : Dialog(context) {

    private var color: Int = R.color.ai_fill1

    private val binding: LoadingDialogBinding by lazy {
        LoadingDialogBinding.inflate(LayoutInflater.from(context))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(binding.root)

        window?.setBackgroundDrawableResource(android.R.color.transparent)
        binding.loadingProgress.indeterminateTintList = android.content.res.ColorStateList.valueOf(context.resources.getColor(color))
        setCancelable(false)
    }

    fun setMessage(message: String) {
        binding.loadingText.text = message
    }

    fun setProgressBarColor(color: Int) {
        this.color = color
    }
}