package io.agora.scene.convoai.ui.fragment

import android.content.Intent
import android.os.Bundle
import android.text.InputFilter
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import androidx.activity.viewModels
import androidx.core.view.isVisible
import androidx.core.widget.doAfterTextChanged
import androidx.fragment.app.activityViewModels
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.common.ui.BaseFragment
import io.agora.scene.common.util.GlideImageLoader
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.api.CovAgentPreset
import io.agora.scene.convoai.constant.CovAgentManager
import io.agora.scene.convoai.databinding.CovFragmentCustomAgentBinding
import io.agora.scene.convoai.databinding.CovItemOfficialAgentBinding
import io.agora.scene.convoai.ui.CovLivingActivity
import io.agora.scene.convoai.ui.vm.CovListViewModel

class CovCustomAgentFragment : BaseFragment<CovFragmentCustomAgentBinding>() {

    companion object{
        private const val TAG = "CovCustomAgentFragment"
    }

    private lateinit var adapter: CustomAgentAdapter
    private val viewModel: CovListViewModel by activityViewModels()

    // Keyboard handling
    private var isKeyboardVisible = false
    private var isHeaderCollapsed = false
    private val globalLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
        handleKeyboardVisibility()
    }

    override fun getViewBinding(inflater: LayoutInflater, container: ViewGroup?): CovFragmentCustomAgentBinding? {
        return CovFragmentCustomAgentBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        initViews()
        setupAdapter()
        observeViewModel()
        setupKeyboardListener()
    }

    private fun initViews() {
        mBinding?.apply {
            // Setup button click listener
            btnGetAgent.setOnClickListener {
                onGetAgentClicked()
            }

            // Setup EditText for agent ID input
            setupAgentIdInput()
        }
    }

    private fun setupAgentIdInput() {
        mBinding?.apply {
            // Set input filter to allow only digits
            val digitFilter = InputFilter { source, start, end, dest, dstart, dend ->
                for (i in start until end) {
                    if (!Character.isDigit(source[i])) {
                        return@InputFilter ""
                    }
                }
                null
            }

            // Apply input filters: digits only + max length 8
            etAgentId.filters = arrayOf(digitFilter, InputFilter.LengthFilter(8))

            // Add text watcher to update character count
            etAgentId.doAfterTextChanged {
                val currentLength = it?.length ?: 0
                val remainingLength = 8 - currentLength
                tvCount.text = remainingLength.toString()
            }

            // Initialize character count display (show remaining characters)
            tvCount.text = "8"
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

    private fun observeViewModel() {
        // Observe data changes
        viewModel.customAgents.observe(viewLifecycleOwner) { presets ->
            adapter.updateData(presets)
        }

        // Observe state changes
        viewModel.customState.observe(viewLifecycleOwner) { state ->
            when (state) {
                is CovListViewModel.AgentListState.Loading -> {
                    showLoading()
                }
                is CovListViewModel.AgentListState.Success -> {
                    showContent()
                }
                is CovListViewModel.AgentListState.Error -> {
                    // Handle error if needed
                    CovLogger.e(TAG, "Custom agents error: ${state.message}")
                    showEmptyState()
                }
                is CovListViewModel.AgentListState.Empty -> {
                    showEmptyState()
                }
            }
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
        CovLogger.d(TAG, "Selected custom preset: ${preset.name}")
        CovAgentManager.setPreset(preset)
        CovLogger.d(TAG, "Selected preset: ${preset.name}")
        context?.let {
            it.startActivity(Intent(it, CovLivingActivity::class.java))
        }
    }

    private fun onGetAgentClicked() {
        CovLogger.d(TAG, "Get agent button clicked")
        mBinding?.apply {
            val agentId = etAgentId.text.toString()
            if (agentId.isEmpty()) {
                ToastUtil.show(R.string.cov_custom_agent_input_tip)
            } else {
                // Load custom agent by ID
                viewModel.loadCustomAgents(agentId)
                ToastUtil.show("Loading agent: $agentId")
            }
        }
    }

    private fun setupKeyboardListener() {
        view?.viewTreeObserver?.addOnGlobalLayoutListener(globalLayoutListener)
    }

    private fun handleKeyboardVisibility() {
        val rootView = view ?: return
        val rect = android.graphics.Rect()
        rootView.getWindowVisibleDisplayFrame(rect)

        val screenHeight = rootView.context.resources.displayMetrics.heightPixels
        val isKeyboardNowVisible = (screenHeight - rect.bottom) > screenHeight * 0.15

        if (isKeyboardNowVisible != isKeyboardVisible) {
            isKeyboardVisible = isKeyboardNowVisible

            mBinding?.apply {
                if (isKeyboardVisible) {
                    val location = IntArray(2)
                    llBottomAction.getLocationInWindow(location)

                    val effectiveBottom = if (isHeaderCollapsed) {
                        location[1] + llBottomAction.height
                    } else {
                        val bottomSpaceHeight = if (viewBottomSpace.isVisible) viewBottomSpace.height else 0
                        location[1] + llBottomAction.height - bottomSpaceHeight
                    }

                    val overlap = effectiveBottom - rect.bottom
                    llBottomAction.translationY = if (overlap > 0) -overlap.toFloat() else 0f
                } else {
                    llBottomAction.translationY = 0f
                }
            }
        }
    }

    override fun onDestroyView() {
        view?.viewTreeObserver?.removeOnGlobalLayoutListener(globalLayoutListener)
        super.onDestroyView()
    }

    fun setBottomActionVisibility(visible: Boolean) {
        isHeaderCollapsed = !visible

        mBinding?.apply {
            viewBottomSpace.isVisible = !isHeaderCollapsed
            if (!isHeaderCollapsed) {
                viewBottomSpace.alpha = 1f
                viewBottomSpace.translationY = 0f
            }

            if (isKeyboardVisible) {
                handleKeyboardVisibility()
            }
        }
    }

    inner class CustomAgentAdapter(
        private val onItemClick: (CovAgentPreset) -> Unit
    ) : RecyclerView.Adapter<CustomAgentAdapter.CustomAgentViewHolder>() {

        private var presets: List<CovAgentPreset> = emptyList()

        fun updateData(newPresets: List<CovAgentPreset>) {
            presets = newPresets
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CustomAgentViewHolder {
            return CustomAgentViewHolder(
                CovItemOfficialAgentBinding.inflate(
                    LayoutInflater.from(parent.context),
                    parent,
                    false
                )
            )
        }

        override fun onBindViewHolder(holder: CustomAgentViewHolder, position: Int) {
            holder.bind(presets[position])
        }

        override fun getItemCount(): Int = presets.size

        inner class CustomAgentViewHolder(private val binding: CovItemOfficialAgentBinding) : RecyclerView.ViewHolder
            (binding.root) {

            fun bind(preset: CovAgentPreset) {
                binding.apply {
                    tvTitle.text = preset.display_name
                    tvDescription.text = preset.description
                    // For now, using default avatar
                    GlideImageLoader.load(
                        ivAvatar,
                        preset.avatar_url,
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