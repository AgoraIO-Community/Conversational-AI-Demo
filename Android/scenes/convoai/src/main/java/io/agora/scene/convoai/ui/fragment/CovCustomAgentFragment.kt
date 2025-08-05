package io.agora.scene.convoai.ui.fragment

import android.os.Bundle
import android.text.InputFilter
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.ImageView
import android.widget.TextView
import androidx.core.view.isVisible
import androidx.core.widget.doAfterTextChanged
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.common.ui.BaseFragment
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.api.CovAgentPreset
import io.agora.scene.convoai.databinding.CovFragmentCustomAgentBinding

class CovCustomAgentFragment : BaseFragment<CovFragmentCustomAgentBinding>() {

    private lateinit var adapter: CustomAgentAdapter

    // Mock data for demonstration - replace with actual data source
    private val mockCustomPresets = listOf<CovAgentPreset>()

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
        loadCustomPresets()
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
        mBinding?.apply {
            if (etAgentId.text.toString().isEmpty()) {
                ToastUtil.show(R.string.cov_custom_agent_input_tip)
            } else {
                ToastUtil.show("Get agent ID: ${etAgentId.text}")
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