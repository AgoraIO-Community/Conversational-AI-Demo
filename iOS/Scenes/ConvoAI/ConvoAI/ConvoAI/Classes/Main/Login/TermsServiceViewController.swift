//
//  TermsServicViewController.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/25.
//

import UIKit
import WebKit
import Common

class TermsServiceWebViewController: UIViewController {
    var url: String = ""
    
    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        return webView
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = UIColor(named: "#0097d4")
        return progress
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        loadWebContent()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: 0x111111)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = .clear
        
        let backButton = UIButton(type: .custom)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: -18, bottom: 0, trailing: 0)
            config.image = UIImage.ag_named("ic_agora_back")
            backButton.configuration = config
        } else {
            backButton.setImage(UIImage.ag_named("ic_agora_back"), for: .normal)
            backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -18, bottom: 0, right: 0)
        }
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.title = ResourceManager.L10n.Join.title
        
        view.addSubview(webView)
        view.addSubview(progressView)
        
        webView.addObserver(self,
                           forKeyPath: "estimatedProgress",
                           options: .new,
                           context: nil)
    }
    
    @objc private func backButtonTapped() {
        self.dismiss(animated: true)
    }
    
    private func setupConstraints() {
        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
        
        webView.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func loadWebContent() {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey : Any]?,
                             context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress >= 1
        }
    }
}

// MARK: - WKNavigationDelegate
extension TermsServiceWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.isHidden = true
        if let title = webView.title {
            self.title = title
        }
        
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
    }
}
