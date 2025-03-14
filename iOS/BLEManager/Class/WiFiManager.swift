//
//  WiFiManager.swift
//  DistributionTool
//
//  Created by LiaoChenliang on 2025/3/4.
//

import Foundation
import CoreLocation
import SystemConfiguration.CaptiveNetwork

public class WiFiManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var completion: ((String?) -> Void)?
    
    // 添加日志记录
    private var logMessages: [String] = []

    override public init() {
        super.init()
        locationManager.delegate = self
    }

    private func _log(_ info: String) {
        logMessages.append(info)
        print("WiFiManager: \(info)")
    }

    /// 请求位置权限
    func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            _log("请求位置权限")
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            _log("用户拒绝或限制了位置服务权限，请在设置中开启")
            // 可以在这里提示用户手动去设置中开启权限
        case .authorizedWhenInUse, .authorizedAlways:
            _log("已授权使用位置服务")
            // 在这里可以进行获取 Wi-Fi SSID 的操作
        @unknown default:
            _log("未知的授权状态")
            break
        }
    }

    /// 获取当前连接的WiFi SSID
    /// - Parameter completion: 回调，返回SSID或nil（如果获取失败）
    public func getWiFiSSID(completion: @escaping (String?) -> Void) {
        self.completion = completion
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            _log("位置权限未确定，请求权限")
            requestLocationPermission()
        case .restricted, .denied:
            _log("未授权使用位置服务，无法获取 Wi-Fi SSID")
            completion(nil)
        case .authorizedWhenInUse, .authorizedAlways:
            if #available(iOS 14.0, *) {
                if locationManager.accuracyAuthorization == .reducedAccuracy {
                    _log("未开启精确位置服务，无法获取 Wi-Fi SSID")
                    completion(nil)
                } else {
                    _log("开始获取WiFi SSID")
                    fetchWiFiSSID()
                }
            } else {
                _log("开始获取WiFi SSID")
                fetchWiFiSSID()
            }
        @unknown default:
            _log("未知的授权状态，无法获取WiFi SSID")
            completion(nil)
        }
    }

    /// 获取WiFi SSID的具体实现
    private func fetchWiFiSSID() {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceName = interface as? String,
                   let info = CNCopyCurrentNetworkInfo(interfaceName as CFString) as NSDictionary? {
                    if let ssid = info["SSID"] as? String {
                        _log("成功获取WiFi SSID: \(ssid)")
                        completion?(ssid)
                        return
                    }
                }
            }
        }
        _log("无法获取WiFi SSID")
        completion?(nil)
    }

    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        _log("位置权限状态变更: \(status.rawValue)")
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if #available(iOS 14.0, *) {
                if locationManager.accuracyAuthorization == .reducedAccuracy {
                    _log("未开启精确位置服务，无法获取 Wi-Fi SSID")
                    completion?(nil)
                } else {
                    fetchWiFiSSID()
                }
            } else {
                fetchWiFiSSID()
            }
        default:
            _log("未授权使用位置服务，无法获取 Wi-Fi SSID")
            completion?(nil)
        }
    }

    @available(iOS 14.0, *)
    public func locationManager(_ manager: CLLocationManager, didChangeAccuracyAuthorization accuracyAuthorization: CLAccuracyAuthorization) {
        _log("位置精度授权变更: \(accuracyAuthorization.rawValue)")
        if accuracyAuthorization == .reducedAccuracy {
            _log("未开启精确位置服务，无法获取 Wi-Fi SSID")
            completion?(nil)
        } else {
            fetchWiFiSSID()
        }
    }
    
    /// 获取WiFi管理器的日志记录
    public func getLogs() -> [String] {
        return logMessages
    }
}
