//
//  ViewController.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/29.
//

import UIKit
import SnapKit
import AgoraRtcKit
import SVProgressHUD
import SwifterSwift
import Common

public class ChatViewController: UIViewController {
    private var isDenoise = true
    private let messageParser = MessageParser()
    private var remoteIsJoined = false
    private var channelName = ""
    private var token = ""
    private var agentUid = 0
    private var remoteAgentId = ""
    private let uid = "\(RtcEnum.getUid())"
    
    private lazy var timerCoordinator: AgentTimerCoordinator = {
        let coordinator = AgentTimerCoordinator()
        coordinator.delegate = self
        
        return coordinator
    }()

    private lazy var subRenderController: CovSubRenderController = {
        let renderCtrl = CovSubRenderController()
        return renderCtrl
    }()
    
    private lazy var rtcManager: RTCManager = {
        let manager = RTCManager(appId: AppContext.shared.appId, delegate: self)
        addLog("rtc sdk version: \(AgoraRtcEngineKit.getSdkVersion())")
        return manager
    }()
    
    private lazy var agentManager: AgentManager = {
        let manager = AgentManager(host: AppContext.shared.baseServerUrl)
        return manager
    }()
    
    private lazy var topBar: AgentSettingBar = {
        let view = AgentSettingBar()
        view.infoListButton.addTarget(self, action: #selector(onClickInformationButton), for: .touchUpInside)
        view.settingButton.addTarget(self, action: #selector(onClickSettingButton), for: .touchUpInside)
        view.centerTitleButton.addTarget(self, action: #selector(onClickLogo), for: .touchUpInside)
        return view
    }()

    private lazy var bottomBar: AgentControlToolbar = {
        let view = AgentControlToolbar()
        view.delegate = self
        return view
    }()
    
    private lazy var welcomeMessageView: TypewriterLabel = {
        let view = TypewriterLabel()
        view.font = UIFont.boldSystemFont(ofSize: 20)
        view.startAnimation()
        return view
    }()
    
    private lazy var animateContentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var animateView: AnimateView = {
        let view = AnimateView(videoView: animateContentView)
        view.delegate = self
        return view
    }()
    
    private let upperBackgroundView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let lowerBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill4")
        return view
    }()
    
    private lazy var toastView: ToastView = {
        let view = ToastView()
        view.isHidden = true
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.layerCornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var aiNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.text = ResourceManager.L10n.Conversation.agentName
        label.textAlignment = .center
        label.backgroundColor = UIColor(hex:0x000000, transparency: 0.25)
        return label
    }()
    
    private lazy var micStateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.ag_named("ic_agent_detail_mute"))
        return imageView
    }()
    
    private lazy var messageView: ChatView = {
        let view = ChatView()
        view.isHidden = true
        return view
    }()
    
    private lazy var devModeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_setting_debug"), for: .normal)
        button.addTarget(self, action: #selector(onClickDevMode), for: .touchUpInside)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressDevMode(_:)))
        button.addGestureRecognizer(longPressGesture)
        return button
    }()
    var clickCount = 0
    var lastClickTime: Date?
    
    deinit {
        print("liveing view controller deinit")
        deregisterDelegate()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        let isLogin = UserCenter.shared.isLogin()
        welcomeMessageView.isHidden = isLogin
        topBar.updateButtonVisible(isLogin)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true

        registerDelegate()
        preloadData()
        setupViews()
        setupConstraints()
        setupSomeNecessaryConfig()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // set gradient color from #23248399 to #242439
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = upperBackgroundView.bounds
        let startColor = UIColor(argbHexString: "#1D1D56") ?? .black
        let endColor = UIColor(argbHexString: "#242439") ?? .black
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        upperBackgroundView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func registerDelegate() {
        AppContext.loginManager()?.addDelegate(self)
    }
    
    private func deregisterDelegate() {
        AppContext.loginManager()?.removeDelegate(self)
    }
    
    private func preloadData() {
        let isLogin = UserCenter.shared.isLogin()
        if !isLogin {
            return
        }

        Task {
            do {
                try await fetchPresetsIfNeeded()
                try await fetchTokenIfNeeded()
            } catch {
                addLog("[PreloadData error]: \(error)")
            }
        }
    }
    
    private func showMicroPhonePermissionAlert() {
        let title = ResourceManager.L10n.Error.microphonePermissionTitle
        let description = ResourceManager.L10n.Error.microphonePermissionDescription
        let cancel = ResourceManager.L10n.Error.permissionCancel
        let confirm = ResourceManager.L10n.Error.permissionConfirm
        AgentAlertView.show(in: view, title: title, content: description, cancelTitle: cancel, confirmTitle: confirm, onConfirm: {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        [upperBackgroundView, lowerBackgroundView, animateContentView, topBar, contentView, welcomeMessageView, bottomBar, toastView, devModeButton].forEach { view.addSubview($0) }
        
        contentView.addSubview(aiNameLabel)
        view.addSubview(messageView)
    }
    
    private func setupConstraints() {
        topBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(5)
            make.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        
        animateContentView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalTo(0)
        }
        
        contentView.snp.makeConstraints { make in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.bottom.equalTo(bottomBar.snp.top).offset(-20)
        }
        
//        animateContentView.snp.makeConstraints { make in
//            make.height.equalTo(animateContentView.snp.width).multipliedBy(1080.0/1142.0)
//            make.width.equalTo(contentView.snp.width).multipliedBy(0.7)
//            make.centerX.equalTo(contentView)
//            make.centerY.equalTo(contentView)
//        }
        
        messageView.snp.makeConstraints { make in
            make.top.left.right.equalTo(0)
            make.bottom.equalTo(bottomBar.snp.top)
        }
        
        toastView.snp.makeConstraints { make in
            make.bottom.equalTo(bottomBar.snp.top).offset(-94)
            make.left.right.equalTo(0)
            make.height.equalTo(44)
        }
        
        bottomBar.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-30)
            make.left.right.equalTo(0)
            make.height.equalTo(76)
        }
        
        welcomeMessageView.snp.makeConstraints { make in
            make.left.equalTo(29)
            make.right.equalTo(-29)
            make.bottom.equalTo(bottomBar.snp.top).offset(-41)
        }
        
        devModeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(-20)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        upperBackgroundView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(animateContentView.snp.top)
        }
        
        lowerBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(animateContentView.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func setupSomeNecessaryConfig() {
        let rtcEngine = rtcManager.getRtcEntine()
        animateView.setupMediaPlayer(rtcEngine)
        animateView.updateAgentState(.idle)
        
        let subRenderConfig = SubRenderConfig(rtcEngine: rtcEngine, renderMode: nil, delegate: self)
        subRenderController.setupWithConfig(subRenderConfig)
        
        devModeButton.isHidden = !DeveloperModeViewController.getDeveloperMode()
    }

    
    @MainActor
    private func prepareToStartAgent() async {
        startLoading()
        
        do {
            try await fetchPresetsIfNeeded()
            try await fetchTokenIfNeeded()
            startCovSubRenderController()
            startAgentRequest()
            joinChannel()
        } catch {
            handleStartError()
        }
    }
    
    private func showErrorToast(text: String) {
        toastView.showToast(text: text)
    }
    
    private func dismissErrorToast() {
        toastView.dismiss()
    }
    
    private func startLoading() {
        bottomBar.style = .controlButtons
        toastView.showLoading()
    }
    
    private func stopLoading() {
        bottomBar.style = .startButton
        toastView.dismiss()
    }
    
    private func joinChannel() {
        addLog("[Call] joinChannel()")
        if channelName.isEmpty {
            addLog("cancel to join channel")
            return
        }
        let ret = rtcManager.joinChannel(token: token, channelName: channelName, uid: uid)
        addLog("Join channel: \(ret)")
        if (ret == 0) {
            self.addLog("Join success")
            self.setupMuteState(state: false)
            AppContext.preferenceManager()?.updateRoomState(.connected)
            AppContext.preferenceManager()?.updateRoomId(channelName)
        }else{
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.joinFailed + "\(ret)")
            stopLoading()
            stopAgent()
            AppContext.preferenceManager()?.updateRoomState(.disconnected)
            self.addLog("Join failed")
        }
    }
    
    private func leaveChannel() {
        addLog("[Call] leaveChannel()")
        channelName = ""
        rtcManager.leaveChannel()
    }
    
    private func destoryRtc() {
        leaveChannel()
        rtcManager.destroy()
    }
    
    private func stopAgent() {
        addLog("[Call] stopAgent()]")
        animateView.updateAgentState(.idle)
        messageView.clearMessages()
        messageView.isHidden = true
        bottomBar.resetState()
        timerCoordinator.stopAllTimer()
        stopCovSubRenderController()
        stopAgentRequest()
        leaveChannel()
        AppContext.preferenceManager()?.resetAgentInformation()
    }
        
    private func setupMuteState(state: Bool) {
        addLog("setupMuteState: \(state)")
        rtcManager.muteVoice(state: state)
    }
    
    private func addLog(_ txt: String) {
        VoiceAgentLogger.info(txt)
    }
    
    private func goToSSOViewController() {
        let ssoWebVC = SSOWebViewController()
        let baseUrl = AppContext.shared.baseServerUrl
        ssoWebVC.urlString = "\(baseUrl)/v1/convoai/sso/login"
        ssoWebVC.completionHandler = { [weak self] token in
            guard let self = self else { return }
            if let token = token {
                self.addLog("SSO token: \(token)")
                let model = LoginModel()
                model.token = token
                AppContext.loginManager()?.updateUserInfo(userInfo: model)
                self.bottomBar.startLoadingAnimation()
                LoginApiService.getUserInfo { [weak self] error in
                    self?.bottomBar.stopLoadingAnimation()                    
                    if let err = error {
                        AppContext.loginManager()?.logout()
                        SVProgressHUD.showInfo(withStatus: err.localizedDescription)
                    }
                }
            }
        }
        self.navigationController?.pushViewController(ssoWebVC, animated: false)
    }
}

// MARK: - Agent Request
extension ChatViewController {
    private func fetchPresetsIfNeeded() async throws {
        guard AppContext.preferenceManager()?.allPresets() == nil else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            agentManager.fetchAgentPresets(appId: AppContext.shared.appId) { error, result in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result else {
                    continuation.resume(throwing: NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "result is empty"]))
                    return
                }
                
                AppContext.preferenceManager()?.setPresets(presets: result)
                continuation.resume()
            }
        }
    }
    
    private func fetchTokenIfNeeded() async throws {
        guard token.isEmpty else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            NetworkManager.shared.generateToken(
                channelName: "",
                uid: uid,
                types: [.rtc]
            ) { [weak self] token in
                guard let self = self else { return }
                
                if let token = token {
                    print("rtc token is : \(token)")
                    self.token = token
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "generate token error"]))
                }
            }
        }
    }
    
    private func handleStartError() {
        stopLoading()
        stopAgent()
        SVProgressHUD.showError(withStatus: ResourceManager.L10n.Error.joinError)
    }
    
    private func startCovSubRenderController() {
        subRenderController.start()
    }
    
    private func stopCovSubRenderController() {
        subRenderController.stop()
    }
    
    private func startAgentRequest() {
        addLog("[Call] startAgentRequest()")
        guard let manager = AppContext.preferenceManager() else {
            addLog("preference manager is nil")
            return
        }
        manager.updateAgentState(.disconnected)
        let aiVad = manager.preference.aiVad
        let bhvs = manager.preference.bhvs
        let presetName = manager.preference.preset?.name ?? ""
        let language = manager.preference.language?.languageCode ?? ""
        channelName = RtcEnum.getChannel()
        agentUid = AppContext.agentUid
        remoteIsJoined = false
        agentManager.startAgent(appId: AppContext.shared.appId,
                                uid: uid,
                                agentUid: "\(agentUid)",
                                channelName: channelName,
                                aiVad: aiVad,
                                bhvs: bhvs,
                                presetName: presetName,
                                language: language) { [weak self] error, channelName, remoteAgentId, targetServer in
            guard let self = self else { return }
            if self.channelName != channelName {
                self.addLog("channelName is different, current : \(self.channelName), before: \(channelName)")
                return
            }
            
            guard let error = error else {
                if let remoteAgentId = remoteAgentId,
                     let targetServer = targetServer {
                    self.remoteAgentId = remoteAgentId
                    AppContext.preferenceManager()?.updateAgentId(remoteAgentId)
                    AppContext.preferenceManager()?.updateUserId(self.uid)
                    AppContext.preferenceManager()?.updateTargetServer(targetServer)
                }
                addLog("start agent success, agent id is: \(self.remoteAgentId)")
                self.timerCoordinator.startPingTimer()
                self.timerCoordinator.startJoinChannelTimer()
                return
            }
            if (error.code == 1412) {
                SVProgressHUD.showError(withStatus: ResourceManager.L10n.Error.resouceLimit)
            } else {
                SVProgressHUD.showError(withStatus: ResourceManager.L10n.Error.joinError)
                self.stopLoading()
                self.stopAgent()
                addLog("start agent failed : \(error.message)")
            }            
        }
    }
    
    private func startPingRequest() {
        addLog("[Call] startPingRequest()")
        let presetName = AppContext.preferenceManager()?.preference.preset?.name ?? ""
        agentManager.ping(appId: AppContext.shared.appId, channelName: channelName, presetName: presetName) { [weak self] err, res in
            guard let self = self else { return }
            guard let error = err else {
                self.addLog("ping request")
                return
            }
            
            self.addLog("ping error : \(error.message)")
        }
    }
    
    private func stopAgentRequest() {
        guard let preset = AppContext.preferenceManager()?.preference.preset else {
            return
        }
        
        if remoteAgentId.isEmpty {
            return
        }
        agentManager.stopAgent(appId: AppContext.shared.appId, agentId: remoteAgentId, channelName: channelName, presetName: preset.name) { _, _ in }
    }
}

// MARK: - AgoraRtcEngineDelegate
extension ChatViewController: AgoraRtcEngineDelegate {
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        addLog("[RTC Call Back] engine didOccurError: \(errorCode.rawValue)")
        SVProgressHUD.dismiss()
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        addLog("[RTC Call Back] didLeaveChannelWith : \(stats)")
        print("didLeaveChannelWith")
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        addLog("[RTC Call Back] connectionChangedToState: \(state), reason: \(reason)")
        if reason == .reasonInterrupted {
            animateView.updateAgentState(.idle)
            AppContext.preferenceManager()?.updateAgentState(.disconnected)
            AppContext.preferenceManager()?.updateRoomState(.disconnected)
            showErrorToast(text: ResourceManager.L10n.Error.networkDisconnected)
        } else if reason == .reasonRejoinSuccess {
            guard let manager = AppContext.preferenceManager() else {
                dismissErrorToast()
                return
            }
            
            if manager.information.rtcRoomState == .connected {
                return
            }
            
            manager.updateAgentState(.connected)
            manager.updateRoomState(.connected)
            
            dismissErrorToast()
        } else if reason == .reasonLeaveChannel {
            dismissErrorToast()
            AppContext.preferenceManager()?.resetAgentInformation()
        }
        
        if state == .failed {
            showErrorToast(text: ResourceManager.L10n.Error.roomError)
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        addLog("[RTC Call Back] didJoinChannel uid: \(uid)")
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        toastView.dismiss()
        remoteIsJoined = true
        timerCoordinator.startUsageDurationLimitTimer()
        addLog("[RTC Call Back] didJoinedOfUid uid: \(uid)")
        AppContext.preferenceManager()?.updateAgentState(.connected)
        SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.agentJoined)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.userSpeakToast)
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        addLog("[RTC Call Back] didOfflineOfUid uid: \(uid)")
        animateView.updateAgentState(.idle)
        AppContext.preferenceManager()?.updateAgentState(.disconnected)
        showErrorToast(text: ResourceManager.L10n.Conversation.agentLeave)
        remoteIsJoined = false
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
        self.token = ""
        addLog("[RTC Call Back] tokenPrivilegeWillExpire")
        NetworkManager.shared.generateToken(
            channelName: "",
            uid: uid,
            types: [.rtc]
        ) { [weak self] token in
            self?.addLog("regenerate token is: \(token ?? "")")
            guard let self = self, let newToken = token else {
                return
            }
            self.addLog("will update token: \(newToken)")
            let rtcEnigne = self.rtcManager.getRtcEntine()
            rtcEnigne.renewToken(newToken)
            self.token = newToken
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        if AppContext.preferenceManager()?.information.agentState == .unload { return }
        addLog("[RTC Call Back] networkQuality: \(rxQuality)")
        AppContext.preferenceManager()?.updateNetworkState(NetworkStatus(agoraQuality: rxQuality))
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        speakers.forEach { info in
            if (info.uid == agentUid) {
                var currentVolume: CGFloat = 0
                currentVolume = CGFloat(info.volume)
                if currentVolume > 0 {
                    animateView.updateAgentState(.speaking, volume: Int(currentVolume))
                } else {
                    animateView.updateAgentState(.listening, volume: Int(currentVolume))
                }
            } else if (info.uid == 0) {
                bottomBar.setVolumeProgress(value: Float(info.volume))
            }
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, remoteAudioStateChangedOfUid uid: UInt, state: AgoraAudioRemoteState, reason: AgoraAudioRemoteReason, elapsed: Int) {
        addLog("[RTC Call Back] remoteAudioStateChangedOfUid")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if uid == self.agentUid, state == .stopped {
                animateView.updateAgentState(.listening)
            }
        }
    }
}

// MARK: - Actions
private extension ChatViewController {
    private func clickTheBackButton() {
        addLog("[Call] clickTheBackButton()")
        stopAgent()
        animateView.releaseView()
        AppContext.destory()
        destoryRtc()
        UIApplication.shared.isIdleTimerDisabled = false
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func onClickInformationButton() {
        AgentInformationViewController.show(in: self, rtcManager: rtcManager)
    }
    
    @objc private func onClickSettingButton() {
        let settingVC = AgentSettingViewController()
        settingVC.modalPresentationStyle = .overFullScreen
        settingVC.agentManager = agentManager
        present(settingVC, animated: false)
    }
    
    private func clickTheCloseButton() {
        addLog("[Call] clickTheCloseButton()")
        if AppContext.preferenceManager()?.information.agentState == .connected {
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.endCallLeave)
        }
        stopLoading()
        stopAgent()
    }
    
    private func clickTheStartButton() async {
        addLog("[Call] clickTheStartButton()")
        let loginState = UserCenter.shared.isLogin()

        if loginState {
            await MainActor.run {
                let needsShowMicrophonePermissionAlert = PermissionManager.getMicrophonePermission() == .denied
                if needsShowMicrophonePermissionAlert {
                    self.bottomBar.setMircophoneButtonSelectState(state: true)
                }
            }
            
            PermissionManager.checkMicrophonePermission { res in
                Task {
                    await self.prepareToStartAgent()
                    await MainActor.run {
                        if !res {
                            self.bottomBar.setMircophoneButtonSelectState(state: true)
                        }
                    }
                }
            }
            
            return
        }
        
        await MainActor.run {
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .overFullScreen
            loginVC.loginAction = { [weak self] in
                self?.goToSSOViewController()
            }
            self.present(loginVC, animated: false)
        }
    }
    
    private func clickCaptionsButton(state: Bool) {
        messageView.isHidden = !state
    }
    
    private func clickMuteButton(state: Bool) -> Bool{
        if state {
            let needsShowMicrophonePermissionAlert = PermissionManager.getMicrophonePermission() == .denied
            if needsShowMicrophonePermissionAlert {
                showMicroPhonePermissionAlert()
                let selectedState = true
                return selectedState
            } else {
                let selectedState = !state
                setupMuteState(state: selectedState)
                return selectedState
            }
        } else {
            let selectedState = !state
            setupMuteState(state: selectedState)
            return selectedState
        }
    }
    
    @objc private func onClickDevMode() {
        DeveloperModeViewController.show(
            from: self,
            audioDump: rtcManager.getAudioDump(),
            serverHost: AppContext.preferenceManager()?.information.targetServer ?? "") 
        {
            self.devModeButton.isHidden = true
        } onAudioDump: { isOn in
            self.rtcManager.enableAudioDump(enabled: isOn)
        } onSwitchServer: {
            self.clickTheBackButton()
        } onCopy: {
            let messageContents = self.messageView.getAllMessages()
                .filter { $0.isMine }
                .map { $0.content }
                .joined(separator: "\n")
            let pasteboard = UIPasteboard.general
            pasteboard.string = messageContents
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.DevMode.copy)
        }
    }
    
    @objc private func onLongPressDevMode(_ sender: UILongPressGestureRecognizer) {
        if DeveloperModeViewController.getDeveloperMode() {
            devModeButton.isHidden = true
            DeveloperModeViewController.setDeveloperMode(false)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    @objc private func onClickLogo(_ sender: UIButton) {
        let currentTime = Date()
        if let lastTime = lastClickTime, currentTime.timeIntervalSince(lastTime) > 1.0 {
            clickCount = 0
        }
        lastClickTime = currentTime
        clickCount += 1
        if clickCount >= 5 {
            onThresholdReached()
            clickCount = 0
        }
    }
    
    func onThresholdReached() {
        if !DeveloperModeViewController.getDeveloperMode() {
            devModeButton.isHidden = false
            DeveloperModeViewController.setDeveloperMode(true)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - AgentControlToolbarDelegate
extension ChatViewController: AgentControlToolbarDelegate {
    func hangUp() {
        clickTheCloseButton()
    }
    
    func getStart() async {
        await clickTheStartButton()
    }
    
    func mute(selectedState: Bool) -> Bool{
        return clickMuteButton(state: selectedState)
    }
    
    func switchCaptions(selectedState: Bool) {
        clickCaptionsButton(state: selectedState)
    }
}

extension ChatViewController: AnimateViewDelegate {
    func onError(error: AgentError) {
        VoiceAgentLogger.info(error.message)
        
        stopLoading()
        stopAgent()
    }
}

extension ChatViewController: CovSubRenderDelegate {
    func onUpdateTextMessageContent(subtitle: SubtitleMessage, timestamp: Int64) {
        messageView.viewModel.reduceIndependentMessage(message: subtitle.text, timestamp: timestamp, owner: subtitle.isMe ? .me : .agent, isFinished: subtitle.status == .end)
    }
    
    func onUpdateStreamContent(subtitle: SubtitleMessage) {
        messageView.viewModel.reduceStandardMessage(turnId: subtitle.turnId, message: subtitle.text, timestamp: 0, owner: subtitle.isMe ? .me : .agent, isInterrupted: subtitle.status == .interrupt)
    }
}

extension ChatViewController: AgentTimerCoordinatorDelegate {
    func agentUseLimitedTimerClosed() {
        addLog("[Call] agentUseLimitedTimerClosed")
        topBar.stop()
    }
    
    func agentUseLimitedTimerStarted(duration: Int) {
        addLog("[Call] agentUseLimitedTimerStarted")
        topBar.startWithRestTime(duration)
    }
    
    func agentUseLimitedTimerUpdated(duration: Int) {
        addLog("[Call] agentUseLimitedTimerUpdated")
        topBar.updateRestTime(duration)
    }
    
    func agentUseLimitedTimerEnd() {
        addLog("[Call] agentUseLimitedTimerEnd")
        topBar.stop()
        stopLoading()
        stopAgent()
        let title = ResourceManager.L10n.ChannelInfo.timeLimitdAlertTitle
        if let manager = AppContext.preferenceManager(), let preset = manager.preference.preset {
            let min = preset.callTimeLimitSecond / 60
            TimeoutAlertView.show(in: view, title: title, description: String(format: ResourceManager.L10n.ChannelInfo.timeLimitdAlertDescription, min))
        }
    }
    
    func agentStartPing() {
        addLog("[Call] agentStartPing()")
        self.startPingRequest()
    }
    
    func agentNotJoinedWithinTheScheduledTime() {
        addLog("[Call] agentNotJoinedWithinTheScheduledTime")
        guard let manager = AppContext.preferenceManager() else {
            addLog("view controller or manager is release, will stop join channel scheduled timer")
            timerCoordinator.stopJoinChannelTimer()
            return
        }
        
        if self.remoteIsJoined {
            timerCoordinator.stopJoinChannelTimer()
            self.addLog("agent is joined in 10 seconds")
            return
        }
        
        if manager.information.agentState != .connected {
            addLog("agent is not joined in 10 seconds")
            self.stopLoading()
            self.stopAgent()
        }
        
        timerCoordinator.stopJoinChannelTimer()
    }
    
}

extension ChatViewController: LoginManagerDelegate {
    func loginManager(_ manager: LoginManager, userInfoDidChange userInfo: LoginModel?, loginState: Bool) {
        welcomeMessageView.isHidden = loginState
        topBar.updateButtonVisible(loginState)
        if !loginState {
            stopLoading()
            stopAgent()
        }
    }
    
    func userLoginSessionExpired() {
        welcomeMessageView.isHidden = false
        topBar.updateButtonVisible(false)
        stopLoading()
        stopAgent()
        
        SVProgressHUD.showError(withStatus: ResourceManager.L10n.Login.sessionExpired)
    }
}

