package io.agora.scene.convoai.iot.model

import io.iot.dn.ble.model.BleDevice

data class CovIotDevice(
    val id: String,
    var name: String,
    val bleDevice: BleDevice,
    val currentPreset: String, // preset_name
    val currentLanguage: String, // language code
    val enableAIVAD: Boolean
)