package io.agora.scene.convoai.iot.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.convoai.iot.databinding.CovItemDeviceBinding
import io.iot.dn.ble.model.BleDevice

class CovIotDeviceScanListAdapter(
    private val devices: List<BleDevice>,
    private val onItemClick: (BleDevice) -> Unit
) : RecyclerView.Adapter<CovIotDeviceScanListAdapter.DeviceViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DeviceViewHolder {
        val binding = CovItemDeviceBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return DeviceViewHolder(binding)
    }

    override fun onBindViewHolder(holder: DeviceViewHolder, position: Int) {
        val device = devices[position]
        holder.bind(device)
    }

    override fun getItemCount(): Int = devices.size

    inner class DeviceViewHolder(private val binding: CovItemDeviceBinding) :
        RecyclerView.ViewHolder(binding.root) {

        init {
            binding.root.setOnTouchListener { view, event ->
                when (event.action) {
                    android.view.MotionEvent.ACTION_DOWN -> {
                        binding.root.setCardBackgroundColor(ContextCompat.getColor(binding.root.context, io.agora.scene.common.R.color.ai_click_app))
                    }
                    android.view.MotionEvent.ACTION_UP, android.view.MotionEvent.ACTION_CANCEL -> {
                        binding.root.setCardBackgroundColor(ContextCompat.getColor(binding.root.context, io.agora.scene.common.R.color.ai_fill1))
                        
                        if (event.action == android.view.MotionEvent.ACTION_UP) {
                            val position = adapterPosition
                            if (position != RecyclerView.NO_POSITION) {
                                onItemClick(devices[position])
                            }
                        }
                    }
                }
                true
            }
        }

        fun bind(device: BleDevice) {
            binding.apply {
                tvDeviceName.text = device.name
            }
        }
    }
} 