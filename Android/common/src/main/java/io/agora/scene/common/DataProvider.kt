package io.agora.scene.common

interface DataProvider {
    fun rtcAppId(): String
    fun rtcAppCert(): String
    fun toolboxHost(): String
    fun isMainland(): Boolean
    fun appBuildNo(): String
    fun envName(): String
}