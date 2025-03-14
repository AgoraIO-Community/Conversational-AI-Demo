//
//  IOTListViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/4.
//

import UIKit
import SVProgressHUD
import Common

class IOTListViewController: BaseViewController {
    // MARK: - Properties
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(IOTDeviceCell.self, forCellReuseIdentifier: "IOTDeviceCell")
        tableView.estimatedRowHeight = 160
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    private lazy var emptyView: EmptyDeviceView = {
        let view = EmptyDeviceView()
        view.isHidden = true
        view.onAddDeviceButtonTapped = { [weak self] in
            let vc = DeviceIntroductionViewController()
            self?.navigationController?.pushViewController(vc)
        }
        return view
    }()
    
    private lazy var devices: [LocalDevice] = {
        var data = AppContext.iotDeviceManager()?.getAllDevices() ?? []
        data.reverse()
        return data
    }()
    
    // MARK: - Lifecycle
    deinit {
        unregisterDelegage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        registerDelegate()
    }
    
    // MARK: - Private Methods
    
    private func registerDelegate() {
        AppContext.iotDeviceManager()?.addDelegate(self)
    }
    
    private func unregisterDelegage() {
        AppContext.iotDeviceManager()?.removeDelegate(self)
    }
    
    private func setupViews() {
        navigationTitle = ResourceManager.L10n.Iot.title
        naviBar.setRightButtonTarget(self, action: #selector(navigationRightButtonTapped), image: UIImage.ag_named("ic_iot_bar_add_icon"))
        
        view.addSubview(tableView)
        view.addSubview(emptyView)
        
        updateViewsVisibility()
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func updateViewsVisibility() {
        let isEmpty = devices.isEmpty
        
        tableView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
        
        // Update navigation bar right button
        if isEmpty {
            naviBar.rightItems = nil  // This will remove the right button
        } else {
            naviBar.setRightButtonTarget(self, 
                                       action: #selector(navigationRightButtonTapped), 
                                       image: UIImage.ag_named("ic_iot_bar_add_icon"))
        }
    }
    
    private func addDevice(device: LocalDevice) {
        // Insert at the beginning of the array
        devices.insert(device, at: 0)
        
        tableView.reloadData()
        
        // Show a success message
        SVProgressHUD.showSuccess(withStatus: ResourceManager.L10n.Iot.deviceAddSuccessTitle)
        
        updateViewsVisibility()
    }
    
    // MARK: - Actions
    override func navigationRightButtonTapped() {
        let vc = DeviceIntroductionViewController()
        self.navigationController?.pushViewController(vc)
    }
    
    @objc private func addDeviceButtonTapped() {
        let vc = DeviceIntroductionViewController()
        self.navigationController?.pushViewController(vc)
    }
    
    private func showRenameAlert(for device: LocalDevice) {
        IOTTextFieldAlertViewController.show(in: self) { text in
            AppContext.iotDeviceManager()?.updateDeviceName(name: text, deviceId: device.deviceId)
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension IOTListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IOTDeviceCell", for: indexPath) as! IOTDeviceCell
        let index = indexPath.row
        let device = devices[index]
        cell.selectionStyle = .none
        cell.configData(device: device, index: index)
        cell.onTitleTapped = { [weak self] in
            self?.showRenameAlert(for: device)
        }
        
        cell.onSettingsTapped = { [weak self] in
            let settingsVC = IOTSettingViewController()
            settingsVC.deviceId = device.deviceId
            self?.present(settingsVC, animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension IOTListViewController: IOTDeviceManagerDelegate {
    func deviceManager(_ manager: IOTDeviceManager, didAddDevice device: LocalDevice) {
        addDevice(device: device)
    }
    
    func deviceManager(_ manager: IOTDeviceManager, didUpdateName name: String, forDevice deviceId: String) {
        if let index = devices.firstIndex(where: { $0.deviceId == deviceId }) {
            var device = devices[index]
            device.name = name
            
            devices[index] = device
            tableView.reloadData()
            SVProgressHUD.showSuccess(withStatus: ResourceManager.L10n.Iot.deviceRenameSucceed)
        }
    }
    
    func deviceManager(_ manager: IOTDeviceManager, didRemoveDevice deviceId: String) {
        if let index = devices.firstIndex(where: { $0.deviceId == deviceId }) {
            devices.remove(at: index)
            tableView.reloadData()
            updateViewsVisibility()
        }
    }
}
