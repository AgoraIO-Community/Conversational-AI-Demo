package io.agora.scene.convoai.iot.adapter

import android.app.AlertDialog
import android.text.InputFilter
import android.text.InputType
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.EditText
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.convoai.iot.R
import io.agora.scene.convoai.iot.databinding.CovIotDeviceItemBinding
import io.agora.scene.convoai.iot.model.CovIotDevice
import io.agora.scene.convoai.iot.ui.dialog.CovEditNameDialog

class CovIotDeviceListAdapter(private val devices: List<CovIotDevice>) :
    RecyclerView.Adapter<CovIotDeviceListAdapter.DeviceViewHolder>() {
    
    private var listener: OnItemClickListener? = null
    
    interface OnItemClickListener {
        fun onItemSettingClick(device: CovIotDevice, position: Int)
        fun onNameChanged(device: CovIotDevice, newName: String, position: Int)
    }
    
    fun setOnItemClickListener(listener: OnItemClickListener) {
        this.listener = listener
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DeviceViewHolder {
        val binding = CovIotDeviceItemBinding.inflate(
            LayoutInflater.from(parent.context), 
            parent, 
            false
        )
        val backgroundResId = if (viewType == 0) {
            R.drawable.cov_iot_device_item_bg
        } else {
            R.drawable.cov_iot_device_item_bg_2
        }
        binding.clIotItem.setBackgroundResource(backgroundResId)
        
        return DeviceViewHolder(binding)
    }
    
    override fun onBindViewHolder(holder: DeviceViewHolder, position: Int) {
        val device = devices[position]
        holder.bind(device)
    }
    
    override fun getItemCount(): Int = devices.size
    
    override fun getItemViewType(position: Int): Int {
        return position % 2
    }
    
    inner class DeviceViewHolder(private val binding: CovIotDeviceItemBinding) : 
        RecyclerView.ViewHolder(binding.root) {
        
        fun bind(device: CovIotDevice) {
            binding.apply {
                tvDeviceName.text = device.name
                
                tvDeviceName.setOnClickListener {
                    showEditNameDialog(device, adapterPosition)
                }

                tvSerialNumber.text = device.id

                cvDeviceSettings.setOnClickListener {
                    listener?.onItemSettingClick(device, adapterPosition)
                }
            }
        }
        
        private fun showEditNameDialog(device: CovIotDevice, position: Int) {
            val context = itemView.context
            
            CovEditNameDialog.show(
                context = context,
                initialName = device.name
            ) { newName ->
                if (newName.isNotEmpty() && newName != device.name) {
                    listener?.onNameChanged(device, newName, position)
                }
            }
        }
    }
}