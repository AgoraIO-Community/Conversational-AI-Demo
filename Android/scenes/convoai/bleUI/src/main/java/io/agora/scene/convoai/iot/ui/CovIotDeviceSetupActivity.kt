package io.agora.scene.convoai.iot.ui

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.provider.Settings
import android.view.LayoutInflater
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.widget.ViewPager2
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getStatusBarHeight
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.iot.CovLogger
import io.agora.scene.convoai.iot.R
import io.agora.scene.convoai.iot.databinding.CovActivityIotDeviceSetupBinding
import io.agora.scene.convoai.iot.ui.dialog.CovPermissionDialog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

data class DeviceImage(
    val resourceId: Int,
    val description: String
)

class CovIotDeviceSetupActivity : BaseActivity<CovActivityIotDeviceSetupBinding>() {

    companion object {
        private const val TAG = "CovIotDeviceSetupActivity"
        private const val MAX_PERMISSION_REQUEST_COUNT = 1

        fun startActivity(activity: BaseActivity<*>) {
            val intent = Intent(activity, CovIotDeviceSetupActivity::class.java)
            activity.startActivity(intent)
        }
    }
    
    // Create coroutine scope for asynchronous operations
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // Device image adapter
    private lateinit var deviceImageAdapter: CovIotSetupImageAdapter
    
    // Device image list
    private val deviceImages = mutableListOf<DeviceImage>()
    
    // Bluetooth adapter
    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothManager.adapter
    }
    
    // Permission dialog
    private var permissionDialog: CovPermissionDialog? = null
    
    // Permission request counter
    private var locationPermissionRequestCount = 0
    private var bluetoothPermissionRequestCount = 0
    
    // Location service check launcher
    private val locationSettingsLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        // After returning from location settings page, recheck location service
        checkLocationEnabledAfterSettings()
    }
    
    // Permission request callback
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        var locationPermissionGranted = true
        var bluetoothPermissionGranted = true
        
        // Check location permission result
        if (permissions.containsKey(Manifest.permission.ACCESS_FINE_LOCATION)) {
            locationPermissionGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] == true
            if (locationPermissionGranted) {
                locationPermissionRequestCount = 0
            } else {
                locationPermissionRequestCount++
            }
        }
        
        // Check bluetooth permission result (Android 12 and above)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (permissions.containsKey(Manifest.permission.BLUETOOTH_SCAN)) {
                bluetoothPermissionGranted = bluetoothPermissionGranted && 
                    permissions[Manifest.permission.BLUETOOTH_SCAN] == true
            }
            if (permissions.containsKey(Manifest.permission.BLUETOOTH_CONNECT)) {
                bluetoothPermissionGranted = bluetoothPermissionGranted && 
                    permissions[Manifest.permission.BLUETOOTH_CONNECT] == true
            }
            
            if (!bluetoothPermissionGranted) {
                bluetoothPermissionRequestCount++
            } else {
                bluetoothPermissionRequestCount = 0
            }
        }
        
        // If any permission is denied, show permission dialog
        if (!locationPermissionGranted || !bluetoothPermissionGranted) {
            showPermissionDialog(locationPermissionGranted, bluetoothPermissionGranted)
        } else {
            // All permissions granted, check if bluetooth is enabled
            checkBluetoothEnabled()
        }
    }
    
    // Bluetooth enable request callback
    private val bluetoothEnableLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            // Bluetooth enabled
            permissionDialog?.updateBluetoothPermissionStatus(true)
            checkLocationEnabled()
        } else {
            // User refused to enable bluetooth
            permissionDialog?.updateBluetoothPermissionStatus(true)
            showPermissionDialog(
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) 
                    == PackageManager.PERMISSION_GRANTED,
                bluetoothGranted = true,
                bluetoothOpen = false
            )
        }
    }

    override fun getViewBinding(): CovActivityIotDeviceSetupBinding {
        return CovActivityIotDeviceSetupBinding.inflate(layoutInflater)
    }

    override fun initView() {
        setupView()
        setupViewPager()
        setupCheckbox()
    }

    override fun onResume() {
        super.onResume()
        // Update UI state when page resumes
        updateUIState()
    }

    override fun onDestroy() {
        // Clean up resources to avoid memory leaks
        dismissPermissionDialog()
        coroutineScope.cancel()
        super.onDestroy()
    }

    private fun setupView() {
        mBinding?.apply {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            val statusBarHeight = getStatusBarHeight() ?: 25.dp.toInt()
            CovLogger.d(TAG, "statusBarHeight $statusBarHeight")
            val layoutParams = clTitleBar.layoutParams as ViewGroup.MarginLayoutParams
            layoutParams.topMargin = statusBarHeight
            clTitleBar.layoutParams = layoutParams

            // Set back button click event
            ivBack.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    finish()
                }
            })
            
            // Set next button click event
            btnNext.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    if (cbConfirm.isChecked) {
                        // Start permission check and bluetooth check process
                        checkAndRequestPermissions()
                    } else {
                        ToastUtil.show("Please confirm you have completed the above operations first")
                    }
                }
            })

            // Initialize button state
            updateNextButtonState(cbConfirm.isChecked)
        }
    }
    
    private fun setupViewPager() {
        // Initialize device image data
        deviceImages.clear()
        deviceImages.add(DeviceImage(R.drawable.cov_iot_prepare_pic_1, "Front view of device"))
        deviceImages.add(DeviceImage(R.drawable.cov_iot_prepare_pic_1, "Back view of device"))
        
        deviceImageAdapter = CovIotSetupImageAdapter(deviceImages)
        
        mBinding?.apply {
            viewpagerDevice.adapter = deviceImageAdapter
            
            // Set ViewPager2 page change listener
            viewpagerDevice.registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
                override fun onPageSelected(position: Int) {
                    super.onPageSelected(position)
                    // Prevent index out of bounds
                    if (position >= 0 && position < deviceImages.size) {
                        updateIndicators(position)
                    }
                }
            })
            
            // Initialize indicator state
            updateIndicators(0)
        }
    }
    
    private fun updateIndicators(position: Int) {
        mBinding?.apply {
            // Update indicator state based on current page position
            indicator1.setBackgroundResource(
                if (position == 0) R.drawable.shape_indicator_selected 
                else R.drawable.shape_indicator_normal
            )
            
            indicator2.setBackgroundResource(
                if (position == 1) R.drawable.shape_indicator_selected 
                else R.drawable.shape_indicator_normal
            )
        }
    }
    
    private fun setupCheckbox() {
        mBinding?.apply {
            cbConfirm.setOnCheckedChangeListener { _, isChecked ->
                // Enable or disable next button based on checkbox state
                updateNextButtonState(isChecked)
            }
        }
    }

    // Update UI state
    private fun updateUIState() {
        mBinding?.apply {
            // Update checkbox and button state
            updateNextButtonState(cbConfirm.isChecked)
        }
    }

    // Check and request necessary permissions
    private fun checkAndRequestPermissions() {
        val permissionsToRequest = mutableListOf<String>()
        
        // Check location permission (required for BLE scanning)
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED) {
            permissionsToRequest.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        
        // Android 12 and above require bluetooth scan and connect permissions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) 
                != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_SCAN)
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) 
                != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_CONNECT)
            }
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            // Request permissions
            requestPermissionLauncher.launch(permissionsToRequest.toTypedArray())
        } else {
            // Already have all permissions, check if bluetooth is enabled
            checkBluetoothEnabled()
        }
    }
    
    // Show permission dialog
    private fun showPermissionDialog(locationGranted: Boolean, bluetoothGranted: Boolean, bluetoothOpen: Boolean? = null) {
        if (permissionDialog == null) {
            permissionDialog = CovPermissionDialog.newInstance(
                onDismiss = {
                    // Dialog dismiss callback
                    permissionDialog = null
                },
                onLocationPermission = {
                    // Location permission click callback
                    if (locationPermissionRequestCount >= MAX_PERMISSION_REQUEST_COUNT) {
                        // User denied multiple times, redirect to app settings
                        openAppSettings()
                    } else {
                        requestLocationPermission()
                    }
                },
                onBluetoothPermission = {
                    // Bluetooth permission click callback
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && 
                        bluetoothPermissionRequestCount >= MAX_PERMISSION_REQUEST_COUNT) {
                        // User denied multiple times, redirect to app settings
                        openAppSettings()
                    } else {
                        requestBluetoothPermission()
                    }
                },
                onBluetoothSwitch = {
                    // Request to enable bluetooth
                    val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                    bluetoothEnableLauncher.launch(enableBtIntent)
                }
            )
        }
        
        permissionDialog?.apply {
            updateLocationPermissionStatus(locationGranted)
            updateBluetoothPermissionStatus(bluetoothGranted)
            if (bluetoothOpen != null) showBluetoothSwitch()
            
            if (!isAdded) {
                show(supportFragmentManager, "permission_dialog")
            }
        }
    }
    
    // Dismiss permission dialog
    private fun dismissPermissionDialog() {
        permissionDialog?.dismiss()
        permissionDialog = null
    }
    
    // Open app settings page
    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = android.net.Uri.parse("package:$packageName")
                addCategory(Intent.CATEGORY_DEFAULT)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            CovLogger.e(TAG, "Unable to open app settings page: ${e.message}")
            ToastUtil.show("Please manually go to settings page to grant permissions")
        }
    }
    
    // Request location permission
    private fun requestLocationPermission() {
        requestPermissionLauncher.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION))
    }
    
    // Request bluetooth permission
    private fun requestBluetoothPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            requestPermissionLauncher.launch(arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT
            ))
        } else {
            // No additional bluetooth permissions needed for Android versions below 12
            permissionDialog?.updateBluetoothPermissionStatus(true)
            checkBluetoothEnabled()
        }
    }
    
    // Check if bluetooth is enabled
    private fun checkBluetoothEnabled() {
        bluetoothAdapter?.let { adapter ->
            if (!adapter.isEnabled) {
                // Bluetooth not enabled, request to enable
                val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                bluetoothEnableLauncher.launch(enableBtIntent)
            } else {
                // Bluetooth enabled, check location service
                checkLocationEnabled()
            }
        } ?: run {
            // Device does not support bluetooth
            ToastUtil.show("Device does not support bluetooth, cannot configure device")
            // Provide alternative or exit flow
            showDeviceNotSupportedDialog()
        }
    }
    
    // Show device not supported dialog
    private fun showDeviceNotSupportedDialog() {
        // Here you can implement a dialog to inform the user that the device does not support bluetooth
        // Can provide alternatives or exit the flow
        ToastUtil.show("Your device does not support bluetooth, cannot configure smart device")
        finish()
    }
    
    // Check if location service is enabled
    private fun checkLocationEnabled() {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isLocationEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        
        if (!isLocationEnabled) {
            // Location service not enabled, prompt user to enable
            // Jump to location settings page
            try {
                val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                locationSettingsLauncher.launch(intent)
            } catch (e: Exception) {
                CovLogger.e(TAG, "Unable to open location settings page: ${e.message}")
                ToastUtil.show("Please manually enable location service")
            }
            
            permissionDialog?.updateLocationPermissionStatus(false)
            showPermissionDialog(false, 
                bluetoothAdapter?.isEnabled == true
            )
        } else {
            // All conditions met, can enter network configuration process
            permissionDialog?.updateLocationPermissionStatus(true)
            startWifiConnectActivity()
        }
    }
    
    // Check location service after returning from settings
    private fun checkLocationEnabledAfterSettings() {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isLocationEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        
        if (isLocationEnabled) {
            // Location service enabled, can enter network configuration process
            permissionDialog?.updateLocationPermissionStatus(true)
            dismissPermissionDialog()
            startWifiConnectActivity()
        } else {
            // Location service still not enabled
            ToastUtil.show("Location service must be enabled to configure the device")
            permissionDialog?.updateLocationPermissionStatus(false)
        }
    }
    
    // Start Wi-Fi connection page
    private fun startWifiConnectActivity() {
        CovDeviceScanActivity.startActivity(this)
    }

    // Add method to update button state
    private fun updateNextButtonState(isChecked: Boolean) {
        mBinding?.apply {
            btnNext.let { button ->
                button.isEnabled = isChecked
                button.alpha = if (isChecked) 1.0f else 0.5f
            }
        }
    }

    inner class CovIotSetupImageAdapter(private val images: List<DeviceImage>) :
        RecyclerView.Adapter<CovIotSetupImageAdapter.ImageViewHolder>() {

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ImageViewHolder {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.cov_item_device_image, parent, false)
            return ImageViewHolder(view)
        }

        override fun onBindViewHolder(holder: ImageViewHolder, position: Int) {
            val deviceImage = images[position]
            holder.imageView.setImageResource(deviceImage.resourceId)
            holder.imageView.contentDescription = deviceImage.description
        }

        override fun getItemCount(): Int = images.size

        inner class ImageViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
            val imageView: ImageView = itemView.findViewById(R.id.iv_device_image)
        }
    }
}