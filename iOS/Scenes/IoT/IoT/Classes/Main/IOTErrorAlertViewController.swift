//
//  IOTErrorAlertViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/6.
//

import UIKit
import Common

class IOTErrorAlertViewController: UIViewController {
    
    // MARK: - Properties
    
    private var onRetryButtonTapped: (() -> Void)?
    private var onCloseButtonTapped: (() -> Void)?

    private let bannerTitles = [
        ResourceManager.L10n.Iot.errorCheckWifi,
        ResourceManager.L10n.Iot.errorCheckPairingMode,
        ResourceManager.L10n.Iot.errorCheckRouter
    ]
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill2")
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_iot_close_icon"), for: .normal)
        button.backgroundColor = UIColor.themColor(named: "ai_fill2")
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.errorAlertTitle
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Iot.errorAlertSubtitle
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var scrollView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: "BannerCell")
        return collectionView
    }()
    
    private let bannerImages = [
        UIImage.ag_named("ic_iot_error_banner1"),
        UIImage.ag_named("ic_iot_error_banner2"),
        UIImage.ag_named("ic_iot_error_banner3")
    ]
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.themColor(named: "ai_line2")
        pageControl.currentPageIndicatorTintColor = UIColor.themColor(named: "ai_brand_main6")
        return pageControl
    }()
    
    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Iot.deviceSearchFailedRetry, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor.themColor(named: "ai_brand_main6")
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    
    init(onRetry: (() -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.onRetryButtonTapped = onRetry
        self.onCloseButtonTapped = onClose
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    // MARK: - UI Setup
    
    private func setupViews() {
        containerView.backgroundColor = UIColor.themColor(named: "ai_fill1")
        
        view.addSubview(containerView)
        [closeButton, titleLabel, subtitleLabel, scrollView, pageControl, retryButton].forEach {
            containerView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.right.equalTo(-16)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(56)
            make.left.right.equalToSuperview().inset(20)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.height.equalTo(scrollView.snp.width).multipliedBy(203.0/315.0)
        }
        
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
        
        retryButton.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(30)
            make.height.equalTo(50)
            make.bottom.equalTo(-56)
        }
    }
    
    // MARK: - Animations
    
    private func animateIn() {
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        view.backgroundColor = .clear
        
        UIView.animate(withDuration: 0.3) {
            self.containerView.transform = .identity
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            self.view.backgroundColor = .clear
        }) { _ in
            completion()
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
            self?.onCloseButtonTapped?()
        }
    }
    
    @objc private func retryButtonTapped() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
            self?.onRetryButtonTapped?()
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension IOTErrorAlertViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bannerImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BannerCell", for: indexPath) as! BannerCell
        cell.imageView.image = bannerImages[indexPath.item]
        cell.titleLabel.text = bannerTitles[indexPath.item]
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        pageControl.currentPage = currentPage
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension IOTErrorAlertViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}

// MARK: - BannerCell
private class BannerCell: UICollectionViewCell {
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        [imageView, titleLabel].forEach { contentView.addSubview($0) }
        
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(contentView.snp.width).multipliedBy(170.0/315.0)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(0)
            make.top.equalTo(imageView.snp.bottom).offset(12)
        }
    }
}
