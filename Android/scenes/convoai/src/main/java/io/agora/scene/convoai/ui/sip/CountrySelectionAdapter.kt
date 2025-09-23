package io.agora.scene.convoai.ui.sip

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.convoai.databinding.CovCountryItemBinding

/**
 * Adapter for country selection in popup
 */
class CountrySelectionAdapter(
    private var countries: List<CountryConfig>,
    private val onCountrySelected: (CountryConfig) -> Unit
) : RecyclerView.Adapter<CountrySelectionAdapter.CountryViewHolder>() {

    private var selectedPosition = 0

    inner class CountryViewHolder(private val binding: CovCountryItemBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(country: CountryConfig) {
            val isSelected = adapterPosition == selectedPosition

            binding.apply {
                tvCountryFlag.text = country.flagEmoji
                tvCountryName.text = country.countryCode
                tvCountryCode.text = country.dialCode

                // Update selection state visual
                ivSelected.visibility = if (isSelected) View.VISIBLE else View.INVISIBLE

                itemView.setOnClickListener {
                    if (selectedPosition != adapterPosition) {
                        val oldPosition = selectedPosition
                        selectedPosition = adapterPosition

                        // Update UI for both old and new selection
                        notifyItemChanged(oldPosition)
                        notifyItemChanged(selectedPosition)

                        // Notify callback
                        onCountrySelected(country)
                    }
                }
            }
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CountryViewHolder {
        return CountryViewHolder(
            CovCountryItemBinding.inflate(
                LayoutInflater.from(parent.context),
                parent,
                false
            )
        )
    }

    override fun onBindViewHolder(holder: CountryViewHolder, position: Int) {
        holder.bind(countries[position])
    }

    override fun getItemCount(): Int = countries.size

    /**
     * Update selected country by dial code
     */
    fun updateSelection(dialCode: String) {
        val newPosition = countries.indexOfFirst { it.dialCode == dialCode }
        if (newPosition != -1 && newPosition != selectedPosition) {
            val oldPosition = selectedPosition
            selectedPosition = newPosition
            notifyItemChanged(oldPosition)
            notifyItemChanged(selectedPosition)
        }
    }

    /**
     * Get currently selected country
     */
    fun getSelectedCountry(): CountryConfig? {
        return countries.getOrNull(selectedPosition)
    }
    
    /**
     * Update countries list and reset selection
     */
    fun updateCountries(newCountries: List<CountryConfig>) {
        countries = newCountries
        selectedPosition = 0 // Reset to first item
        notifyDataSetChanged()
    }
}
