package io.agora.scene.convoai.ui.fragment

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.core.view.isVisible
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.common.ui.BaseFragment
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.api.CovAgentPreset
import io.agora.scene.convoai.databinding.CovFragmentCustomAgentBinding

class CustomAgentFragment : BaseFragment<CovFragmentCustomAgentBinding>() {

    private lateinit var adapter: CustomAgentAdapter

    // Mock data for demonstration - replace with actual data source
    private val mockCustomPresets = listOf<CovAgentPreset>()

    override fun getViewBinding(inflater: LayoutInflater, container: ViewGroup?): CovFragmentCustomAgentBinding? {
        return CovFragmentCustomAgentBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        initViews()
        setupAdapter()
        loadCustomPresets()
    }

    private fun initViews() {
        mBinding?.apply {
            btnGetAgent.setOnClickListener {
                onGetAgentClicked()
            }
        }
    }

    private fun setupAdapter() {
        adapter = CustomAgentAdapter { preset ->
            onPresetSelected(preset)
        }
        mBinding?.apply {
            rvCustomAgents.adapter = adapter
        }
    }

    private fun loadCustomPresets() {
        showLoading()

        // For now, using mock data
        // TODO: Replace with actual custom presets API call
        if (mockCustomPresets.isNotEmpty()) {
            adapter.updateData(mockCustomPresets)
            showContent()
        } else {
            showEmptyState()
        }
    }

    private fun showLoading() {
        mBinding?.apply {
            pbLoading.visibility = View.VISIBLE
            rvCustomAgents.visibility = View.GONE
            llEmptyState.visibility = View.GONE
            // Keep bottom action always visible
            llBottomAction.visibility = View.VISIBLE
        }
    }

    private fun showContent() {
        mBinding?.apply {
            pbLoading.visibility = View.GONE
            rvCustomAgents.visibility = View.VISIBLE
            llEmptyState.visibility = View.GONE
            // Bottom action is always visible
            llBottomAction.visibility = View.VISIBLE
        }
    }

    private fun showEmptyState() {
        mBinding?.apply {
            pbLoading.visibility = View.GONE
            rvCustomAgents.visibility = View.GONE
            llEmptyState.visibility = View.VISIBLE
            // Bottom action is always visible
            llBottomAction.visibility = View.VISIBLE
        }
    }

    private fun onPresetSelected(preset: CovAgentPreset) {
        CovLogger.d("CustomAgentFragment", "Selected custom preset: ${preset.name}")
        // TODO: Handle custom preset selection
        // You can add navigation logic here or communicate with parent activity
    }

    private fun onGetAgentClicked() {
        CovLogger.d("CustomAgentFragment", "Get agent button clicked")
        // TODO: Implement get agent functionality
        // This could open a dialog to input agent ID or navigate to another screen
    }
    
    /**
     * Set bottom action visibility based on header state
     * @param visible true to show bottom action, false to hide
     * Note: Bottom action is now always visible, this method is kept for compatibility
     */
    fun setBottomActionVisibility(visible: Boolean) {
        mBinding?.apply {
            // Bottom action is now always visible at the bottom of the fragment
            // llBottomAction is always visible via layout constraints
            // viewBottomSpace provides consistent spacing regardless of header state
            
            // Cancel any ongoing animation to prevent conflicts
            viewBottomSpace.animate().cancel()
            
            // Keep bottom space visible to maintain consistent layout
            viewBottomSpace.isVisible =visible
            viewBottomSpace.alpha = 1f
            viewBottomSpace.translationY = 0f
        }
    }

    inner class CustomAgentAdapter(
        private val onItemClick: (CovAgentPreset) -> Unit
    ) : RecyclerView.Adapter<CustomAgentAdapter.ViewHolder>() {

        private var presets: List<CovAgentPreset> = emptyList()

        fun updateData(newPresets: List<CovAgentPreset>) {
            presets = newPresets
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.cov_item_official_agent, parent, false)
            return ViewHolder(view)
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            holder.bind(presets[position])
        }

        override fun getItemCount(): Int = presets.size

        inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
            private val ivAvatar: ImageView = itemView.findViewById(R.id.ivAvatar)
            private val tvTitle: TextView = itemView.findViewById(R.id.tvTitle)
            private val tvDescription: TextView = itemView.findViewById(R.id.tvDescription)

            init {
                itemView.setOnClickListener {
                    val position = adapterPosition
                    if (position != RecyclerView.NO_POSITION) {
                        onItemClick(presets[position])
                    }
                }
            }

            fun bind(preset: CovAgentPreset) {
                tvTitle.text = preset.name
                tvDescription.text = preset.display_name

                // TODO: Load avatar image when available
                // For now, using default avatar
                ivAvatar.setImageResource(R.drawable.cov_default_avatar)
            }
        }
    }
} 