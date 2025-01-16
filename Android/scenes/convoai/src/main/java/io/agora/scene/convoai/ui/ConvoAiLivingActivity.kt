package io.agora.scene.convoai.ui

import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Toast
import io.agora.scene.common.AgentApp
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.net.AgoraTokenType
import io.agora.scene.common.net.TokenGenerator
import io.agora.scene.common.net.TokenGeneratorType
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.LoadingDialog
import io.agora.scene.common.util.PermissionHelp
import io.agora.scene.convoai.http.AgentRequestParams
import io.agora.scene.convoai.rtc.AgoraManager
import io.agora.scene.convoai.utils.MessageParser
import io.agora.convoai.databinding.ConvoaiActivityLivingBinding
import io.agora.rtc2.ChannelMediaOptions
import io.agora.rtc2.Constants
import io.agora.rtc2.Constants.CLIENT_ROLE_BROADCASTER
import io.agora.rtc2.Constants.ERR_OK
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.RtcEngineConfig
import io.agora.rtc2.RtcEngineEx
import io.agora.scene.convoai.ConvoAiLogger
import io.agora.scene.convoai.http.ConvAIManager
import kotlin.random.Random

class ConvoAiLivingActivity : BaseActivity<ConvoaiActivityLivingBinding>() {

    private val TAG = "LivingActivity"

    private lateinit var engine: RtcEngineEx

    private var loadingDialog: LoadingDialog? = null

    private var networkDialog: AgentNetworkDialogFragment? = null

    private var parser = MessageParser()

    private var isLocalAudioMuted = false
    private var rtcToken: String? = null
    private var channelName = ""
    private var localUid: Int = 0
    private val agentUID = 999
    private var networkStatus: Int? = null
    private var isShowMessageList = false
        set(value) {
            if (field != value) {
                field = value
                updateCenterView()
            }
        }

    var isAgentStarted = false
        set(value) {
            if (field != value) {
                field = value
                updateCenterView()
            }
        }

    override fun getViewBinding(): ConvoaiActivityLivingBinding {
        return ConvoaiActivityLivingBinding.inflate(layoutInflater)
    }

    override fun initView() {
        setupView()
        updateCenterView()
        // data
        AgoraManager.resetData()
        createRtcEngine()
        loadingDialog = LoadingDialog(this)
        channelName = "agora_" + Random.nextInt(1, 10000000).toString()
        localUid = Random.nextInt(1000, 10000000)
        getToken { }
        PermissionHelp(this).checkMicPerm({}, {
            finish()
        }, true
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        engine.leaveChannel()
        ConvAIManager.stopAgent { ok ->
            if (ok) {
                Log.d(TAG, "Agent stopped successfully")
            } else {
                Log.d(TAG, "Failed to stop agent")
            }
        }
        RtcEngine.destroy()
        AgoraManager.resetData()
        loadingDialog?.dismiss()
    }

    override fun onPause() {
        super.onPause()
        if (isAgentStarted) {
            startRecordingService()
        }
    }

    private fun startRecordingService() {
        val intent = Intent("io.agora.agent.START_FOREGROUND_SERVICE")
        sendBroadcast(intent)
    }

    private fun onClickStartAgent() {
        loadingDialog?.setMessage(getString(io.agora.scene.common.R.string.cov_detail_agent_joining))
        loadingDialog?.show()
        AgoraManager.channelName = channelName
        AgoraManager.uid = localUid
        val params = AgentRequestParams(
            channelName = channelName,
            remoteRtcUid = localUid,
            agentRtcUid = agentUID,
            ttsVoiceId = AgoraManager.voiceType.value
        )
        ConvAIManager.startAgent(params) { isAgentOK ->
            if (isAgentOK) {
                if (rtcToken == null) {
                    getToken { isTokenOK ->
                        if (isTokenOK) {
                            joinChannel()
                        } else {
                            loadingDialog?.dismiss()
                            ConvoAiLogger.e(TAG, "Token error")
                            Toast.makeText(this, io.agora.scene.common.R.string.cov_detail_join_call_failed, Toast
                                .LENGTH_SHORT)
                                .show()
                        }
                    }
                } else {
                    joinChannel()
                }
            } else {
                loadingDialog?.dismiss()
                ConvoAiLogger.e(TAG, "Agent error")
                Toast.makeText(this, io.agora.scene.common.R.string.cov_detail_join_call_failed, Toast.LENGTH_SHORT)
                    .show()
            }
        }
    }

    private fun onClickEndCall() {
        engine.leaveChannel()
        loadingDialog?.setMessage(getString(io.agora.scene.common.R.string.cov_detail_agent_ending))
        loadingDialog?.show()
        ConvAIManager.stopAgent { ok ->
            loadingDialog?.dismiss()
            if (ok) {
                Toast.makeText(this, io.agora.scene.common.R.string.cov_detail_agent_leave, Toast.LENGTH_SHORT).show()
                isAgentStarted = false
                networkStatus = null
                AgoraManager.agentStarted = false
                resetSceneState()
            } else {
                Toast.makeText(this, "Agent Leave Failed", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun joinChannel() {
        ConvoAiLogger.e(
            TAG,
            "onClickStartAgent: rtcToken: $rtcToken, channelName: $channelName, localUid: $localUid, agentUID: $agentUID"
        )
        val options = ChannelMediaOptions()
        options.clientRoleType = CLIENT_ROLE_BROADCASTER
        options.publishMicrophoneTrack = true
        options.publishCameraTrack = false
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = false
        engine.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
        engine.setParameters("{\"che.audio.sf.enabled\":false}")
        AgoraManager.updateDenoise(true)
        val ret = engine.joinChannel(rtcToken, channelName, localUid, options)
        ConvoAiLogger.d(TAG, "Joining RTC channel: $channelName, uid: $localUid")
        if (ret == ERR_OK) {
            ConvoAiLogger.d(TAG, "Join RTC room success")
        } else {
            ConvoAiLogger.e(TAG, "Join RTC room failed, ret: $ret")
        }
    }

    private fun getToken(complete: (Boolean) -> Unit) {
        TokenGenerator.generateToken("",
            localUid.toString(),
            TokenGeneratorType.Token007,
            AgoraTokenType.Rtc,
            success = { token ->
                ConvoAiLogger.d(TAG, "getToken success $token")
                rtcToken = token
                complete.invoke(true)
            },
            failure = { e ->
                ConvoAiLogger.d(TAG, "getToken error $e")
                complete.invoke(false)
            })
    }

    private fun createRtcEngine() {
        val config = RtcEngineConfig()
        config.mContext = AgentApp.instance()
        config.mAppId = ServerConfig.rtcAppId
        config.mChannelProfile = Constants.CHANNEL_PROFILE_LIVE_BROADCASTING
        config.mAudioScenario = Constants.AUDIO_SCENARIO_CHORUS
        config.mEventHandler = object : IRtcEngineEventHandler() {
            override fun onError(err: Int) {
                super.onError(err)
                ConvoAiLogger.e(TAG, "Rtc Error code:$err, msg:" + RtcEngine.getErrorDescription(err))
            }

            override fun onJoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
                ConvoAiLogger.d(TAG, "local user didJoinChannel uid: $uid")
                updateNetworkStatus(1)
            }

            override fun onLeaveChannel(stats: RtcStats?) {
                ConvoAiLogger.d(TAG, "local user didLeaveChannel")
                runOnUiThread {
                    updateNetworkStatus(0)
                }
            }

            override fun onUserJoined(uid: Int, elapsed: Int) {
                runOnUiThread {
                    if (uid == agentUID) {
                        isAgentStarted = true
                        AgoraManager.agentStarted = true
                        loadingDialog?.dismiss()
                        Toast.makeText(
                            this@ConvoAiLivingActivity,
                            io.agora.scene.common.R.string.cov_detail_join_call_succeed,
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }
                ConvoAiLogger.d(TAG, "remote user didJoinedOfUid uid: $uid")
            }

            override fun onUserOffline(uid: Int, reason: Int) {
                ConvoAiLogger.d(TAG, "remote user onUserOffline uid: $uid")
                if (uid == agentUID) {
                    runOnUiThread {
                        ConvoAiLogger.d(TAG, "start agent reconnect")
                        rtcToken = null
                        // reconnect
                        loadingDialog?.setMessage(getString(io.agora.scene.common.R.string.cov_detail_agent_joining))
                        loadingDialog?.show()
                        val params = AgentRequestParams(
                            channelName = channelName,
                            remoteRtcUid = localUid,
                            agentRtcUid = agentUID,
                            ttsVoiceId = AgoraManager.voiceType.value
                        )
                        ConvAIManager.startAgent(params) { isAgentOK ->
                            if (!isAgentOK) {
                                loadingDialog?.dismiss()
                                Toast.makeText(
                                    this@ConvoAiLivingActivity,
                                    io.agora.scene.common.R.string.cov_detail_agent_leave,
                                    Toast.LENGTH_SHORT
                                ).show()
                                engine.leaveChannel()
                                isAgentStarted = false
                                AgoraManager.agentStarted = false
                                resetSceneState()
                            }
                        }
                    }
                }
            }

            override fun onAudioVolumeIndication(
                speakers: Array<out AudioVolumeInfo>?, totalVolume: Int
            ) {
                super.onAudioVolumeIndication(speakers, totalVolume)
                speakers?.forEach {
                    if (it.uid == agentUID) {
                        runOnUiThread {
                            mBinding?.recordingAnimationView?.startVolumeAnimation(it.volume)
                        }
                    }
                }
            }

            override fun onStreamMessage(uid: Int, streamId: Int, data: ByteArray?) {
                data?.let {
                    val rawString = String(it, Charsets.UTF_8)
//                    ConvoAiLogger.d(TAG, "onStreamMessage rawString: $rawString")
                    val message = parser.parseStreamMessage(rawString)
//                    ConvoAiLogger.d(TAG, "onStreamMessage message: $message")
                    message?.let { msg ->
                        handleStreamMessage(msg)
                    }
                }
            }

            override fun onNetworkQuality(uid: Int, txQuality: Int, rxQuality: Int) {
                ConvoAiLogger.d(TAG, "onNetworkQuality uid: $uid, txQuality: $txQuality, rxQuality: $rxQuality")
                if (uid == 0) {
                    runOnUiThread {
                        updateNetworkStatus(rxQuality)
                        networkDialog?.updateNetworkStatus(rxQuality)
                    }
                }
            }

            override fun onTokenPrivilegeWillExpire(token: String?) {
                ConvoAiLogger.d(TAG, "onTokenPrivilegeWillExpire")
                getToken { isOK ->
                    if (isOK) {
                        engine.renewToken(rtcToken)
                    } else {
                        onClickEndCall()
                    }
                }
            }
        }
        engine = (RtcEngine.create(config) as RtcEngineEx).apply {
            enableAudioVolumeIndication(100, 10, true)
            adjustRecordingSignalVolume(100)
        }
        AgoraManager.rtcEngine = engine
    }

    private fun handleStreamMessage(message: Map<String, Any>) {
        val isFinal = message["is_final"] as? Boolean ?: false
        val streamId = message["stream_id"] as? Double ?: 0.0
        val text = message["text"] as? String ?: ""
        if (text.isEmpty()) {
            return
        }
        runOnUiThread {
            mBinding?.messageListView?.updateStreamContent((streamId != 0.0), text, isFinal)
        }
    }

    private fun resetSceneState() {
        mBinding?.apply {
            messageListView.clearMessages()
            if (isShowMessageList) {
                isShowMessageList = false
                btnText.setBackgroundColor(Color.parseColor("#212121"))
            }
            if (isLocalAudioMuted) {
                isLocalAudioMuted = false
                engine.adjustRecordingSignalVolume(100)
                btnMic.setBackgroundResource(io.agora.scene.common.R.drawable.app_living_mic_on)
            }
        }

    }

    private fun updateCenterView() {
        if (!isAgentStarted) {
            mBinding?.apply {
                llCalling.visibility = View.INVISIBLE
                vNotJoined.root.visibility = View.VISIBLE
                llJoinCall.visibility = View.VISIBLE
                messageListView.visibility = View.INVISIBLE
                clAnimationContent.visibility = View.INVISIBLE
            }
            return
        }
        mBinding?.apply {
            llCalling.visibility = View.VISIBLE
            vNotJoined.root.visibility = View.INVISIBLE
            llJoinCall.visibility = View.INVISIBLE
            if (isShowMessageList) {
                messageListView.visibility = View.VISIBLE
                clAnimationContent.visibility = View.INVISIBLE
            } else {
                messageListView.visibility = View.INVISIBLE
                clAnimationContent.visibility = View.VISIBLE
            }
        }
    }

    private fun updateNetworkStatus(value: Int) {
        networkStatus = value
        mBinding?.apply {
            when (value) {
                1, 2 -> {
                    btnWifi.setImageResource(io.agora.scene.common.R.drawable.scene_detail_net_good)
                }

                3, 4 -> {
                    btnWifi.setImageResource(io.agora.scene.common.R.drawable.scene_detail_net_okay)
                }

                else -> {
                    btnWifi.setImageResource(io.agora.scene.common.R.drawable.scene_detail_net_poor)
                }
            }
        }

    }

    private fun setupView() {
        mBinding?.apply {
            btnBack.setOnClickListener {
                finish()
            }
            llEndCall.setOnClickListener {
                onClickEndCall()
            }
            btnMic.setOnClickListener {
                isLocalAudioMuted = !isLocalAudioMuted
                engine.adjustRecordingSignalVolume(if (isLocalAudioMuted) 0 else 100)
                btnMic.setBackgroundResource(
                    if (isLocalAudioMuted) io.agora.scene.common.R.drawable.app_living_mic_off else io.agora.scene.common.R.drawable.app_living_mic_on
                )
            }
            btnSettings.setOnClickListener {
                AgentSettingsSheetDialog().show(supportFragmentManager, "AgentSettingsSheetDialog")
            }
            btnText.setOnClickListener {
                isShowMessageList = !isShowMessageList
                btnText.setBackgroundColor(
                    if (isShowMessageList) Color.parseColor("#0097D4") else Color.parseColor(
                        "#212121"
                    )
                )
            }
            btnInfo.setOnClickListener {
                AgentInfoDialogFragment().apply {
                    isConnected = (networkStatus != 6)
                }.show(supportFragmentManager, "StatsDialog")
            }
            btnWifi.setOnClickListener {
                if (!AgoraManager.agentStarted) {
                    return@setOnClickListener
                }
                networkDialog = AgentNetworkDialogFragment().apply {
                    networkStatus?.let { updateNetworkStatus(it) }
                    show(supportFragmentManager, "NetworkDialog")
                    setOnDismissListener {
                        networkDialog = null
                    }
                }
            }
            llJoinCall.setOnClickListener {
                onClickStartAgent()
            }
        }
    }
}