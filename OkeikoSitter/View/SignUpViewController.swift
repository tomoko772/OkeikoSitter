//
//  RegistrationlViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/07/15.
//

import UIKit
import SwiftGifOrigin
import FirebaseAuth
import FirebaseFirestore

/// 新規アカウント登録の画面
final class SignUpViewController: UIViewController {
    
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
        configureTapGesture()
    }
    
    // MARK: - IBActions
    
    /// 登録ボタンをタップ
    @IBAction private func registrationButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Emailアドレスとパスワードが空です")
            return
        }
        
        signUp(email: email, password: password)
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
    
    /// サインアップをする
    private func signUp(email: String, password: String) {
        guard password.count >= 6 else {
            showAlert(message: "パスワードは6文字以上で入力してください")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                switch AuthErrorCode(rawValue: error.code) {
                case .emailAlreadyInUse:
                    self.showAlert(message: "すでに登録されているメールアドレスです")
                case .invalidEmail:
                    self.showAlert(message: "メールアドレスの形式が正しくありません")
                case .weakPassword:
                    self.showAlert(message: "パスワードが弱すぎます")
                default:
                    self.showAlert(message: "登録に失敗しました")
                }
                return
            }
            // サインアップ成功 → Firestore に保存
            guard let user = authResult?.user else {
                self.showAlert(message: "ユーザー情報の取得に失敗しました")
                return
            }
            
            self.registerUserInfo(user: user)
        }
    }
    
    /// Firebaseにユーザー情報を登録
    private func registerUserInfo(user: FirebaseAuth.User) {
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                print("Firestoreへの保存失敗: \(error.localizedDescription)")
                self.showAlert(message: "ユーザーデータの保存に失敗しました")
            } else {
                print("Firestoreにユーザー情報を保存しました")
                self.navigateToMain()
            }
        }
    }
    
    /// メイン 画面へ遷移
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
    
    /// 画面をタップする設定
    private func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false   // ボタンなどのタップイベントも有効にしたい場合はfalse
        view.addGestureRecognizer(tapGesture)
    }
    
    /// キーボードを閉じる
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
