//
//  SettingViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/05/21.
//

import UIKit
import FirebaseAuth

protocol SettingViewControllerDelegate: AnyObject {
    func settingViewControllerDidUpdateData()
}

/// 設定画面
final class SettingViewController: UIViewController {
    
    // MARK: - Properties
    
    private let defaultText = "ポイントを選択してください"
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    /// 選択した画像
    private var selectedImage: UIImage?
    /// 選択したチャレンジポイント
    private var selectedChallengePoint: Int?
    /// 選択したボーナスポイント
    private var selectedBonusPoint: Int?
    /// 選択した目標ポイント
    private var selectedGoalPoint: Int?
    /// 選択したチャレンジ日数
    private var selectedChallengeDay: Int?
    /// デリゲート
    weak var delegate: SettingViewControllerDelegate?

    // MARK: - IBOutlets

    /// ユーザー名ラベル
    @IBOutlet private weak var userNameLabel: UILabel!
    /// ユーザー画像
    @IBOutlet private weak var userImageView: UIImageView!
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
        configureTapGesture()
        configureUI()
        configureTextView()
        configureBarButtonItems()
        configureChallengePointMenuButton()
        configureBonusPointMenuButton()
        configureGoalPointMenuButton()
        configureChallengeDaysMenuButton()
        challengeTaskTextView.delegate = self
        placeholderLabel.isHidden = !challengeTaskTextView.text.isEmpty
    }
    
    // MARK: - IBActions
    
    /// ユーザー画像ボタンをタップした
    @IBAction private func userImageButtonTapped(_ sender: Any) {
        presentImagePicker()
    }

    /// 画像の保存ボタンをタップした
    @IBAction private func imageSaveButtonTapped(_ sender: Any) {
        guard Auth.auth().currentUser != nil else {
            return showAlert(title: "ログインしてください")
        }

        guard let selectedImage = selectedImage else {
            return showAlert(title: "画像が選択されていません")
        }

        // userNameLabel からユーザー名を取得（ユーザーIDで保存したいならそれでOK）
        guard let userName = userNameLabel.text, !userName.isEmpty else {
            return showAlert(title: "ユーザー名が取得できません")
        }

        uploadProfileImage(userName: userName, image: selectedImage)
    }

    /// ご褒美登録ボタンをタップした
    @IBAction private func presentRegisterButtonTapped(_ sender: UIButton) {
        let presentVC = PresentViewController()
        let navController = UINavigationController(rootViewController: presentVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }
    
    /// 各種設定の保存ボタンをタップした
    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        validateSaveData { [weak self] success in
            guard let self = self else { return }
            if success {
                self.delegate?.settingViewControllerDidUpdateData()
            }
        }
    }
    
    /// ログアウトボタンをタップした
    @IBAction private func logoutButtonTapped(_ sender: UIButton) {
        showLogoutAlert()
    }
    
    // MARK: - Other Methods
    
    private func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    /// キーボードを閉じる
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func configureUI() {
        if let user = UserSession.shared.currentUser {
            userNameLabel.text = user.userName
            challengeTaskTextView.text = user.challengeTask
            challengePointLabel.text = "\(user.challengePoint)ポイント"
            selectedChallengePoint = user.challengePoint
            bonusPointLabel.text = "\(user.bonusPoint)ポイント"
            selectedBonusPoint = user.bonusPoint
            goalPointLabel.text = "\(user.goalPoint)ポイント"
            selectedGoalPoint = user.goalPoint
            challengeDaysLabel.text = "\(user.challengeDay)日"
            selectedChallengeDay = user.challengeDay

            if let profileImage = user.profileImage {
                userImageView.image = profileImage
                selectedImage = profileImage
            } else if let profileImageURL = user.profileImageURL {
                fetchImage(from: profileImageURL)
            } else {
                userImageView.image = UIImage(systemName: "person.crop.circle")
            }
        } else {
            challengePointLabel.text = defaultText
            bonusPointLabel.text = defaultText
            goalPointLabel.text = defaultText
            challengeDaysLabel.text = "日数を選択してください"
            userImageView.image = UIImage(systemName: "person.crop.circle")
        }
    }
    
    private func configureTextView() {
        challengeTaskTextView.delegate = self
    }
    
    private func configureBarButtonItems() {
        // 左端のキャンセルボタン（アイコン）
        let cancelImage = UIImage(named: "cancel")
        let closeButton = UIBarButtonItem(image: cancelImage,
                                           style: .plain,
                                           target: self,
                                           action: #selector(closeButtonTapped(_:)))
        navigationItem.leftBarButtonItem = closeButton
    }
    
    @objc func closeButtonTapped(_ sender: UIBarButtonItem) {
        self.delegate?.settingViewControllerDidUpdateData()
        dismiss(animated: true, completion: nil)
    }
        
    private func configureChallengePointMenuButton() {
        let challengePointMenu = UIMenu(title: "", children: [
            UIAction(title: "1") { _ in
                self.selectedChallengePoint = 1
                self.challengePointLabel.text = "\(1)ポイント"
            },
            UIAction(title: "2") { _ in
                self.selectedChallengePoint = 2
                self.challengePointLabel.text = "\(2)ポイント"
            },
            UIAction(title: "3") { _ in
                self.selectedChallengePoint = 3
                self.challengePointLabel.text = "\(3)ポイント"
            }
        ])
        challengePointMenuButton.menu = challengePointMenu
        challengePointMenuButton.showsMenuAsPrimaryAction = true
    }
    
    private func configureBonusPointMenuButton() {
        let bonusPointMenu = UIMenu(title: "", children: [
            UIAction(title: "3") { _ in
                self.selectedBonusPoint = 3
                self.bonusPointLabel.text = "\(3)ポイント"
            },
            UIAction(title: "5") { _ in
                self.selectedBonusPoint = 5
                self.bonusPointLabel.text = "\(5)ポイント"
            },
            UIAction(title: "10") { _ in
                self.selectedBonusPoint = 10
                self.bonusPointLabel.text = "\(10)ポイント"
            }
        ])
        bonusPointMenuButton.menu = bonusPointMenu
        bonusPointMenuButton.showsMenuAsPrimaryAction = true
    }
    
    private func configureGoalPointMenuButton() {
        let goalPointMenu = UIMenu(title: "", children: [
            UIAction(title: "30") { _ in
                self.selectedGoalPoint = 30
                self.goalPointLabel.text = "\(30)ポイント"
            },
            UIAction(title: "50") { _ in
                self.selectedGoalPoint = 50
                self.goalPointLabel.text = "\(50)ポイント"
            },
            UIAction(title: "100") { _ in
                self.selectedGoalPoint = 100
                self.goalPointLabel.text = "\(100)ポイント"
            }
        ])
        goalPointMenuButton.menu = goalPointMenu
        goalPointMenuButton.showsMenuAsPrimaryAction = true
    }
    
    private func configureChallengeDaysMenuButton() {
        let challengeDaysMenu = UIMenu(title: "", children: [
            UIAction(title: "10日") { _ in
                self.selectedChallengeDay = 10
                self.challengeDaysLabel.text = "\(10)日"
            },
            UIAction(title: "20日") { _ in
                self.selectedChallengeDay = 20
                self.challengeDaysLabel.text = "\(20)日"
            },
            UIAction(title: "30日") { _ in
                self.selectedChallengeDay = 30
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
    
    /// データをチェックする
    private func validateSaveData(completion: ((Bool) -> Void)? = nil) {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "ログインしてください")
            completion?(false)
            return
        }

        // 必須項目チェック（画像と名前は除外）
        guard let challengeTask = challengeTaskTextView.text, !challengeTask.isEmpty,
              let challengePoint = selectedChallengePoint,
              let bonusPoint = selectedBonusPoint,
              let goalPoint = selectedGoalPoint,
              let challengeDay = selectedChallengeDay else {
            showAlert(title: "設定が済んでいません", message: "全ての項目を入力してください。")
            completion?(false)
            return
        }

        let dataToSave: [String: Any] = [
            "challenge_task": challengeTask,
            "challenge_point": challengePoint,
            "bonus_point": bonusPoint,
            "goal_point": goalPoint,
            "challenge_day": challengeDay
        ]

        saveData(userID: user.uid, saveData: dataToSave) { success in
            completion?(success)
        }
    }

    /// アラートを表示
    private func showAlert(title: String, message: String = "",
                           completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        // 1秒後に自動で閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            alert.dismiss(animated: true)
        }
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
    
    /// プロフィール画像をアップロード
    private func uploadProfileImage(userName: String, image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        let path = "profile_images/\(userName).jpg"

        firebaseService.uploadDataToStorage(data: imageData, path: path) { [weak self] url, error in
            if let error = error {
                self?.showAlert(title: "画像アップロード失敗", message: error.localizedDescription)
                return
            }
            guard let downloadURL = url else {
                self?.showAlert(title: "画像URL取得失敗")
                return
            }
            print("アップロード成功: \(downloadURL)")
            // Firestoreのユーザードキュメントに画像URLを保存したい場合はここで更新
            self?.saveProfileImageURL(downloadURL.absoluteString)
        }
    }
    
    /// プロフィール画像URLを保存
    private func saveProfileImageURL(_ urlString: String) {
        guard let userID = Auth.auth().currentUser?.uid,
              let currentUser = UserSession.shared.currentUser else {
            showAlert(title: "ユーザー情報が取得できません")
            return
        }

        let userName = currentUser.userName
        let imageData = ["profile_image_url": urlString]

        // 両方を更新
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: userName,
            userData: imageData
        ) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "画像保存失敗", message: error.localizedDescription)
                return
            }

            var updatedUser = currentUser
            updatedUser.profileImageURL = urlString
            updatedUser.profileImage = self.selectedImage
            UserSession.shared.selectCurrentUser(user: updatedUser)

            self.delegate?.settingViewControllerDidUpdateData()
            self.userImageView.image = self.selectedImage
            self.showAlert(title: "画像を保存しました！")
        }
    }

    /// データを保存
    private func saveData(userID: String, saveData: [String: Any], completion: ((Bool) -> Void)? = nil) {
        guard let currentUser = UserSession.shared.currentUser else {
            showAlert(title: "ユーザー情報が取得できません")
            completion?(false)
            return
        }

        let userName = currentUser.userName

        // 両方を更新
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: userName,
            userData: saveData
        ) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "データの保存エラー", message: error.localizedDescription)
                completion?(false)
            } else {
                // UserSession も更新
                self.updateUserSession(with: saveData)
                self.showAlert(title: "設定を保存しました！")
                completion?(true)
            }
        }
    }

    /// UserSession を更新
    private func updateUserSession(with data: [String: Any]) {
        guard var user = UserSession.shared.currentUser else { return }

        if let challengeTask = data["challenge_task"] as? String {
            user.challengeTask = challengeTask
        }
        if let challengePoint = data["challenge_point"] as? Int {
            user.challengePoint = challengePoint
        }
        if let bonusPoint = data["bonus_point"] as? Int {
            user.bonusPoint = bonusPoint
        }
        if let goalPoint = data["goal_point"] as? Int {
            user.goalPoint = goalPoint
        }
        if let challengeDay = data["challenge_day"] as? Int {
            user.challengeDay = challengeDay
        }

        // 更新したユーザーをセット
        UserSession.shared.selectCurrentUser(user: user)
    }

    /// 画像を取得
    private func fetchImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.userImageView.image = image
                    self.selectedImage = image
                    // UserSessionにも反映
                    UserSession.shared
                        .updateCurrentUser(profileImage: image, profileImageURL: urlString)
                }
            }
        }.resume()
    }
}

// MARK: - UITextViewDelegate

extension SettingViewController: UITextViewDelegate {
    /// チャレンジ内容UITextViewが空のときだけplaceholderLabelを表示
    func textViewDidChange(_ challengeTaskTextView: UITextView) {
        placeholderLabel.isHidden = !challengeTaskTextView.text.isEmpty
    }
    
    /// returnキーを押された時のメソッド
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if text == "\n" { // 改行が入力された場合
            textView.resignFirstResponder() // キーボードを閉じる
            return false // 改行はしない
        }
        return true
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension SettingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /// イメージピッカーを表示
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    /// 選択完了時
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let selectedImage = info[.originalImage] as? UIImage {
            userImageView.image = selectedImage
            self.selectedImage = selectedImage
        }
    }
    
    /// キャンセル時
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
