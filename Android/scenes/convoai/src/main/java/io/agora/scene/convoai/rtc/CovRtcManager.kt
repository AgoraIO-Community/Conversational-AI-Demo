package io.agora.scene.convoai.rtc

import io.agora.mediaplayer.IMediaPlayer
import io.agora.rtc2.ChannelMediaOptions
import io.agora.rtc2.Constants
import io.agora.rtc2.Constants.CLIENT_ROLE_BROADCASTER
import io.agora.rtc2.Constants.ERR_OK
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.RtcEngineConfig
import io.agora.rtc2.RtcEngineEx
import io.agora.scene.common.AgentApp
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.convoai.CovLogger

object CovRtcManager {

    private val TAG = "CovAgoraManager"

    private var rtcEngine: RtcEngineEx? = null

    fun createRtcEngine(rtcCallback: IRtcEngineEventHandler): RtcEngineEx {
        val config = RtcEngineConfig()
        config.mContext = AgentApp.instance()
        config.mAppId = ServerConfig.rtcAppId
        config.mChannelProfile = Constants.CHANNEL_PROFILE_LIVE_BROADCASTING
        config.mAudioScenario = Constants.AUDIO_SCENARIO_AI_CLIENT
        config.mEventHandler = rtcCallback
        try {
            rtcEngine = (RtcEngine.create(config) as RtcEngineEx).apply {
                loadExtensionProvider("ai_echo_cancellation_extension")
                loadExtensionProvider("ai_echo_cancellation_ll_extension")
                loadExtensionProvider("ai_noise_suppression_extension")
                loadExtensionProvider("ai_noise_suppression_ll_extension")


            }
            rtcEngine?.
        } catch (e: Exception) {
            CovLogger.e(TAG, "createRtcEngine error: $e")
        }
        CovLogger.d(TAG, "current sdk version: ${RtcEngine.getSdkVersion()}")
        return rtcEngine!!
    }

    private var mediaPlayer: IMediaPlayer? = null

    fun createMediaPlayer(): IMediaPlayer {
        try {
            mediaPlayer = rtcEngine?.createMediaPlayer()!!
        } catch (e: Exception) {
            CovLogger.e(TAG, "createMediaPlayer error: $e")
        }
        return mediaPlayer!!
    }

    fun joinChannel(rtcToken: String, channelName: String, uid: Int) {
        CovLogger.d(TAG, "onClickStartAgent channelName: $channelName, localUid: $uid")
        setAudioConfig()
        val options = ChannelMediaOptions()
        options.clientRoleType = CLIENT_ROLE_BROADCASTER
        options.publishMicrophoneTrack = true
        options.publishCameraTrack = false
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = false
        val ret = rtcEngine?.joinChannel(rtcToken, channelName, uid, options)
        rtcEngine?.enableAudioVolumeIndication(100, 3, true)
        CovLogger.d(TAG, "Joining RTC channel: $channelName, uid: $uid")
        if (ret == ERR_OK) {
            CovLogger.d(TAG, "Join RTC room success")
        } else {
            CovLogger.e(TAG, "Join RTC room failed, ret: $ret")
        }
    }

    private fun setAudioConfig() {
        rtcEngine?.apply {
            //set audio scenario 10，open AI-QoS
            setAudioScenario(Constants.AUDIO_SCENARIO_AI_CLIENT)
            setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
            setParameters("{\"che.audio.sf.enabled\":true}")
            setParameters("{\"che.audio.sf.delayMode\":2}")
            setParameters("{\"che.audio.sf.procChainMode\":1}")
            setParameters("{\"che.audio.sf.nlpDynamicMode\":1}")
            setParameters("{\"che.audio.sf.nlpAlgRoute\":1}")
            setParameters("{\"che.audio.sf.ainlpToLoadFlag\":1}")
            setParameters("{\"che.audio.sf.ainlpModelPref\":10}")
            setParameters("{\"che.audio.sf.nsngAlgRoute\":12}")
            setParameters("{\"che.audio.sf.ainsToLoadFlag\":1}")
            setParameters("{\"che.audio.sf.ainsModelPref\":10}")
            setParameters("{\"che.audio.sf.nsngPredefAgg\":11}")
            setParameters("{\"che.audio.agc.enable\":false}")

            // audio predump default enable
            setParameters("{\"che.audio.enable.predump\":{\"enable\":\"true\",\"duration\":\"60\"}}")
        }
    }

    fun leaveChannel() {
        rtcEngine?.leaveChannel()
    }

    fun renewRtcToken(value: String) {
        val engine = rtcEngine ?: return
        engine.renewToken(value)
    }

    fun muteLocalAudio(mute: Boolean) {
        rtcEngine?.adjustRecordingSignalVolume(if (mute) 0 else 100)
    }

    fun onAudioDump(enable: Boolean) {
        if (enable) {
//            rtcEngine?.setParameters("{\"che.audio.apm_dump\": true}")
        } else {
//            rtcEngine?.setParameters("{\"che.audio.apm_dump\": false}")
        }
    }

    fun generatePredumpFile() {
        rtcEngine?.setParameters("{\"che.audio.start.predump\": true}")
    }

    fun resetData() {
        rtcEngine = null
        mediaPlayer = null
        RtcEngine.destroy()
    }
}