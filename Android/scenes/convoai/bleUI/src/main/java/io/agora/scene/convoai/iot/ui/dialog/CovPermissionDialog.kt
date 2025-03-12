package io.agora.scene.convoai.iot.ui.dialog

import android.content.DialogInterface
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.convoai.iot.databinding.CovPermissionDialogBinding

class CovPermissionDialog : BaseSheetDialog<CovPermissionDialogBinding>() {

    private var onDismissCallback: (() -> Unit)? = null
    private var onLocationPermissionClick: (() -> Unit)? = null
    private var onBluetoothPermissionClick: (() -> Unit)? = null
    private var onBluetoothSwitchClick: (() -> Unit)? = null
    private var onWifiPermissionClick: (() -> Unit)? = null
    
    // Permission states
    private var locationPermissionGranted = false
    private var bluetoothPermissionGranted = false
    private var bluetoothSwitchNeedOpen = false
    private var wifiPermissionGranted = false
    
    // Permission display configuration
    private var showLocationPermission = true
    private var showBluetoothPermission = true
    private var showWifiPermission = false

    companion object {
        private const val TAG = "CovPermissionDialog"

        fun newInstance(
            onDismiss: () -> Unit,
            onLocationPermission: (() -> Unit)? = null,
            onBluetoothPermission: (() -> Unit)? = null,
            onWifiPermission: (() -> Unit)? = null,
            onBluetoothSwitch: (() -> Unit)? = null,
            showLocation: Boolean = true,
            showBluetoothPermission: Boolean = true,
            showWifi: Boolean = false
        ): CovPermissionDialog {
            return CovPermissionDialog().apply {
                this.onDismissCallback = onDismiss
                this.onLocationPermissionClick = onLocationPermission
                this.onBluetoothPermissionClick = onBluetoothPermission
                this.onBluetoothSwitchClick = onBluetoothSwitch
                this.onWifiPermissionClick = onWifiPermission
                this.showLocationPermission = showLocation
                this.showBluetoothPermission = showBluetoothPermission
                this.showWifiPermission = showWifi
            }
        }
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        onDismissCallback?.invoke()
    }

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovPermissionDialogBinding {
        return CovPermissionDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding?.apply {
            setOnApplyWindowInsets(root)
            
            // Set close button click event
            btnClose.setOnClickListener {
                dismiss()
            }
            
            // Set location service permission button click event
            btnLocationPermission.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onLocationPermissionClick?.invoke()
                    dismiss()
                }
            })
            
            // Set bluetooth permission button click event
            btnBluetoothPermission.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onBluetoothPermissionClick?.invoke()
                    dismiss()
                }
            })

            // Set bluetooth switch button click event
            btnBluetoothSwitch.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onBluetoothSwitchClick?.invoke()
                    dismiss()
                }
            })
            
            // Set Wi-Fi permission button click event
            btnWifiPermission.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onWifiPermissionClick?.invoke()
                    dismiss()
                }
            })
            
            // Show or hide permission items based on configuration
            cvLocationPermission.visibility = if (showLocationPermission) View.VISIBLE else View.GONE
            cvBluetoothPermission.visibility = if (showBluetoothPermission) View.VISIBLE else View.GONE
            cvWifiPermission.visibility = if (showWifiPermission) View.VISIBLE else View.GONE
            cvBluetoothSwitch.visibility = if (bluetoothSwitchNeedOpen) View.VISIBLE else View.GONE
        }
        
        updatePermissionStatus()
    }

    override fun disableDragging(): Boolean {
        return true
    }
    
    /**
     * Update location permission status
     * @param granted Whether permission is granted
     */
    fun updateLocationPermissionStatus(granted: Boolean) {
        locationPermissionGranted = granted
        updatePermissionStatus()
    }
    
    /**
     * Update bluetooth permission status
     * @param granted Whether permission is granted
     */
    fun updateBluetoothPermissionStatus(granted: Boolean) {
        bluetoothPermissionGranted = granted
        updatePermissionStatus()
    }
    
    /**
     * Update Wi-Fi permission status
     * @param granted Whether permission is granted
     */
    fun updateWifiPermissionStatus(granted: Boolean) {
        wifiPermissionGranted = granted
        updatePermissionStatus()
    }

    fun showBluetoothSwitch() {
        bluetoothSwitchNeedOpen = true
        updatePermissionStatus()
    }
    
    /**
     * Update permission status UI
     */
    private fun updatePermissionStatus() {
        binding?.apply {
            // Update location service permission status
            if (showLocationPermission) {
                if (locationPermissionGranted) {
                    cvLocationPermission.visibility = View.GONE
                } else {
                    cvLocationPermission.visibility = View.VISIBLE
                    btnLocationPermission.isEnabled = true
                }
            }
            
            // Update bluetooth permission status
            if (showBluetoothPermission) {
                if (bluetoothPermissionGranted) {
                    cvBluetoothPermission.visibility = View.GONE
                } else {
                    cvBluetoothPermission.visibility = View.VISIBLE
                    btnBluetoothPermission.isEnabled = true
                }
            }
            
            // Update Wi-Fi permission status
            if (showWifiPermission) {
                if (wifiPermissionGranted) {
                    cvWifiPermission.visibility = View.GONE
                } else {
                    cvWifiPermission.visibility = View.VISIBLE
                    btnWifiPermission.isEnabled = true
                }
            }

            // Check if all displayed permissions are granted, if so automatically close the dialog
            val allGranted = (!showLocationPermission || locationPermissionGranted) && 
                             (!showBluetoothPermission || bluetoothPermissionGranted) &&
                             (!showWifiPermission || wifiPermissionGranted) &&
                             (!bluetoothSwitchNeedOpen)
            if (allGranted) {
                dismiss()
            }
        }
    }
} 