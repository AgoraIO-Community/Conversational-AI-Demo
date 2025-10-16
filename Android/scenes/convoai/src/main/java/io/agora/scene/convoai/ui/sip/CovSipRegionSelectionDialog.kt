package io.agora.scene.convoai.ui.sip

import android.graphics.Canvas
import android.os.Bundle
import android.text.Editable
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import androidx.core.widget.doAfterTextChanged
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.common.R
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.convoai.api.CovSipCallee
import io.agora.scene.convoai.databinding.CovDialogRegionSelectionBinding
import io.agora.scene.convoai.databinding.CovItemRegionSelectionBinding
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class CovSipRegionSelectionDialog : BaseSheetDialog<CovDialogRegionSelectionBinding>() {

    companion object {
        private const val TAG = "CovSipRegionSelectionDialog"
        private const val SEARCH_DELAY = 300L // Delay for search debouncing

        fun newInstance(
            data: List<CovSipCallee>? = null,
            onDismiss: (() -> Unit)? = null,
            onRegionSelected: ((RegionInfo) -> Unit)? = null
        ): CovSipRegionSelectionDialog {
            return CovSipRegionSelectionDialog().apply {
                this.regions = data?.toList() ?: emptyList()
                this.onDismissCallback = onDismiss
                this.onRegionSelectedCallback = onRegionSelected
            }
        }
    }

    private var onDismissCallback: (() -> Unit)? = null
    private var onRegionSelectedCallback: ((RegionInfo) -> Unit)? = null
    private val regionAdapter = RegionAdapter()
    private var searchJob: Job? = null
    private val scope = MainScope()

    override fun getViewBinding(
        inflater: LayoutInflater, container: ViewGroup?
    ): CovDialogRegionSelectionBinding {
        return CovDialogRegionSelectionBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding?.apply {
            setOnApplyWindowInsets(root)
        }
        initData()
        initViews()
    }

    override fun onStart() {
        super.onStart()
        // Set peek height to 2/3 of screen height for BottomSheetDialog
        dialog?.let { dialog ->
            val bottomSheet = dialog.findViewById<View>(com.google.android.material.R.id.design_bottom_sheet)
            val behavior = com.google.android.material.bottomsheet.BottomSheetBehavior.from(bottomSheet)

            val displayMetrics = resources.displayMetrics
            val screenHeight = displayMetrics.heightPixels
            val peekHeight = (screenHeight * 0.9).toInt()

            // Set the height to allow content scrolling
            bottomSheet.layoutParams.height = peekHeight

            behavior.peekHeight = peekHeight
            behavior.state = com.google.android.material.bottomsheet.BottomSheetBehavior.STATE_EXPANDED
            behavior.isDraggable = false
        }
    }


    private var regions: List<CovSipCallee> = emptyList()

    private fun initData() {
        // Initialize adapter with data
        val list = regions.map { config ->
            RegionInfo(
                flag = config.flag_emoji,
                name = config.region_name,
                displayName = config.region_full_name,
                code = config.region_code
            )
        }
        regionAdapter.setData(list)
    }

    private fun initViews() {
        binding?.apply {
            // Initialize visibility
            rvRegions.isVisible = true
            llEmptyState.isVisible = false

            // Setup click listeners
            btnClose.setOnClickListener {
                onDismissCallback?.invoke()
                dismiss()
            }
            ivClearInput.setOnClickListener { clearSearch() }

            // Setup search input listener
            etSearch.apply {
                doAfterTextChanged { text: Editable? ->
                    handleSearchTextChange(text)
                }
                setOnEditorActionListener { _, actionId, _ ->
                    if (actionId == android.view.inputmethod.EditorInfo.IME_ACTION_SEARCH) {
                        performSearch()
                        true
                    } else {
                        false
                    }
                }
            }

            // Setup recycler view
            rvRegions.apply {
                adapter = regionAdapter
                addItemDecoration(object : RecyclerView.ItemDecoration() {
                    override fun onDraw(c: Canvas, parent: RecyclerView, state: RecyclerView.State) {
                        val childCount = parent.childCount
                        ContextCompat.getDrawable(context, R.drawable.shape_divider_line)?.let { divider ->
                            for (i in 0 until childCount - 1) {
                                val child = parent.getChildAt(i)
                                val params = child.layoutParams as RecyclerView.LayoutParams

                                val top = child.bottom + params.bottomMargin
                                val bottom = top + divider.intrinsicHeight

                                divider.setBounds(child.paddingLeft, top, parent.width - child.paddingRight, bottom)
                                divider.draw(c)
                            }
                        }
                    }
                })
            }
        }
    }

    private fun handleSearchTextChange(text: Editable?) {
        binding?.apply {
            val query = text?.toString() ?: ""
            ivClearInput.isVisible = query.isNotEmpty()

            // Cancel previous search job
            searchJob?.cancel()

            // Create new search job
            searchJob = scope.launch {
                delay(SEARCH_DELAY)
                regionAdapter.filter(query)
            }
        }
    }

    private fun clearSearch() {
        binding?.apply {
            etSearch.setText("")
            ivClearInput.isVisible = false
            regionAdapter.filter("")
        }
    }

    private fun performSearch() {
        binding?.apply {
            val query = etSearch.text?.toString() ?: ""
            regionAdapter.filter(query)
        }
    }

    override fun dismiss() {
        super.dismiss()
        onDismissCallback?.invoke()
    }


    private inner class RegionAdapter : RecyclerView.Adapter<RegionViewHolder>() {
        private var regions = emptyList<RegionInfo>()
        private var filteredIndices = mutableListOf<Int>()
        private var searchQuery = ""

        fun setData(newRegions: List<RegionInfo>) {
            regions = newRegions
            filteredIndices.clear()
            filteredIndices.addAll(regions.indices)
            notifyDataSetChanged()
        }

        fun filter(query: String) {
            searchQuery = query // Keep original query for highlighting
            filteredIndices.clear()

            if (query.isEmpty()) {
                filteredIndices.addAll(regions.indices)
            } else {
                // Convert to lowercase only for comparison
                val lowercaseQuery = query.lowercase()
                regions.forEachIndexed { index, region ->
                    if (region.displayName.lowercase().contains(lowercaseQuery) ||
                        region.name.lowercase().contains(lowercaseQuery) ||
                        region.code.contains(lowercaseQuery) // Keep original case for dial code
                    ) {
                        filteredIndices.add(index)
                    }
                }
            }
            notifyDataSetChanged()

            // Update empty state visibility based on search results
            binding?.apply {
                val isEmpty = filteredIndices.isEmpty() && query.isNotEmpty()
                llEmptyState.isVisible = isEmpty
                rvRegions.isVisible = !isEmpty
            }
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RegionViewHolder {
            val binding = CovItemRegionSelectionBinding.inflate(
                LayoutInflater.from(parent.context), parent, false
            )
            return RegionViewHolder(binding)
        }

        override fun getItemCount() = filteredIndices.size

        override fun onBindViewHolder(holder: RegionViewHolder, position: Int) {
            val region = regions[filteredIndices[position]]
            holder.bind(region, searchQuery)
        }
    }

    private inner class RegionViewHolder(
        private val binding: CovItemRegionSelectionBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(region: RegionInfo, searchQuery: String) {
            binding.apply {
                tvCountryFlag.text = region.flag
                tvCountryName.text = region.getHighlightedDisplayName(searchQuery)
                tvCountryCode.text = region.getHighlightedCode(searchQuery)
                root.setOnClickListener {
                    onRegionSelectedCallback?.invoke(region)
                    dismiss()
                }
            }
        }
    }

    data class RegionInfo(
        val flag: String,
        val name: String,
        val displayName: String,
        val code: String,
    ) {
        fun getHighlightedDisplayName(query: String): CharSequence {
            if (query.isEmpty()) return displayName

            // Find the actual matching part to preserve its case
            val matchStart = displayName.lowercase().indexOf(query.lowercase())
            if (matchStart == -1) return displayName

            val matchingPart = displayName.substring(matchStart, matchStart + query.length)
            return displayName.replace(
                matchingPart,
                "<font color='#165DFF'>$matchingPart</font>"
            ).let { android.text.Html.fromHtml(it, android.text.Html.FROM_HTML_MODE_COMPACT) }
        }

        fun getHighlightedCode(query: String): CharSequence {
            if (query.isEmpty()) return code

            // For dial code, we want exact match
            val matchStart = code.indexOf(query)
            if (matchStart == -1) return code

            val matchingPart = code.substring(matchStart, matchStart + query.length)
            return code.replace(
                matchingPart,
                "<font color='#165DFF'>$matchingPart</font>"
            ).let { android.text.Html.fromHtml(it, android.text.Html.FROM_HTML_MODE_COMPACT) }
        }
    }
}