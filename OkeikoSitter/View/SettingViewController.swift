//
//  SettingViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/05/21.
//

import UIKit
import FirebaseAuth

/// 設定画面
final class SettingViewController: UIViewController {
    
    // MARK: - Properties
    
    private let defaultText = "ポイントを選択してください"
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    private var challengePoint: Int?
    private var bonusPoint: Int?
    private var goalPoint: Int?
    private var challengeDay: Int?
    
    // MARK: - IBOutlets
    
    /// ユーザー画像
    @IBOutlet private weak var userImageView: UIImageView!
    /// ユーザー名テキストフィールド
    @IBOutlet private weak var userNameTextField: UITextField!
    /// チャレンジ内容テキストビュー
    @IBOutlet private weak var challengeTaskTextView: UITextView!
    /// プレースホルダーラベル
    @IBOutlet private weak var placeholderLabel: UILabel!
    /// もらえるポイント数ラベル
    @IBOutlet private weak var challengePointLabel: UILabel!
    /// もらえるポイント数ボタン
    @IBOutlet private weak var challengePointMenuButton: PressableButton!
    /// ボーナスポイント数ラベル
    @IBOutlet private weak var bonusPointLabel: UILabel!
    /// ボーナスポイント数ボタン
    @IBOutlet private weak var bonusPointMenuButton: PressableButton!
    /// 目標ポイント数ラベル
    @IBOutlet private weak var goalPointLabel: UILabel!
    /// 目標ポイント数ボタン
    @IBOutlet private weak var goalPointMenuButton: PressableButton!
    /// チャレンジ日数
    @IBOutlet private weak var challengeDaysLabel: UILabel!
    /// チャレンジ日数ボタン
    @IBOutlet private weak var challengeDaysMenuButton: PressableButton!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        configureChallengePointMenuButton()
        configureBonusPointMenuButton()
        configureGoalPointMenuButton()
        configureChallengeDaysMenuButton()
        challengeTaskTextView.delegate = self
        placeholderLabel.isHidden = !challengeTaskTextView.text.isEmpty
    }
    
    // MARK: - IBActions
    
    /// ご褒美登録ボタンをタップした
    @IBAction private func presentRegisterButtonTapped(_sender: UIButton) {
        let presentVC = PresentViewController()
        let navController = UINavigationController(rootViewController: presentVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }
    
    /// 完了ボタンをタップした
    @IBAction private func doneButtonTapped(_ sender: UIButton) {
        saveData()
    }
    
    /// ログアウトボタンをタップした
    @IBAction private func logoutButtonTapped(_ sender: UIButton) {
        showLogoutAlert()
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
        
        // 右端の削除ボタン（アイコン）
        let deleteImage = UIImage(named: "delete")
        let deleteButton = UIBarButtonItem(image: deleteImage,
                                           style: .plain,
                                           target: self,
                                           action: #selector(deleteButtonPressed(_:)))
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func deleteButtonPressed(_ sender: UIBarButtonItem) {
        print("ユーザーが削除されます")
    }
    
    private func configureChallengePointMenuButton() {
        challengePointLabel.text = defaultText
        let challengePointMenu = UIMenu(title: "", children: [
            UIAction(title: "1") { _ in
                self.challengePoint = 1
                self.challengePointLabel.text = "\(1)ポイント"
            },
            UIAction(title: "2") { _ in
                self.challengePoint = 2
                self.challengePointLabel.text = "\(2)ポイント"
            },
            UIAction(title: "3") { _ in
                self.challengePoint = 3
                self.challengePointLabel.text = "\(3)ポイント"
            }
        ])
        challengePointMenuButton.menu = challengePointMenu
        challengePointMenuButton.showsMenuAsPrimaryAction = true
    }
    
    private func configureBonusPointMenuButton() {
        bonusPointLabel.text = defaultText
        let bonusPointMenu = UIMenu(title: "", children: [
            UIAction(title: "3") { _ in
                self.bonusPoint = 3
                self.bonusPointLabel.text = "\(3)ポイント"
            },
            UIAction(title: "5") { _ in
                self.bonusPoint = 5
                self.bonusPointLabel.text = "\(5)ポイント"
            },
            UIAction(title: "10") { _ in
                self.bonusPoint = 10
                self.bonusPointLabel.text = "\(10)ポイント"
            }
        ])
        bonusPointMenuButton.menu = bonusPointMenu
        bonusPointMenuButton.showsMenuAsPrimaryAction = true
    }
    
    private func configureGoalPointMenuButton() {
        goalPointLabel.text = defaultText
        let goalPointMenu = UIMenu(title: "", children: [
            UIAction(title: "30") { _ in
                self.goalPoint = 30
                self.goalPointLabel.text = "\(30)ポイント"
            },
            UIAction(title: "50") { _ in
                self.goalPoint = 50
                self.goalPointLabel.text = "\(50)ポイント"
            },
            UIAction(title: "100") { _ in
                self.goalPoint = 100
                self.goalPointLabel.text = "\(100)ポイント"
            }
        ])
        goalPointMenuButton.menu = goalPointMenu
        goalPointMenuButton.showsMenuAsPrimaryAction = true
    }
    
    private func configureChallengeDaysMenuButton() {
        challengeDaysLabel.text = "日数を選択してください"
        let challengeDaysMenu = UIMenu(title: "", children: [
            UIAction(title: "10日") { _ in
                self.challengeDay = 10
                self.challengeDaysLabel.text = "\(10)日"
            },
            UIAction(title: "20日") { _ in
                self.challengeDay = 20
                self.challengeDaysLabel.text = "\(20)日"
            },
            UIAction(title: "30日") { _ in
                self.challengeDay = 30
                self.challengeDaysLabel.text = "\(30)日"
            }
        ])
        challengeDaysMenuButton.menu = challengeDaysMenu
        challengeDaysMenuButton.showsMenuAsPrimaryAction = true
    }
    
    /// 家族IDを取得
    private func getCurrentUserFamilyID() -> String {
        return ""
    }
    
    /// データを保存する
    private func saveData() {
        guard let user = Auth.auth().currentUser else {
            return showAlert(title: "ログインしてください")
        }
        
        guard let userName = userNameTextField.text,
              !userName.isEmpty,
              let challengeTask = challengeTaskTextView.text,
              !challengeTask.isEmpty,
              let challengePoint = challengePoint,
              let bonusPoint = bonusPoint,
              let goalPoint = goalPoint,
              let challengeDay = challengeDay else {
            return showAlert(title: "設定が済んでいません", message: "全ての項目を入力してください。")
        }
        
        let data: [String: Any] = [
            "user_id": user.uid,
            "user_name": userName,
            "challenge_task": challengeTask,
            "challenge_point": challengePoint,
            "bonus_point": bonusPoint,
            "goal_point": goalPoint,
            "challenge_day": challengeDay
        ]
        
        firebaseService.save(collection: "users", data: data) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(title: "データの保存エラー", message: error.localizedDescription)
            } else {
                self.showAlert(title: "登録しました！") {
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    /// アラートを表示
    private func showAlert(title: String, message: String = "",
                           completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    /// ログアウトをする
    private func logout() {
        do {
            // 成功時
            try Auth.auth().signOut()
            print("User signed out successfully")
            // ログアウト後にログイン画面に戻る
            navigateToLogin()
        } catch let signOutError as NSError {
            // エラー時
            showAlert(title: "エラーが発生しました",
                      message: "Error signing out: \(signOutError.localizedDescription)")
        }
    }
    
    /// ログイン画面へ遷移
    private func navigateToLogin() {
        let loginVC = LoginViewController()
        let navVC = UINavigationController(rootViewController: loginVC)
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = navVC
        }
    }
    
    /// 「ログアウトしますか？」のアラートを表示
    private func showLogoutAlert() {
        let alert = UIAlertController(title: "ログアウトしますか？",
                                      message: "",
                                      preferredStyle: .alert)
        //　「いいえ」ボタン
        let cancelAction = UIAlertAction(title: "いいえ",
                                         style: .cancel,
                                         handler: { (action: UIAlertAction) -> Void in
            // ボタンが押された時の処理
        })
        
        // 「はい」ボタン
        let logoutAction = UIAlertAction(title: "はい",
                                         style: .default,
                                         handler: { (action: UIAlertAction) -> Void in
            // ボタンが押された時の処理
            self.logout()
        })
        
        alert.addAction(cancelAction)
        alert.addAction(logoutAction)
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITextViewDelegate
extension SettingViewController: UITextViewDelegate {
    /// チャレンジ内容UITextViewが空のときだけplaceholderLabelを表示
    func textViewDidChange(_ challengeTaskTextView: UITextView) {
        placeholderLabel.isHidden = !challengeTaskTextView.text.isEmpty
    }
}
