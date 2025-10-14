//
//  CharactersInformationView.swift
//  ConvoAI
//
//  Created by qinhui on 2025/8/6.
//

import Foundation
import Common
import Kingfisher

class CharactersInformationView: UIView {
    private lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    public lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.themColor(named: "ai_brand_white6").cgColor
        
        return imageView
    }()
    
    public lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.themColor(named: "ai_brand_white10")
        label.font = .systemFont(ofSize: 10, weight: .medium)
        return label
    }()
    
    public lazy var phoneLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.themColor(named: "ai_brand_white10")
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(containerView)
        containerView.addSubview(stackView)
        
        [avatarImageView, nameLabel, phoneLabel].forEach { stackView.addArrangedSubview($0) }
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(32)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalTo(0)
            make.left.equalTo(6)
            make.right.equalTo(-6)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
    }
    
    func configure(icon: String, defaultIcon: String, name: String) {
        avatarImageView.kf.setImage(with: URL(string: icon), placeholder: UIImage.ag_named(defaultIcon))
        nameLabel.text = name
    }
    
    // MARK: - Public Methods
    
    func showNameLabel(animated: Bool = true) {
        guard animated else {
            nameLabel.isHidden = false
            phoneLabel.isHidden = true
            return
        }
        
        guard !phoneLabel.isHidden else { return }
        
        nameLabel.isHidden = false
        nameLabel.transform = CGAffineTransform(translationX: 0, y: -20)
        nameLabel.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.phoneLabel.transform = CGAffineTransform(translationX: 0, y: 20)
            self.phoneLabel.alpha = 0
            
            self.nameLabel.transform = .identity
            self.nameLabel.alpha = 1
        }) { _ in
            self.phoneLabel.isHidden = true
            self.phoneLabel.transform = .identity
            self.phoneLabel.alpha = 1
        }
    }
    
    func showPhoneLabel(animated: Bool = true) {
        guard animated else {
            nameLabel.isHidden = true
            phoneLabel.isHidden = false
            return
        }
        
        guard !nameLabel.isHidden else { return }
        
        phoneLabel.isHidden = false
        phoneLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        phoneLabel.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.nameLabel.transform = CGAffineTransform(translationX: 0, y: -20)
            self.nameLabel.alpha = 0
            
            self.phoneLabel.transform = .identity
            self.phoneLabel.alpha = 1
        }) { _ in
            self.nameLabel.isHidden = true
            self.nameLabel.transform = .identity
            self.nameLabel.alpha = 1
        }
    }
}
