//
//  LoginViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/07/15.
//

import UIKit
import SwiftGifOrigin

/// ログイン画面
final class LoginViewController: UIViewController {
    
    // MARK: - Properties

    
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
    
    /// パスワードを忘れた場合ボタンをタップ
    @IBAction private func forgotPasswordButtonTapped(_ sender: Any) {
    }
    /// ログインボタンをタップ
    @IBAction private func loginButtonTapped(_ sender: Any) {
    }
    /// 新規アカウント登録ボタンをタップ
    @IBAction private func signUPButtonTapped(_ sender: Any) {
        let signUpVC = SignUpViewController()
        let navController = UINavigationController(rootViewController: signUpVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
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
