package io.agora.scene.convoai.iot.ui

import android.content.Context
import android.content.Intent
import android.os.CountDownTimer
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.recyclerview.widget.LinearLayoutManager
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.getStatusBarHeight
import io.agora.scene.convoai.iot.CovLogger
import io.agora.scene.convoai.iot.databinding.CovActivityDeviceScanBinding
import io.agora.scene.convoai.iot.adapter.CovIotDeviceScanListAdapter
import io.iot.dn.ble.callback.BleListener
import io.iot.dn.ble.manager.BleManager
import io.iot.dn.ble.model.BleDevice
import io.iot.dn.ble.state.BleConnectionState
import io.iot.dn.ble.state.BleScanState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import io.agora.scene.convoai.iot.manager.CovScanBleDeviceManager
import io.agora.scene.convoai.iot.ui.dialog.CovPermissionDialog
import io.iot.dn.ble.log.BleLogCallback
import io.iot.dn.ble.log.BleLogLevel
import io.iot.dn.ble.log.BleLogger

class CovDeviceScanActivity : BaseActivity<CovActivityDeviceScanBinding>() {


    companion object {
        private const val TAG = "CovDeviceScanActivity"
        fun startActivity(activity: BaseActivity<*>) {
            val intent = Intent(activity, CovDeviceScanActivity::class.java)
            activity.startActivity(intent)
        }
    }
    
    // Create coroutine scope for asynchronous operations
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    private val bleManager = BleManager(this)

    // Device list adapter
    private lateinit var deviceAdapter: CovIotDeviceScanListAdapter
    
    // Device list
    private val deviceList = mutableListOf<BleDevice>()
    
    // Countdown timer
    private var countDownTimer: CountDownTimer? = null

    private var permissionDialog: CovPermissionDialog? = null
    
    // Scan state
    private enum class ScanState {
        SCANNING,    // Scanning
        FAILED,      // Scan failed
        SUCCESS      // Scan successful
    }

    override fun getViewBinding(): CovActivityDeviceScanBinding {
        return CovActivityDeviceScanBinding.inflate(layoutInflater)
    }

    override fun initView() {
        setupView()
        setupDeviceList()
        setupRippleAnimation()
        initBle()
        startScan()
    }

    override fun onDestroy() {
        countDownTimer?.cancel()
        coroutineScope.cancel()
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        // Check if WiFi is enabled, if enabled, close the permission dialog
        if (isNetworkConnected() && permissionDialog?.isAdded == true) {
            permissionDialog?.dismiss()
        }
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
            
            // Set retry button click event
            btnRetry.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    startScan()
                }
            })
        }
    }
    
    // Setup ripple animation
    private fun setupRippleAnimation() {
        mBinding?.apply {
            // Ripple animation during scanning
            rippleAnimationView.scaleFactor = 1.4f
        }
    }
    
    private fun setupDeviceList() {
        deviceAdapter = CovIotDeviceScanListAdapter(deviceList) { device ->
            // Device click event handling
            CovLogger.d(TAG, "Device clicked: ${device.name}")
            // Check network connection status
            if (!isNetworkConnected()) {
                // Network not connected, show prompt dialog
                showNetworkSettingsDialog()
            } else {
                // Network connected, only pass device ID
                CovWifiSelectActivity.startActivity(this, device.address)
            }
        }
        
        mBinding?.apply {
            rvDeviceList.layoutManager = LinearLayoutManager(this@CovDeviceScanActivity)
            rvDeviceList.adapter = deviceAdapter
        }
    }

    private fun initBle() {
        BleLogger.init(object : BleLogCallback {
            override fun onLog(level: BleLogLevel, tag: String, message: String) {
                when (level) {
                    BleLogLevel.DEBUG -> Log.d(tag, message)
                    BleLogLevel.INFO -> Log.i(tag, message)
                    BleLogLevel.WARN -> Log.w(tag, message)
                    BleLogLevel.ERROR -> Log.e(tag, message)
                }
            }
        })
        bleManager.addListener(object : BleListener {
            override fun onScanStateChanged(state: BleScanState) {
                // Handle scan state changes
            }

            override fun onDeviceFound(device: BleDevice) {
                // Add discovered device to device manager
                CovScanBleDeviceManager.addDevice(device)
                
                runOnUiThread {
                    // Check if the device already exists in the list
                    if (deviceList.none { it.address == device.address } && device.name.isNotEmpty()) {
                        deviceList.add(device)
                        deviceAdapter.notifyDataSetChanged()
                        
                        // After finding a device, hide the scanning view but keep the ripple animation
                        if (deviceList.size == 1) { // When first device is found
                            mBinding?.clScanning?.visibility = View.GONE
                            mBinding?.clScanResult?.visibility = View.VISIBLE
                            // Keep ripple animation visible
                            mBinding?.rippleAnimationView?.alpha = 0.5F
                        }
                    }
                }
            }

            override fun onConnectionStateChanged(state: BleConnectionState) {
                // Handle connection state changes
            }

            override fun onDataReceived(uuid: String, data: ByteArray) {
                // Handle received data
            }
        })
    }
    
    // Start scanning for devices
    private fun startScan() {
        updateScanState(ScanState.SCANNING)
        
        // Clear previous device list
        deviceList.clear()
        deviceAdapter.notifyDataSetChanged()
        
        // Clear devices in device manager
        CovScanBleDeviceManager.clearDevices()
        
        // Start Bluetooth scanning
        bleManager.startScan(null)
        
        // Start 30-second countdown
        countDownTimer?.cancel()
        countDownTimer = object : CountDownTimer(20000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = millisUntilFinished / 1000
                mBinding?.tvCountdown?.text = "${seconds}s"
            }

            override fun onFinish() {
                // Stop scanning
                bleManager.stopScan()
                
                // Determine scan success based on deviceList size
                if (deviceList.isEmpty()) {
                    // No devices found, show failure state
                    updateScanState(ScanState.FAILED)
                } else {
                    // Devices found, show device list
                    updateScanState(ScanState.SUCCESS)
                }
            }
        }.start()
    }
    
    // Update scan state UI
    private fun updateScanState(state: ScanState) {
        mBinding?.apply {
            when (state) {
                ScanState.SCANNING -> {
                    rippleAnimationView.alpha = 1.0F
                    tvCountdown.visibility = View.VISIBLE
                    clScanning.visibility = View.VISIBLE
                    clScanFailed.visibility = View.GONE
                    clScanResult.visibility = View.VISIBLE
                    rippleAnimationView.visibility = View.VISIBLE
                    
                    // When scanning, set clScanResult 160dp from bottom
                    val layoutParams = clScanResult.layoutParams as ViewGroup.MarginLayoutParams
                    layoutParams.bottomMargin = 160.dp.toInt()
                    clScanResult.layoutParams = layoutParams
                }
                ScanState.FAILED -> {
                    clScanning.visibility = View.GONE
                    clScanFailed.visibility = View.VISIBLE
                    clScanResult.visibility = View.GONE
                    rippleAnimationView.visibility = View.GONE
                    tvCountdown.visibility = View.GONE
                }
                ScanState.SUCCESS -> {
                    clScanning.visibility = View.GONE
                    clScanFailed.visibility = View.GONE
                    clScanResult.visibility = View.VISIBLE
                    rippleAnimationView.visibility = View.GONE // Hide ripple animation when scan succeeds
                    tvCountdown.visibility = View.GONE
                    
                    // After successful scan, set clScanResult 60dp from bottom
                    val layoutParams = clScanResult.layoutParams as ViewGroup.MarginLayoutParams
                    layoutParams.bottomMargin = 60.dp.toInt()
                    clScanResult.layoutParams = layoutParams
                }
            }
        }
    }

    // Check if WiFi is enabled
    private fun isNetworkConnected(): Boolean {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
        return wifiManager.isWifiEnabled
    }

    // Show permission dialog
    private fun showNetworkSettingsDialog() {
        if (permissionDialog == null) {
            permissionDialog = CovPermissionDialog.newInstance(
                onDismiss = {
                    // Dialog dismiss callback
                    permissionDialog = null
                },
                onWifiPermission = {
                    startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                },
                showBluetoothPermission = false,
                showLocation = false,
                showWifi = true
            )
        }

        permissionDialog?.apply {
            updateWifiPermissionStatus(false)
            if (!isAdded) {
                show(supportFragmentManager, "permission_dialog")
            }
        }
    }
} 