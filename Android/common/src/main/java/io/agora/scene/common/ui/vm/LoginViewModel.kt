package io.agora.scene.common.ui.vm

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.agora.scene.common.R
import io.agora.scene.common.constant.SSOUserManager
import io.agora.scene.common.net.ApiManager
import io.agora.scene.common.net.ApiManagerService
import io.agora.scene.common.util.toast.ToastUtil
import kotlinx.coroutines.launch
import retrofit2.HttpException
import io.agora.scene.common.net.SSOUserInfo
import io.agora.scene.common.util.CommonLogger

class LoginViewModel : ViewModel() {

    companion object{
       private const val TAG = "LoginViewModel"
    }

    private fun getApiService() = ApiManager.getService(ApiManagerService::class.java)

    private val _userInfoLiveData: MutableLiveData<SSOUserInfo?> = MutableLiveData()
    val userInfoLiveData: LiveData<SSOUserInfo?> get() = _userInfoLiveData

    fun getUserInfoByToken(token: String) {
        viewModelScope.launch {
            runCatching {
                getApiService().ssoUserInfo("Bearer $token")
            }.onSuccess { result ->
                if (result.isSuccess && result.data != null) {
                    SSOUserManager.saveUser(result.data!!)
                    _userInfoLiveData.postValue(result.data)
                } else {
                    SSOUserManager.logout()
                    _userInfoLiveData.postValue(null)
                    ToastUtil.show(R.string.common_login_expired)
                }
            }.onFailure { e ->
                SSOUserManager.logout()
                _userInfoLiveData.postValue(null)
                ToastUtil.show(R.string.common_login_expired)
            }
        }
    }
}