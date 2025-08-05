package io.agora.scene.convoai.ui.fragment

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.common.ui.BaseFragment
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.GlideImageLoader
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.api.CovAgentApiManager
import io.agora.scene.convoai.api.CovAgentPreset
import io.agora.scene.convoai.constant.CovAgentManager
import io.agora.scene.convoai.databinding.CovAvatarSelectorCloseItemBinding
import io.agora.scene.convoai.databinding.CovFragmentOfficialAgentBinding
import io.agora.scene.convoai.databinding.CovItemOfficialAgentBinding
import io.agora.scene.convoai.ui.CovLivingActivity
import io.agora.scene.convoai.ui.dialog.CovAvatarSelectorDialog.AvatarItem

class CovOfficialAgentFragment : BaseFragment<CovFragmentOfficialAgentBinding>() {

    private lateinit var adapter: OfficialAgentAdapter

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovFragmentOfficialAgentBinding? {
        return CovFragmentOfficialAgentBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        initViews()
        setupAdapter()
        loadPresets()
    }


    private fun initViews() {
        mBinding?.apply {
            btnRetry.setOnClickListener {
                loadPresets()
            }
        }
    }

    private fun setupAdapter() {
        adapter = OfficialAgentAdapter { preset ->
            onPresetSelected(preset)
        }
        mBinding?.apply {
            rvOfficialAgents.adapter = adapter
        }
    }

    private fun loadPresets() {
        showLoading()
        CovAgentApiManager.fetchPresets { error, presets ->
            if (error != null) {
                CovLogger.e("OfficialAgentFragment", "Failed to load presets: ${error.message}")
                showError()
            } else {
                if (presets.isNotEmpty()) {
                    adapter.updateData(presets)
                    showContent()
                } else {
                    showError()
                }
            }
        }
    }

    private fun showLoading() {
        mBinding?.apply {
            pbLoading.visibility = View.VISIBLE
            rvOfficialAgents.visibility = View.GONE
            llError.visibility = View.GONE
        }

    }

    private fun showContent() {
        mBinding?.apply {
            pbLoading.visibility = View.GONE
            rvOfficialAgents.visibility = View.VISIBLE
            llError.visibility = View.GONE
        }
    }

    private fun showError() {
        mBinding?.apply {
            pbLoading.visibility = View.GONE
            rvOfficialAgents.visibility = View.GONE
            llError.visibility = View.VISIBLE
        }
    }

    private fun onPresetSelected(preset: CovAgentPreset) {
        CovAgentManager.setPreset(preset)
        CovLogger.d("OfficialAgentFragment", "Selected preset: ${preset.name}")
        context?.let {
            it.startActivity(Intent(it, CovLivingActivity::class.java))
        }
    }

    inner class OfficialAgentAdapter(
        private val onItemClick: (CovAgentPreset) -> Unit
    ) : RecyclerView.Adapter<OfficialAgentAdapter.OfficialAgentViewHolder>() {

        private var presets: List<CovAgentPreset> = emptyList()

        fun updateData(newPresets: List<CovAgentPreset>) {
            presets = newPresets
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): OfficialAgentViewHolder {
            return OfficialAgentViewHolder(
                CovItemOfficialAgentBinding.inflate(
                    LayoutInflater.from(parent.context),
                    parent,
                    false
                )
            )
        }

        override fun onBindViewHolder(holder: OfficialAgentViewHolder, position: Int) {
            holder.bind(presets[position])
        }

        override fun getItemCount(): Int = presets.size

        inner class OfficialAgentViewHolder(private val binding: CovItemOfficialAgentBinding) : RecyclerView.ViewHolder
            (binding.root) {

            fun bind(preset: CovAgentPreset) {
                binding.apply {
                    tvTitle.text = preset.display_name
                    tvDescription.text = preset.display_name
                    // For now, using default avatar
                    GlideImageLoader.load(
                        ivAvatar,
                        "xxx",
                        io.agora.scene.common.R.drawable.common_default_agent,
                        io.agora.scene.common.R.drawable.common_default_agent
                    )
                    rootView.setOnClickListener {
                        val position = adapterPosition
                        if (position != RecyclerView.NO_POSITION) {
                            onItemClick(presets[position])
                        }
                    }
                }
            }
        }
    }
} 