//
//  RegistrationlViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/07/15.
//

import UIKit
import SwiftGifOrigin
import FirebaseAuth

/// 最初の画面
final class SignUpViewController: UIViewController {
    
    // MARK: - Properties
    
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    private var email: String = ""
    private var password: String = ""
    
    // MARK: - IBOutlets
    
    /// プレゼントGIF画像
    @IBOutlet private weak var presentGIFImageView: UIImageView!
    ///  Eメール
    @IBOutlet private weak var emailTextField: UITextField!
    /// パスワード
    @IBOutlet private weak var passwordTextField: UITextField!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentGIFImageView.loadGif(name: "present")
        configureBarButtonItems()
    }
    
    // MARK: - IBActions
    
    /// 登録ボタンをタップ
    @IBAction func RegistrationButtonTapped(_ sender: Any) {
    }
    
    // MARK: - Other Methods
    
    private func configureBarButtonItems() {
        // 左端のキャンセルボタン（アイコン）
        let cancelImage = UIImage(named: "cancel")
        let cancelButton = UIBarButtonItem(image: cancelImage,
                                           style: .plain,
                                           target: self,
                                           action: #selector(cancelButtonPressed(_:)))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
