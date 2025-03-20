package io.iot.dn.ble.connector

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothProfile
import android.content.Context
import androidx.annotation.RequiresPermission
import io.iot.dn.ble.callback.BleConnectionCallback
import io.iot.dn.ble.config.BleConfig
import io.iot.dn.ble.log.BleLogger
import io.iot.dn.ble.state.BleConnectionState
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * BleConnector handles Bluetooth Low Energy (BLE) connections and communication.
 *
 * This class provides functionality to:
 * - Connect to BLE devices
 * - Send/receive data via BLE characteristics
 * - Handle WiFi credentials distribution
 * - Manage BLE connection states
 *
 * @property context Android context used for BLE operations
 * @property bleConfig Configuration parameters for BLE operations
 */
class BleConnector(
    private val context: Context,
    private val bleConfig: BleConfig
) : IBleConnector {

    private var bluetoothGatt: BluetoothGatt? = null
    private var connectLatch = CountDownLatch(1)
    private var ssidLatch = CountDownLatch(1)
    private var pwdLatch = CountDownLatch(1)
    private var opCodeLatch = CountDownLatch(1)
    private var cmdLatch = CountDownLatch(1)
    private var tokenLatch = CountDownLatch(1)
    private var urlLatch = CountDownLatch(1)
    private var customDataLatch = CountDownLatch(1)
    private var callback: BleConnectionCallback? = null
    private var opRet: Triple<Int, Int, ByteArray?>? = null
    private var currentConnectionState: BleConnectionState = BleConnectionState.IDLE
    private var preState = DEFAULT_PRE_STATE

    /**
     * Connects to the specified BLE device.
     *
     * @param device The BluetoothDevice to connect to
     * @return true if connection was successful, false otherwise
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun connect(device: BluetoothDevice): Boolean {
        BleLogger.d(TAG, "Connecting to device: ${device.address}")
        resetConnectLatch()
        notifyConnectionStateChanged(BleConnectionState.CONNECTING)
        bluetoothGatt = device.connectGatt(context, false, gattCallback)
        BleLogger.d(TAG, "Waiting for connection completion")
        val result = connectLatch.await(bleConfig.connectTimeout, TimeUnit.MILLISECONDS)
        val connectRet = isConnected()
        BleLogger.d(TAG, "Connection result: $result")
        if (!connectRet) {
            disconnectInner()
            return false
        }
        notifyConnectionStateChanged(BleConnectionState.CONNECTED)
        return true
    }

    /**
     * Disconnects from the currently connected BLE device.
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun disconnect() {
        BleLogger.d(TAG, "Disconnecting BLE connection")
        disconnectInner()
    }

    /**
     * Sends data to a specific BLE characteristic.
     *
     * @param serviceUuid UUID of the BLE service
     * @param characteristicUuid UUID of the BLE characteristic
     * @param data Data bytes to send
     * @return true if send was successful, false otherwise
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun send(serviceUuid: String, characteristicUuid: String, data: ByteArray): Boolean {
        BleLogger.d(
            TAG,
            "Sending data to characteristic: $characteristicUuid, service: $serviceUuid, data length: ${data.size}"
        )
        resetCustomDataLatch()
        val service = try {
            bluetoothGatt?.getService(UUID.fromString(serviceUuid))
        } catch (e: IllegalArgumentException) {
            BleLogger.e(TAG, "Invalid service UUID format: $serviceUuid")
            notifyMessageSent(serviceUuid, characteristicUuid, false, "Invalid service UUID format")
            return false
        }
        if (service == null) {
            BleLogger.e(TAG, "Send failed: Service not found $serviceUuid")
            notifyMessageSent(serviceUuid, characteristicUuid, false, "Service not found $serviceUuid")
            return false
        }

        val characteristic = service.getCharacteristic(UUID.fromString(characteristicUuid))
        if (characteristic == null) {
            BleLogger.e(TAG, "Send failed: Characteristic not found $characteristicUuid")
            notifyMessageSent(serviceUuid, characteristicUuid, false, "Characteristic not found $characteristicUuid")
            return false
        }

        characteristic.value = data
        val result = bluetoothGatt?.writeCharacteristic(characteristic) == true
        BleLogger.d(TAG, "Send result: $result")
        if (!result) {
            BleLogger.e(TAG, "Send failed")
            notifyMessageSent(serviceUuid, characteristicUuid, false, "Send failed")
            return false
        }
        val awaitRet = customDataLatch.await(bleConfig.awaitTimeout, TimeUnit.MILLISECONDS)
        BleLogger.d(TAG, "Send await result: $awaitRet")
        // Notify message send result
        notifyMessageSent(serviceUuid, characteristicUuid, awaitRet, if (!awaitRet) "Send timeout" else null)
        return awaitRet
    }

    /**
     * Sends WiFi SSID to the connected device.
     *
     * @param ssid WiFi network SSID
     * @return true if send was successful, false otherwise
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun sendSSID(ssid: String): Boolean {
        BleLogger.d(TAG, "sendSSID => $ssid")
        resetSsidLatch()
        if (ssid.isBlank()) {
            BleLogger.d(TAG, "sendSSID ssid is blank")
            notifyMessageSent(SERVICE_UUID.toString(), SSID_UUID.toString(), false, "ssid is blank")
            return false
        }

        val gatt = bluetoothGatt ?: return false
        val service = gatt.getService(SERVICE_UUID) ?: return false
        val characteristic = service.getCharacteristic(SSID_UUID) ?: return false
        characteristic.setValue(ssid)
        val ret = gatt.writeCharacteristic(characteristic)
        BleLogger.d(TAG, "sendSSID ret => $ret")
        if (!ret) {
            BleLogger.e(TAG, "sendSSID failed")
            notifyMessageSent(SERVICE_UUID.toString(), SSID_UUID.toString(), false, "sendSSID failed")
            return false
        }
        val awaitRet = ssidLatch.await(bleConfig.awaitTimeout, TimeUnit.MILLISECONDS)
        BleLogger.d(TAG, "sendSSID awaitRet: $awaitRet")
        notifyMessageSent(
            SERVICE_UUID.toString(),
            SSID_UUID.toString(),
            awaitRet,
            if (!awaitRet) "Send timeout" else null
        )
        return awaitRet
    }

    /**
     * Sends WiFi password to the connected device.
     *
     * @param pwd WiFi network password
     * @return true if send was successful, false otherwise
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun sendPassword(pwd: String): Boolean {
        BleLogger.d(TAG, "sendPassword => $pwd")
        resetPwdLatch()

        val gatt = bluetoothGatt ?: return false
        val service = gatt.getService(SERVICE_UUID) ?: return false
        val characteristic = service.getCharacteristic(PASSWORD_UUID) ?: return false

        characteristic.setValue(pwd)
        val ret = gatt.writeCharacteristic(characteristic)
        BleLogger.d(TAG, "sendPassword ret => $ret")
        if (!ret) {
            BleLogger.e(TAG, "sendPassword failed")
            notifyMessageSent(SERVICE_UUID.toString(), PASSWORD_UUID.toString(), false, "sendPassword failed")
            return false
        }
        val awaitRet = pwdLatch.await(bleConfig.awaitTimeout, TimeUnit.MILLISECONDS)
        BleLogger.d(TAG, "sendPassword awaitRet: $awaitRet")
        notifyMessageSent(
            SERVICE_UUID.toString(),
            PASSWORD_UUID.toString(),
            awaitRet,
            if (!awaitRet) "Send timeout" else null
        )
        return awaitRet
    }

    /**
     * Sends authentication token to the connected device.
     *
     * @param token Authentication token string
     * @return true if send was successful, false otherwise
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun sendToken(token: String): Boolean {
        BleLogger.d(TAG, "sendToken => $token")

        // Check if token length exceeds maximum limit
        if (token.length > MAX_TOKEN_LENGTH) {
            BleLogger.e(TAG, "Token length exceeds maximum limit of $MAX_TOKEN_LENGTH characters")
            return false
        }

        val halfLength = token.length / 2
        val firstPart = token.substring(0, halfLength)
        val secondPart = token.substring(halfLength)

        // Send first part
        BleLogger.d(TAG, "Sending first part of token")
        val firstResult = sendTokenInternal(AUTH_TOKEN_FIRST_UUID, firstPart)
        if (!firstResult) {
            BleLogger.e(TAG, "Failed to send first part of token")
            return false
        }

        // Send second part
        BleLogger.d(TAG, "Sending second part of token")
        val secondResult = sendTokenInternal(AUTH_TOKEN_SECOND_UUID, secondPart)
        if (!secondResult) {
            BleLogger.e(TAG, "Failed to send second part of token")
            return false
        }

        return true
    }

    /**
     * Internal method to actually send token data
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    private fun sendTokenInternal(uuid: UUID, tokenData: String): Boolean {
        resetTokenLatch()

        val gatt = bluetoothGatt ?: return false
        val service = gatt.getService(SERVICE_UUID) ?: return false
        val characteristic = service.getCharacteristic(uuid) ?: return false

        characteristic.setValue(tokenData)
        val ret = gatt.writeCharacteristic(characteristic)
        BleLogger.d(TAG, "sendTokenInternal ret => $ret")
        if (!ret) {
            BleLogger.e(TAG, "sendTokenInternal failed")
            notifyMessageSent(SERVICE_UUID.toString(), uuid.toString(), false, "sendToken failed")
            return false
        }
        val awaitRet = tokenLatch.await(bleConfig.awaitTimeout, TimeUnit.MILLISECONDS)
        BleLogger.d(TAG, "sendTokenInternal awaitRet: $awaitRet")
        notifyMessageSent(
            SERVICE_UUID.toString(),
            uuid.toString(),
            awaitRet,
            if (!awaitRet) "Send timeout" else null
        )
        return awaitRet
    }

    /**
     * Sends URL to the connected device.
     *
     * @param url The URL to send
     * @return true if send was successful, false otherwise
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun sendUrl(url: String): Boolean {
        BleLogger.d(TAG, "sendUrl => $url")
        resetUrlLatch()

        val gatt = bluetoothGatt ?: return false
        val service = gatt.getService(SERVICE_UUID) ?: return false
        val characteristic = service.getCharacteristic(URL_UUID) ?: return false

        characteristic.setValue(url)
        val ret = gatt.writeCharacteristic(characteristic)
        BleLogger.d(TAG, "sendUrl ret => $ret")
        if (!ret) {
            BleLogger.e(TAG, "sendUrl failed")
            notifyMessageSent(SERVICE_UUID.toString(), URL_UUID.toString(), false, "sendUrl failed")
            return false
        }
        val awaitRet = urlLatch.await(bleConfig.awaitTimeout, TimeUnit.MILLISECONDS)
        BleLogger.d(TAG, "sendUrl awaitRet: $awaitRet")
        notifyMessageSent(
            SERVICE_UUID.toString(),
            URL_UUID.toString(),
            awaitRet,
            if (!awaitRet) "Send timeout" else null
        )
        return awaitRet
    }

    /**
     * Writes operation data to the operation characteristic.
     *
     * @param opCode Operation code to write
     * @param payload Optional payload data
     * @param needResp Whether response is expected
     * @return Pair of success boolean and operation result Triple
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    private fun operationCharacteristicWrite(
        opCode: Int,
        payload: ByteArray?,
        needResp: Boolean
    ): Pair<Boolean, Triple<Int, Int, ByteArray?>?> {
        BleLogger.d(TAG, "operationCharacteristicWrite opCode => $opCode, needResp => $needResp")
        resetOpCodeLatch()
        resetCmdLatch()

        val gatt = bluetoothGatt ?: return false to null
        val service = gatt.getService(SERVICE_UUID) ?: return false to null
        val characteristic = service.getCharacteristic(OPERATION_UUID) ?: return false to null

        val length = payload?.size ?: 0
        val value = ByteArray(4 + length)
        value[0] = (opCode.and(0xFF)).toByte()
        value[1] = (opCode.shr(8)).toByte()

        if (length > 0) {
            value[2] = (length.and(0xFF)).toByte()
            value[3] = (length.shr(8)).toByte()
            System.arraycopy(payload ?: ByteArray(0), 0, value, 4, length)
        } else {
            value[2] = 0
            value[3] = 0
        }

        characteristic.value = value
        val ret = gatt.writeCharacteristic(characteristic)
        BleLogger.d(TAG, "operationCharacteristicWrite opCode => $opCode ret => $ret")
        if (!ret) {
            BleLogger.e(TAG, "operationCharacteristicWrite failed")
            return false to null
        }

        val awaitRet = opCodeLatch.await(bleConfig.awaitTimeout, TimeUnit.MILLISECONDS)
        BleLogger.d(TAG, "operationCharacteristicWrite awaitRet: $awaitRet")
        if (!needResp) {
            BleLogger.d(TAG, "operationCharacteristicWrite needResp is false, return true to null")
            return true to null
        }
        val awaitCmdRet = cmdLatch.await(bleConfig.awaitTimeout, TimeUnit.MILLISECONDS)
        BleLogger.d(TAG, "operationCharacteristicWrite awaitCmdRet => $awaitCmdRet")
        val resp = opRet?.copy()
        opRet = null
        return awaitCmdRet to resp
    }

    /**
     * Starts station mode on the connected device.
     *
     * @return true if operation was successful, false otherwise
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun startStation(): Boolean {
        return operationCharacteristicWrite(OP_STATION_START, null, true).first
    }

    /**
     * Get the device ID of connected BLE device
     *
     * @return Device ID string
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    override fun getDeviceId(): String {
        BleLogger.d(TAG, "getDeviceId")
        val ret = operationCharacteristicWrite(OP_GET_DEVICE_ID, null, true)
        BleLogger.d(TAG, "getDeviceId ret => ${ret.second?.third?.let { String(it) }}")
        return ret.second?.third?.let { String(it) } ?: ""
    }

    /**
     * Enables notifications for the notification characteristic.
     *
     * @return true if notifications were enabled successfully, false otherwise
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    private fun enableNotifyCharacteristic(): Boolean {
        BleLogger.d(TAG, "enableNotifyCharacteristic")
        val gatt = bluetoothGatt ?: kotlin.run {
            BleLogger.d(TAG, "enableNotifyCharacteristic gatt is null, failed")
            return false
        }
        val gattService = gatt.getService(SERVICE_UUID) ?: run {
            BleLogger.d(TAG, "enableNotifyCharacteristic get service is null")
            return false
        }
        val characteristic = gattService.getCharacteristic(NOTIFICATION_UUID) ?: run {
            BleLogger.d(TAG, "enableNotifyCharacteristic get characteristic is null")
            return false
        }
        gatt.setCharacteristicNotification(characteristic, true)
        val descriptor = characteristic.getDescriptor(DESCRIPTOR_UUID) ?: kotlin.run {
            BleLogger.d(TAG, "enableNotifyCharacteristic getDescriptor is null")
            return false
        }
        descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        val ret = gatt.writeDescriptor(descriptor)
        BleLogger.d(TAG, "enableNotifyCharacteristic writeDescriptor ret => $ret")
        return ret
    }

    /**
     * Callback for handling BLE GATT events.
     */
    private val gattCallback = object : BluetoothGattCallback() {

        @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            BleLogger.d(TAG, "Connection state changed: status=$status, newState=$newState")
            if (newState == preState) {
                BleLogger.e(TAG, "Connection state changed: status=$status, newState=$newState, preState=$preState")
                return
            }
            preState = newState
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    BleLogger.i(TAG, "Device connected, discovering services")
                    val requestMtuRet = bluetoothGatt?.requestMtu(255) ?: false
                    BleLogger.i(TAG, "requestMtu ret $requestMtuRet")
                    if (!requestMtuRet) {
                        disconnectInner()
                    }
                }

                BluetoothProfile.STATE_DISCONNECTED -> {
                    disconnectInner()
                }

                BluetoothProfile.STATE_CONNECTING -> {
                }

                BluetoothProfile.STATE_DISCONNECTING -> {
                }
            }
        }

        @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
        override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
            super.onMtuChanged(gatt, mtu, status)
            BleLogger.d(TAG, "onMtuChanged: mtu: $mtu, status: $status")
            if (status == BluetoothGatt.GATT_SUCCESS) {
                BleLogger.d(TAG, "onMtuChanged: to discoverServices")
                val discoverServicesRet = bluetoothGatt?.discoverServices() ?: false
                BleLogger.d(TAG, "discoverServices ret $discoverServicesRet")
                if (!discoverServicesRet) {
                    disconnectInner()
                }
            }
        }

        @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            BleLogger.d(TAG, "Services discovered: status=$status")
            if (status != BluetoothGatt.GATT_SUCCESS) {
                BleLogger.e(TAG, "Service discovery failed: $status")
                return
            }
            BleLogger.i(TAG, "Service discovery successful")
            if (!enableNotifyCharacteristic()) {
                BleLogger.e(TAG, "enableNotifyCharacteristic failed")
                disconnectInner()
            }
        }

        override fun onCharacteristicRead(
            gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray, status: Int
        ) {
            BleLogger.d(TAG, "Characteristic read: ${characteristic.uuid}, status=$status, data length=${value.size}")
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int
        ) {
            BleLogger.d(TAG, "onCharacteristicWrite: status: $status  uuid ${characteristic.uuid}")
            if (status == BluetoothGatt.GATT_SUCCESS) {
                when (characteristic.uuid) {
                    OPERATION_UUID -> {
                        BleLogger.d(TAG, "onCharacteristicWrite: operation write success")
                        opCodeLatch.countDown()
                    }

                    SSID_UUID -> {
                        BleLogger.d(TAG, "onCharacteristicWrite: ssid write success")
                        ssidLatch.countDown()
                    }

                    PASSWORD_UUID -> {
                        BleLogger.d(TAG, "onCharacteristicWrite: pwd write success")
                        pwdLatch.countDown()
                    }

                    AUTH_TOKEN_FIRST_UUID -> {
                        BleLogger.d(TAG, "onCharacteristicWrite: token first write success")
                        tokenLatch.countDown()
                    }

                    AUTH_TOKEN_SECOND_UUID -> {
                        BleLogger.d(TAG, "onCharacteristicWrite: token second write success")
                        tokenLatch.countDown()
                    }

                    URL_UUID -> {
                        BleLogger.d(TAG, "onCharacteristicWrite: url write success")
                        urlLatch.countDown()
                    }

                    else -> {
                        BleLogger.d(TAG, "onCharacteristicWrite: custom data write success")
                        customDataLatch.countDown()
                    }
                }
            }
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int
        ) {
            BleLogger.d(TAG, "onDescriptorWrite: status: $status  uuid ${descriptor.uuid}")
            if (status == BluetoothGatt.GATT_SUCCESS && descriptor.uuid == DESCRIPTOR_UUID) {
                BleLogger.d(TAG, "onDescriptorWrite: count down connect latch")
                connectLatch.countDown()
            }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic?) {
            super.onCharacteristicChanged(gatt, characteristic)
            BleLogger.i(TAG, "onCharacteristicChanged ${characteristic?.uuid}")
            characteristic ?: return

            val uuid = characteristic.uuid.toString()
            val data = characteristic.value
            var payload: ByteArray? = null

            // Notify all listeners of received data
            notifyDataReceived(uuid, data)

            val opcode = data[0].toInt() or (data[1].toInt() shl 8)
            val statusCode = java.lang.Byte.toUnsignedInt(data[2])
            val length = data[3].toInt() or (data[4].toInt() shl 8)

            if (length != data.size - 5) {
                BleLogger.e(TAG, "payload error")
            } else {
                payload = ByteArray(length)
                System.arraycopy(data, 5, payload, 0, length)
            }

            if (uuid == NOTIFICATION_UUID.toString()) {
                notificationDataHandle(opcode, statusCode, payload)
            }
        }
    }

    /**
     * Handles notification data received from the device.
     */
    private fun notificationDataHandle(opcode: Int, status: Int, payload: ByteArray?) {
        BleLogger.i(TAG, "notificationDataHandle opcode: $opcode status: $status")
        opRet = Triple(opcode, status, payload)
        cmdLatch.countDown()
    }

    /**
     * Checks if device is currently connected.
     *
     * @return true if connected, false otherwise
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    private fun isConnected(): Boolean {
        BleLogger.d(TAG, "invoke isConnected")
        val gatt = bluetoothGatt ?: kotlin.run {
            BleLogger.d(TAG, "isConnected gatt is null, false")
            return false
        }
        val gattService = gatt.getService(SERVICE_UUID) ?: run {
            BleLogger.d(TAG, "isConnected get service is null")
            return false
        }
        val characteristic = gattService.getCharacteristic(NOTIFICATION_UUID) ?: run {
            BleLogger.d(TAG, "isConnected get characteristic is null")
            return false
        }
        gatt.setCharacteristicNotification(characteristic, true)
        val descriptor = characteristic.getDescriptor(DESCRIPTOR_UUID) ?: kotlin.run {
            BleLogger.d(TAG, "isConnected getDescriptor is null")
            return false
        }
        val ret = descriptor.value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
        BleLogger.d(TAG, "isConnected ENABLE_NOTIFICATION_VALUE ret => $ret")
        return ret
    }

    /**
     * Internal method to handle disconnection cleanup.
     */
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    private fun disconnectInner() {
        BleLogger.d(TAG, "disconnectInner")
        notifyConnectionStateChanged(BleConnectionState.DISCONNECTED)
        preState = DEFAULT_PRE_STATE
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
        connectLatch.countDown()
        ssidLatch.countDown()
        pwdLatch.countDown()
        opCodeLatch.countDown()
        cmdLatch.countDown()
        tokenLatch.countDown()
        customDataLatch.countDown()
        urlLatch.countDown()
    }

    /**
     * Sets callback for connection events.
     */
    override fun setConnectionCallback(callback: BleConnectionCallback?) {
        this.callback = callback
    }

    /**
     * Notifies listeners of connection state changes.
     */
    private fun notifyConnectionStateChanged(state: BleConnectionState) {
        BleLogger.d(TAG, "Connection state changed to: $state")
        currentConnectionState = state
        callback?.onConnectionStateChanged(state)
    }

    /**
     * Notifies listeners of received data.
     */
    private fun notifyDataReceived(uuid: String, data: ByteArray) {
        callback?.onDataReceived(uuid, data)
    }

    /**
     * Notifies listeners of message send status.
     */
    private fun notifyMessageSent(
        serviceUuid: String,
        characteristicUuid: String,
        success: Boolean,
        error: String? = null
    ) {
        callback?.onMessageSent(serviceUuid, characteristicUuid, success, error)
    }

    /**
     * Resets the connection latch to initial state
     */
    private fun resetConnectLatch() {
        connectLatch = CountDownLatch(1)
    }

    /**
     * Resets the SSID latch to initial state
     */
    private fun resetSsidLatch() {
        ssidLatch = CountDownLatch(1)
    }

    /**
     * Resets the password latch to initial state
     */
    private fun resetPwdLatch() {
        pwdLatch = CountDownLatch(1)
    }

    /**
     * Resets the URL latch to initial state
     */
    private fun resetUrlLatch() {
        urlLatch = CountDownLatch(1)
    }

    /**
     * Resets the token latch to initial state
     */
    private fun resetTokenLatch() {
        tokenLatch = CountDownLatch(1)
    }

    /**
     * Resets the operation code latch to initial state
     */
    private fun resetOpCodeLatch() {
        opCodeLatch = CountDownLatch(1)
    }

    /**
     * Resets the command latch to initial state
     */
    private fun resetCmdLatch() {
        cmdLatch = CountDownLatch(1)
    }

    /**
     * Resets the custom data latch to initial state
     */
    private fun resetCustomDataLatch() {
        customDataLatch = CountDownLatch(1)
    }

    companion object {
        private const val TAG = "BleConnector"
        private val SERVICE_UUID = UUID.fromString("0000fa00-0000-1000-8000-00805f9b34fb")
        private val NOTIFICATION_UUID = UUID.fromString("0000ea01-0000-1000-8000-00805f9b34fb")
        private val OPERATION_UUID = UUID.fromString("0000ea02-0000-1000-8000-00805f9b34fb")
        private val SSID_UUID = UUID.fromString("0000ea05-0000-1000-8000-00805f9b34fb")
        private val PASSWORD_UUID = UUID.fromString("0000ea06-0000-1000-8000-00805f9b34fb")
        private val AUTH_TOKEN_FIRST_UUID = UUID.fromString("0000ea07-0000-1000-8000-00805f9b34fb")
        private val AUTH_TOKEN_SECOND_UUID = UUID.fromString("0000ea08-0000-1000-8000-00805f9b34fb")
        private val URL_UUID = UUID.fromString("0000ea09-0000-1000-8000-00805f9b34fb")
        private val DESCRIPTOR_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
        private const val OP_STATION_START = 1
        private const val OP_GET_DEVICE_ID = 60000
        private const val DEFAULT_PRE_STATE = -1000
        private const val MAX_TOKEN_LENGTH = 500
    }
}