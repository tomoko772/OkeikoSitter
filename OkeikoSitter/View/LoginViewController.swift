//
//  LoginViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/07/15.
//

import UIKit
import SwiftGifOrigin
import FirebaseAuth

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
    @IBAction private func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Emailアドレスとパスワードが空です")
            return
        }
        signIn(email: email, password: password)
    }
    
    /// 新規アカウント登録ボタンをタップ
    @IBAction private func signUPButtonTapped(_ sender: Any) {
        let signUpVC = SignUpViewController()
        let navController = UINavigationController(rootViewController: signUpVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }
    
    // MARK: - Other Methods
    
    /// サインイン（ログイン）をする
    private func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                switch error.code {
                case AuthErrorCode.wrongPassword.rawValue:
                    self.showAlert(message: "パスワードが間違っています。")
                case AuthErrorCode.invalidEmail.rawValue:
                    self.showAlert(message: "無効なメールアドレスです。")
                case AuthErrorCode.userNotFound.rawValue:
                    self.showAlert(message: "ユーザーが見つかりません。")
                default:
                    self.showAlert(message: "ログインに失敗しました。")
                }
                return
            }
            // ログイン成功
            print("User signed in successfully")
            // メイン画面に遷移
            self.navigateToMain()
        }
    }
    
    /// メイン画面へ遷移
    private func navigateToMain() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainViewController")
        let navController = UINavigationController(rootViewController: vc)
        // SceneDelegateのwindowを取得
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = navController
            window.makeKeyAndVisible()
            
            // トランジションをアニメーションで
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.3
            window.layer.add(transition, forKey: kCATransition)
        }
    }
    
    /// アラートを表示
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
    
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
