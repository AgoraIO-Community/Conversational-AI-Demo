//
//  SearchResultCell.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/6.
//

import UIKit
import Common
import BLEManager

class SearchResultCell: UITableViewCell {
    var tapCallback: (() -> Void)?
    
    private lazy var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage.ag_named("ic_iot_mascot_small_icon")
        return view
    }()
    
    private lazy var titleView: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(bgView)
        
        [iconView, titleView].forEach {
            bgView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        bgView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(5)
            make.bottom.equalTo(-5)
        }
        
        iconView.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(50)
        }
        
        titleView.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(19)
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
    }
    
    func configData(device: BLEDevice) {
        titleView.text = device.name
    }
    
    // Use system highlight state callbacks
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.bgView.backgroundColor = highlighted ?
            UIColor.themColor(named: "ai_click_app") :
            UIColor.themColor(named: "ai_fill1")
    }
}
