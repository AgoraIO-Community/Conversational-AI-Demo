//
//  IOTDeviceCell.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/5.
//

import UIKit
import Common

class IOTDeviceCell: UITableViewCell {
    var onTitleTapped: (() -> Void)?
    var onSettingsTapped: (() -> Void)?

    lazy var deviceCardView: IotDeviceCardView = {
        let view = IotDeviceCardView()
        view.backgroundImage = UIImage.ag_named("ic_iot_card_bg_green")
        view.settingsButtonBackgroundColor = UIColor.themColor(named: "ai_brand_white8")
        view.titleColor = UIColor.themColor(named: "ai_brand_black10")
        view.subtitleColor = UIColor.themColor(named: "ai_brand_black10")
        view.showEditIcon = true
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.onSettingsTapped = onSettingsTapped
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(deviceCardView)
    }
    
    func setupConstraints() {
        deviceCardView.snp.makeConstraints { make in
            make.left.equalTo(25)
            make.right.equalTo(-25)
            make.top.equalTo(10)
            make.height.equalTo(160)
            make.bottom.equalTo(-10)
        }
    }
    
    func configData(device: LocalDevice, index: Int) {
        deviceCardView.configure(title: device.name, subtitle: "SN \(device.deviceId)")
        deviceCardView.backgroundImage = index % 2 == 0 ? UIImage.ag_named("ic_iot_card_bg_green") : UIImage.ag_named("ic_iot_card_bg_blue")
        
        deviceCardView.onTitleButtonTapped = { [weak self] in
            self?.onTitleTapped?()
        }
        
        deviceCardView.onSettingsTapped = { [weak self] in
            self?.onSettingsTapped?()
        }
    }
}

