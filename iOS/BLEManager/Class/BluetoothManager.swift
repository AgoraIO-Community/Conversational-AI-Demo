//
//  BluetoothConnection.swift
//  DistributionTool
//
//  Created by LiaoChenliang on 2025/3/3.
//

import CoreBluetooth

public class BLEDevice: NSObject {
    public let id: UUID
    public let name: String
    public let rssi: Int
    public let data: [String: Any]
    public init(id: UUID, name: String, rssi: Int, data: [String: Any]) {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.data = data
    }
}

private extension CBUUID {
    static let AI_SERVICE_UUID = CBUUID(string: "0000fa00-0000-1000-8000-00805f9b34fb")
    static let AI_NOTIFICATION_UUID = CBUUID(string: "0000ea01-0000-1000-8000-00805f9b34fb")
    static let AI_OPERATION_UUID = CBUUID(string: "0000ea02-0000-1000-8000-00805f9b34fb")
    static let AI_SSID_UUID = CBUUID(string: "0000ea05-0000-1000-8000-00805f9b34fb")
    static let AI_PASSWORD_UUID = CBUUID(string: "0000ea06-0000-1000-8000-00805f9b34fb")
    static let AI_DESCRIPTOR_UUID = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")
    static let AI_AUTHTOKEN1_UUID = CBUUID(string: "0000ea07-0000-1000-8000-00805f9b34fb")
    static let AI_AUTHTOKEN2_UUID = CBUUID(string: "0000ea08-0000-1000-8000-00805f9b34fb")
    static let AI_URL_UUID = CBUUID(string: "0000ea09-0000-1000-8000-00805f9b34fb")
}

public enum BLEOpCode {
    public static let WifiStationStart = 1
    public static let OpGetDeviceId = 60000
    public static let DefaultPreState = -1000
    public static let MaxTokenLength = 500
}

public class BLENetworkConfigInfo: NSObject {
    public let ssid: String
    public let password: String
    public let url: String
    public let authToken: String
    public init(ssid: String,
                password: String,
                url: String,
                authToken: String) {
        self.ssid = ssid
        self.password = password
        self.url = url
        self.authToken = authToken
    }
}

public enum BLEManagerError: Error {
    case bleNotAvailable
    case connectDeviceNotFound
    case deviceConnectFailed
    case deviceDisconnected
    case writeTimeout
    case custom(String)
}

extension BLEManagerError: CustomNSError {
    public static var errorDomain: String { "com.beken.iot" }

    public var errorCode: Int {
        switch self {
        case .bleNotAvailable: return 100
        case .connectDeviceNotFound: return 101
        case .deviceConnectFailed: return 102
        case .deviceDisconnected: return 103
        case .writeTimeout: return 104
        case .custom: return 99
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case .bleNotAvailable:
            return [NSLocalizedDescriptionKey: "蓝牙不可用，请检查系统蓝牙功能是否开启、App蓝牙权限是否已授权"]
        case .connectDeviceNotFound:
            return [NSLocalizedDescriptionKey: "查找不到设备，请重试"]
        case .deviceConnectFailed:
            return [NSLocalizedDescriptionKey: "连接设备失败，请重试"]
        case .deviceDisconnected:
            return [NSLocalizedDescriptionKey: "设备已断开连接"]
        case .writeTimeout:
            return [NSLocalizedDescriptionKey: "写入超时"]
        case let .custom(err):
            return [NSLocalizedDescriptionKey: err]
        }
    }
}

public protocol BLEManagerDelegate {
    func bleManagerDidUpdateState(_ manager: AIBLEManager, isPowerOn: Bool)
    func bleManagerDidScanDevice(_ manager: AIBLEManager, device: BLEDevice, error: Error?)
    func bleManagerOnDevicConfigError(manager: AIBLEManager, error: Error)
    func bleManagerOnDevicConfigStateChanged(manager: AIBLEManager, oldState: AIBLEManager.DeviceConfigState, newState: AIBLEManager.DeviceConfigState)
    func bleManagerOnLastLogInfo(manager: AIBLEManager, logInfo: String)
    func bleManagerOnLastProgress(manager: AIBLEManager, progress: CGFloat)
    func bleManagerdidUpdateNotification(manager: AIBLEManager, opcode: Int, statusCode: UInt, payload: Data)
}

public extension BLEManagerDelegate {
    func bleManagerDidUpdateState(_ manager: AIBLEManager, isPowerOn: Bool) {}
    func bleManagerDidScanDevice(_ manager: AIBLEManager, device: BLEDevice, error: Error?) {}
    func bleManagerOnDevicConfigError(manager: AIBLEManager, error: Error) {}
    func bleManagerOnDevicConfigStateChanged(manager: AIBLEManager, oldState: AIBLEManager.DeviceConfigState, newState: AIBLEManager.DeviceConfigState) {}
    func bleManagerOnLastLogInfo(manager: AIBLEManager, logInfo: String) {}
    func bleManagerOnLastProgress(manager: AIBLEManager, progress: CGFloat) {}
    func bleManagerdidUpdateNotification(manager: AIBLEManager, opcode: Int, statusCode: UInt, payload: Data) {}
}

public class AIBLEManager: NSObject {
    public static let shared = AIBLEManager()

    public var deviceConnectTimeout: TimeInterval = 60 // 设备连接超时时间
    public var writeValueTimeout: TimeInterval = 10 // 写入特征值超时时间

    @objc public enum DeviceConfigState: Int {
        case none = 0
        case readyToScanDevices // 可以扫描设备了
        case deviceConnecting // 连接设备
        case deviceConnected // 设备连接成功
        case readyToConfigWifi // 可以开始发送wifi数据了
        case wifiConfiguration // wifi信息配置中
        case wifiConfigurationDone // wifi配置、连接成功
    }

    fileprivate enum WifiConfigState: Int {
        case none = 0
        case ssid
        case password
        case authTokenFront
        case authTokenBack
        case url
        case wifiConnect
    }

    private var curPeripheral: CBPeripheral?
    private var curService: CBService? { curPeripheral?.services?.filter { $0.uuid == .AI_SERVICE_UUID }.first }

    private var lastState: CBManagerState = .unknown
    private var deviceConfigState: DeviceConfigState = .none
    private var wifiInfo: BLENetworkConfigInfo?

    private(set) var logInfo = ""

    private var wifiConfigState: WifiConfigState = .none {
        didSet {
            switch wifiConfigState {
            case .ssid: _log("发送wifi ssid")
            case .password: _log("发送wifi password ")
            case .authTokenFront: _log("发送auth token front")
            case .authTokenBack: _log("发送auth token back")
            case .url: _log("发送 url config")
            case .wifiConnect: _log("发送连接wifi指令")
            default: break
            }
        }
    }

    // beken设备标识
    public lazy var bekenDeviceManufacturerData: Data = {
        let bytes: [UInt8] = [240, 5]
        let data = Data(bytes: bytes, count: 2)
        return data
    }()

    private lazy var centralManager: CBCentralManager = {
        let manager = CBCentralManager(delegate: self, queue: nil)
        return manager
    }()

    private var timer: Timer?
    private var curTimeoutCountdown: TimeInterval = 0

    private var writeTimer: Timer?
    private var currentWriteOperation: String?

    public var delegate: BLEManagerDelegate?
    public var isBLEAvailable: Bool { lastState == .poweredOn }

    private var deviceIdCompletion: ((String?) -> Void)?

    override public init() {
        super.init()
        // let _ = centralManager.state
    }

    private func _log(_ info: String) {
        logInfo = info
        print("info  - \(info)")
        delegate?.bleManagerOnLastLogInfo(manager: self, logInfo: info)
    }

    // 开始扫描设备
    public func startScan() {
        let _ = centralManager.state
        if lastState == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            _log("开始扫描设备")
        } else {
            // onConfigError(.bleNotAvailable)
        }
    }

    public func getDeviceId(completion: @escaping (String?) -> Void) {
        // Store the completion handler to be called when we receive the device ID
        deviceIdCompletion = completion
        sendOperation(opcode: BLEOpCode.OpGetDeviceId, data: nil)
    }

    // 停止扫描设备
    public func stopScan() {
        centralManager.stopScan()
        _log("停止扫描设备")
    }

    // 开始设备配网流程
    @discardableResult public func connect(_ device: BLEDevice) -> Bool {
        guard deviceConfigState.rawValue < DeviceConfigState.deviceConnecting.rawValue else {
            return false
        }
        stopScan()
        startConnect(device)
        _log("开始对\(device.name)进行配网")
        return true
    }

    // 断开设备连接
    @discardableResult public func disconnect(_ device: BLEDevice) -> Bool {
        disConnectDevice()
        _log("和 \(device.name) 断开连接")
        return true
    }

    // 发送wifi数据
    public func sendWifiInfo(_ info: BLENetworkConfigInfo) {
        guard deviceConfigState == .readyToConfigWifi else {
            return
        }
        wifiInfo = info
        updateState(.wifiConfiguration)
        _log("开始发送wifi数据")
        doWifiConfigurationStep(.ssid)
    }

    // 发送自定义数据
    public func send(info: String, uuid: CBUUID) {
        if let cs = findCharacteristic(uuid: uuid),
           let data = info.data(using: .utf8) {
            writeValueWithTimeout(data: data, for: cs, type: .withResponse, operationName: "发送自定义数据")
        } else {
            onConfigFailed(with: .custom("发送data错误: 数据错误"))
        }
    }

    public func dispose() {
        disConnectDevice()
        updateState(.none, forceUpdate: true)
        curPeripheral = nil
        wifiConfigState = .none
        wifiInfo = nil
        stopTimer()
        clearWriteTimer()
        
        // Clear any pending completion handlers
        deviceIdCompletion = nil
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        curTimeoutCountdown = 0
    }

    private func clearWriteTimer() {
        writeTimer?.invalidate()
        writeTimer = nil
        currentWriteOperation = nil
    }
}

extension AIBLEManager {
    private func getCurrentStateTimeoutInterval() -> TimeInterval {
        if deviceConfigState == .deviceConnecting {
            return deviceConnectTimeout
        }
        return 0
    }

    private func getCurrentTimeoutError() -> BLEManagerError {
        if deviceConfigState == .deviceConnecting {
            return .custom("与设备连接超时，请检查设备和蓝牙状态。")
        }
        return .custom("")
    }

    private func startTimeoutCountdown() {
        curTimeoutCountdown = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.timeoutCheck()
        })
    }

    private func timeoutCheck() {
        let totalInterval = getCurrentStateTimeoutInterval()
        curTimeoutCountdown += 1
        if curTimeoutCountdown > totalInterval {
            // 超时
            onConfigFailed(with: getCurrentTimeoutError())
        }
    }

    private func onProgress(_ progress: CGFloat) {
        delegate?.bleManagerOnLastProgress(manager: self, progress: progress)
    }
}

extension AIBLEManager {
    // 与设备断开连接
    private func disConnectDevice() {
        if let peripheral = curPeripheral {
            _log("开始与设备断开连接")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    private func onDiscoverDevice(_ device: BLEDevice) {
        delegate?.bleManagerDidScanDevice(self, device: device, error: nil)
    }

    private func doWifiConfigurationStep(_ step: WifiConfigState) {
        guard step.rawValue > wifiConfigState.rawValue else {
            return
        }
        wifiConfigState = step
        switch wifiConfigState {
        case .ssid: sendSSID()
        case .password: sendPassword()
        case .authTokenFront: sendAuthTokenFront()
        case .authTokenBack: sendAuthTokenBack()
        case .url: sendURLConfig()
        case .wifiConnect: sendOperation(opcode: BLEOpCode.WifiStationStart, data: nil)
        default: break
        }
    }
}

extension AIBLEManager {
    private func onConfigError(_ error: BLEManagerError) {
        delegate?.bleManagerOnDevicConfigError(manager: self, error: error)
    }

    private func startConnect(_ device: BLEDevice) {
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [device.id])
        if peripherals.isEmpty {
            onConfigFailed(with: .connectDeviceNotFound)
            return
        }
        updateState(.deviceConnecting)
        curPeripheral = peripherals.first!
        curPeripheral?.delegate = self
        centralManager.connect(curPeripheral!, options: nil)
        _log("开始连接设备")
        onProgress(0.1)
    }

    private func updateState(_ newState: DeviceConfigState, forceUpdate: Bool = false) {
        let oldState = deviceConfigState
        if !forceUpdate, newState.rawValue < oldState.rawValue {
            return
        }
        deviceConfigState = newState
        delegate?.bleManagerOnDevicConfigStateChanged(manager: self, oldState: oldState, newState: newState)
        if newState == .deviceConnecting {
            startTimeoutCountdown()
        } else if newState == .deviceConnected {
            stopTimer()
        }
    }

    private func onConfigFailed(with error: BLEManagerError) {
        onConfigError(error)
        dispose()
    }
}

extension AIBLEManager {
    private func findCharacteristic(uuid: CBUUID) -> CBCharacteristic? {
        if let cs = curService?.characteristics, !cs.isEmpty {
            for character in cs {
                if character.uuid == uuid {
                    return character
                }
            }
        }
        return nil
    }

    private func writeValueWithTimeout(data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType, operationName: String) {
        // 取消之前的计时器
        writeTimer?.invalidate()
        
        // 记录当前操作
        currentWriteOperation = operationName
        
        // 设置超时计时器
        writeTimer = Timer.scheduledTimer(withTimeInterval: writeValueTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // 超时处理
            self.writeTimer?.invalidate()
            self.writeTimer = nil
            
            if let operation = self.currentWriteOperation {
                self.onConfigFailed(with: .writeTimeout)
            }
        }
        
        // 执行写入操作
        curPeripheral?.writeValue(data, for: characteristic, type: type)
    }

    private func sendSSID() {
        if let cs = findCharacteristic(uuid: .AI_SSID_UUID),
           let ssid = wifiInfo?.ssid,
           let data = ssid.data(using: .utf8) {
            writeValueWithTimeout(data: data, for: cs, type: .withResponse, operationName: "发送SSID")
        } else {
            onConfigFailed(with: .custom("发送ssid错误: 数据错误"))
        }
    }

    private func sendPassword() {
        if let cs = findCharacteristic(uuid: .AI_PASSWORD_UUID),
           let password = wifiInfo?.password {
            if let data = password.data(using: .utf8) {
                writeValueWithTimeout(data: data, for: cs, type: .withResponse, operationName: "发送密码")
            } else {
                onConfigFailed(with: .custom("发送password错误: 数据编码错误"))
            }
        } else {
            onConfigFailed(with: .custom("发送password错误: 特征值或密码获取失败"))
        }
    }

    private func sendAuthTokenFront() {
        if let cs = findCharacteristic(uuid: .AI_AUTHTOKEN1_UUID),
           let password = wifiInfo?.authToken {
            let halfLength = password.count / 2
            let frontPart = String(password.prefix(halfLength))
            if let data = frontPart.data(using: .utf8) {
                writeValueWithTimeout(data: data, for: cs, type: .withResponse, operationName: "发送Token前半段")
            } else {
                onConfigFailed(with: .custom("发送authToken前半段错误: 数据编码错误"))
            }
        } else {
            onConfigFailed(with: .custom("发送authToken前半段错误: 特征值或authToken获取失败"))
        }
    }

    private func sendAuthTokenBack() {
        if let cs = findCharacteristic(uuid: .AI_AUTHTOKEN2_UUID),
           let password = wifiInfo?.authToken {
            let halfLength = password.count / 2
            let backPart = String(password.suffix(from: password.index(password.startIndex, offsetBy: halfLength)))
            if let data = backPart.data(using: .utf8) {
                writeValueWithTimeout(data: data, for: cs, type: .withResponse, operationName: "发送Token后半段")
            } else {
                onConfigFailed(with: .custom("发送authToken后半段错误: 数据编码错误"))
            }
        } else {
            onConfigFailed(with: .custom("发送authToken后半段错误: 特征值或authToken获取失败"))
        }
    }

    private func sendURLConfig() {
        if let cs = findCharacteristic(uuid: .AI_URL_UUID),
           let url = wifiInfo?.url {
            if let data = url.data(using: .utf8) {
                writeValueWithTimeout(data: data, for: cs, type: .withResponse, operationName: "发送URL")
            } else {
                onConfigFailed(with: .custom("发送URL错误: 数据编码错误"))
            }
        } else {
            onConfigFailed(with: .custom("发送URL错误: 特征值或URL获取失败"))
        }
    }

    private func sendOperation(opcode: Int, data: Data?) {
        guard let characteristic = findCharacteristic(uuid: .AI_OPERATION_UUID) else {
            return
        }

        let payload: [UInt8]? = [0]

        var length = 0
        if payload != nil, !payload!.isEmpty {
            length = payload!.count
        }

        let totalLegnth = length + 4

        var value: [UInt8] = Array(repeating: 0, count: totalLegnth)

        value[0] = UInt8(opcode & 0xFF)
        value[1] = UInt8(opcode >> 8)

        if length > 0 {
            value[2] = UInt8(length & 0xFF)
            value[3] = UInt8(length >> 8)
            value.replaceSubrange(4 ..< 4 + length, with: payload!.prefix(length))
        } else {
            value[2] = UInt8(0)
            value[3] = UInt8(0)
        }

        let operationName = opcode == BLEOpCode.WifiStationStart ? "发送WiFi连接指令" : 
                           (opcode == BLEOpCode.OpGetDeviceId ? "获取设备ID" : "发送操作指令")
        
        writeValueWithTimeout(data: Data(bytes: value, count: totalLegnth), for: characteristic, type: .withResponse, operationName: operationName)
    }
}

// MARK: - CBCentralManagerDelegate

extension AIBLEManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        lastState = central.state
        if central.state == .poweredOn, deviceConfigState == .none {
            updateState(.readyToScanDevices)
        }
        delegate?.bleManagerDidUpdateState(self, isPowerOn: central.state == .poweredOn)
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // 处理扫描到的蓝牙设备
        /*
         if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
             if bekenDeviceManufacturerData == data {

             }
         }
         */
//        print(peripheral.name ?? "--")
//        print(advertisementData)

        let name = peripheral.name ?? "--"
        let rssiInt: Int = RSSI.intValue
        let id = peripheral.identifier
        let device = BLEDevice(id: id, name: name, rssi: rssiInt, data: advertisementData)
        onDiscoverDevice(device)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if deviceConfigState == .deviceConnecting {
            stopScan()
            updateState(.deviceConnected)
            onProgress(0.2)
            curPeripheral?.discoverServices(nil)
        }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if deviceConfigState.rawValue < DeviceConfigState.wifiConfigurationDone.rawValue {
            onConfigFailed(with: .deviceConnectFailed)
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if deviceConfigState.rawValue > DeviceConfigState.deviceConnected.rawValue,
           deviceConfigState.rawValue < DeviceConfigState.wifiConfigurationDone.rawValue {
            onConfigFailed(with: .deviceDisconnected)
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: Error?) {
        if let err = error {
            _log("didDisconnectPeripheral error: \(err)")
        } else {
            _log("与「\(peripheral.name ?? "")」断开连接")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension AIBLEManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services where service.uuid == .AI_SERVICE_UUID {
                curPeripheral?.discoverCharacteristics(nil, for: service)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let cs = service.characteristics, !cs.isEmpty {
            for character in cs {
                if character.uuid == .AI_NOTIFICATION_UUID {
                    curPeripheral?.setNotifyValue(true, for: character)
                    break
                }
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // 处理特征通知状态的变化
        if let error {
            onConfigFailed(with: .custom(error.localizedDescription))
        } else {
            if characteristic.uuid == .AI_NOTIFICATION_UUID {
                updateState(.readyToConfigWifi)
                onProgress(0.3)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == .AI_NOTIFICATION_UUID {
            guard let data = characteristic.value else {
                return
            }

            var payload: [UInt8]?
            var statusCode: UInt = 0
            var length = 0

            // 解析操作码
            let opcodeByte1 = Int(data[0])
            let opcodeByte2 = Int(data[1])
            let opcode = opcodeByte1 | (opcodeByte2 << 8)

            statusCode = UInt(data[2])
            length = Int(data[3] | data[4] << 8)

            if length != data.count - 5 {
                return
            } else {
                payload = Array(repeating: 0, count: length)
                payload!.replaceSubrange(0 ..< length, with: data[5 ..< 5 + length])
            }

            if statusCode == 0 {
                notificationDataHandle(opcode: opcode, statusCode: statusCode, payload: Data(bytes: payload!, count: length))
            } else {
                onConfigFailed(with: .custom("op error: \(opcode) statusCode: \(statusCode)"))
                if opcode == BLEOpCode.OpGetDeviceId {
                    deviceIdCompletion?(nil)
                    deviceIdCompletion = nil
                }
            }
        }
    }

    private func notificationDataHandle(opcode: Int, statusCode: UInt, payload: Data) {
        let payloadString = String(data: payload, encoding: .utf8) ?? ""

        if opcode == BLEOpCode.WifiStationStart {
            // 清除写入超时计时器
            clearWriteTimer()
            onProgress(1.0)
            updateState(.wifiConfigurationDone)
            _log("配网成功!")
        } else if opcode == BLEOpCode.OpGetDeviceId {
            deviceIdCompletion?(payloadString)
            deviceIdCompletion = nil
        }
        delegate?.bleManagerdidUpdateNotification(manager: self, opcode: opcode, statusCode: statusCode, payload: payload)
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            onConfigFailed(with: .custom(error.localizedDescription))
        } else {
            if characteristic.uuid == .AI_SSID_UUID {
                doWifiConfigurationStep(.password)
                onProgress(0.4)
            } else if characteristic.uuid == .AI_PASSWORD_UUID {
                doWifiConfigurationStep(.authTokenFront)
                onProgress(0.5)
            } else if characteristic.uuid == .AI_AUTHTOKEN1_UUID {
                doWifiConfigurationStep(.authTokenBack)
                onProgress(0.6)
            } else if characteristic.uuid == .AI_AUTHTOKEN2_UUID {
                doWifiConfigurationStep(.url)
                onProgress(0.7)
            } else if characteristic.uuid == .AI_URL_UUID {
                doWifiConfigurationStep(.wifiConnect)
                onProgress(0.8)
            }
        }
    }
}
