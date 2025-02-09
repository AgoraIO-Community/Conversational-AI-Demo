package io.agora.scene.convoai.ui

import android.content.DialogInterface
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import io.agora.rtc2.Constants
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovInfoDialogBinding
import io.agora.scene.convoai.manager.AgentConnectionState
import io.agora.scene.convoai.manager.CovAgentManager
import io.agora.scene.convoai.manager.CovRtcManager

class CovAgentInfoDialog(private val onDismiss: () -> Unit) : BaseSheetDialog<CovInfoDialogBinding>() {

    private var value: Int = 0

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovInfoDialogBinding {
        return CovInfoDialogBinding.inflate(inflater, container, false)
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        onDismiss.invoke()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding?.apply {
            setOnApplyWindowInsets(root)
            when (CovAgentManager.connectionState) {
                AgentConnectionState.IDLE -> {
                    context?.let {
                        mtvNetworkStatus.text = getString(R.string.cov_info_your_network_disconnected)
                        mtvNetworkStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))

                        mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                        mtvRoomStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))

                        mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                        mtvAgentStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))

                        mtvRoomId.text = getString(R.string.cov_info_empty)
                        mtvUidValue.text = getString(R.string.cov_info_empty)
                    }
                }
                AgentConnectionState.CONNECTING -> {
                    context?.let {
                        mtvNetworkStatus.text = getString(R.string.cov_info_your_network_disconnected)
                        mtvNetworkStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))

                        mtvNetworkStatus.text = getString(R.string.cov_info_your_network_disconnected)
                        mtvNetworkStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))

                        mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                        mtvRoomStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))

                        mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                        mtvAgentStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))

                        mtvRoomId.text = CovRtcManager.channelName
                        mtvUidValue.text = CovRtcManager.uid.toString()
                    }
                }
                AgentConnectionState.CONNECTED -> {
                    context?.let {
                        updateNetworkStatus(value)
                        mtvRoomStatus.text = getString(R.string.cov_info_agent_connected)
                        mtvRoomStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_green6))

                        mtvAgentStatus.text = getString(R.string.cov_info_agent_connected)
                        mtvAgentStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_green6))

                        mtvRoomId.text = CovRtcManager.channelName
                        mtvUidValue.text = CovRtcManager.uid.toString()
                    }
                }
                AgentConnectionState.CONNECTED_INTERRUPT -> {
                    context?.let {
                        updateNetworkStatus(value)
                        mtvRoomStatus.text = getString(R.string.cov_info_agent_connected)
                        mtvRoomStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_green6))

                        mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                        mtvAgentStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))

                        mtvRoomId.text = CovRtcManager.channelName
                        mtvUidValue.text = CovRtcManager.uid.toString()
                    }
                }
            }
            btnClose.setOnClickListener {
                dismiss()
            }
        }
    }

    fun updateNetworkStatus(value: Int) {
        this.value = value
        val context = context ?: return
        binding?.apply {
            when (value) {
                Constants.QUALITY_EXCELLENT, Constants.QUALITY_GOOD -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_good)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_green6))
                }
                Constants.QUALITY_POOR, Constants.QUALITY_BAD -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_medium)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_yellow6))
                }
                else -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_poor)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))
                }
            }
        }
    }
}