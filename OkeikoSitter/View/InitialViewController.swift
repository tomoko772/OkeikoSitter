//
//  InitialViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/07/15.
//

import UIKit
import SwiftGifOrigin

/// 最初の画面
final class InitialViewController: UIViewController {

    // MARK: - IBOutlets
    
    /// プレゼントGIF画像
    @IBOutlet private weak var presentGIFImageView: UIImageView!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentGIFImageView.loadGif(name: "present")
    }

    // MARK: - IBActions
   
    /// ログインボタンをタップ
    @IBAction private func loginButtonTapped(_ sender: Any) {
    }
    
    /// 新規アカウント登録ボタンをタップ
    @IBAction private func signUpButtonTapped(_ sender: Any) {
    }
    
}
