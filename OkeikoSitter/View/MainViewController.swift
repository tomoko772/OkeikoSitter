//
//  MainViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/04/07.
//

import UIKit
import SwiftGifOrigin
import FirebaseAuth

/// メイン画面
final class MainViewController: UIViewController {

    // MARK: - Properties

    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared

    // MARK: - IBOutlets

    /// ユーザー画像
    @IBOutlet private weak var userImageView: UIImageView!
    /// ユーザーネームラベル
    @IBOutlet private weak var userNameLabel: UILabel!
    /// 目標（課題）の内容ラベル
    @IBOutlet private weak var taskLabel: UILabel!
    /// 目標（課題）達成時にもらえるポイント数ラベル
    @IBOutlet private weak var dailyPointLabel: UILabel!
    /// ボーナスポイントラベル
    @IBOutlet private weak var bonusPointLabel: UILabel!
    /// 現在のポイント数の表示ラベル
    @IBOutlet private weak var currentPointLabel: UILabel!
    /// 目標ポイント数ラベル
    @IBOutlet private weak var goalPointLabel: UILabel!
    /// 残りの日数ラベル
    @IBOutlet private weak var remainingDaysLabel: UILabel!
    /// GIF画像を表示するためにIBOutlet接続
    @IBOutlet private weak var gifImage: UIImageView!
    /// GIF画像を表示するためにIBOutlet接続
    @IBOutlet private weak var gifImage2: UIImageView!

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        gifImage.loadGif(name: "violin")
        gifImage.clipsToBounds = true
        gifImage.contentMode = .center
        gifImage2.loadGif(name: "present")
        configureBarButtonItems()
        fetchData()
    }

    // MARK: - IBActions

    /// ポイント獲得ボタンをタップ
    @IBAction private func addButtonTapped(_ sender: UIButton) {
        guard let currentPoint = UserSession.shared.currentUser?.currentPoint,
              let challengePoint = UserSession.shared.currentUser?.challengePoint else { return }
        UserSession.shared.updateCurrentPoint(currentPoint + challengePoint)
        currentPointLabel.text = "現在　\(currentPoint + challengePoint)　ポイント"
        saveCurrentPoint(currentPoint: currentPoint + challengePoint)
    }

    /// ボーナスボタンをタップ
    @IBAction private func addBonusButtonTapped(_ sender: UIButton) {
        guard let currentPoint = UserSession.shared.currentUser?.currentPoint,
              let bonusPoint = UserSession.shared.currentUser?.bonusPoint else { return }
        UserSession.shared.updateCurrentPoint(currentPoint + bonusPoint)
        currentPointLabel.text = "現在　\(currentPoint + bonusPoint)　ポイント"
        saveCurrentPoint(currentPoint: currentPoint + bonusPoint)
    }

    /// 残り日数が表示されたボタンをタップ
    @IBAction private func calendarButtonTapped(_ sender: UIButton) {
    }

    /// ご褒美ボタンをタップ
    @IBAction private func presentButtonTapped(_ sender: UIButton) {
        let presentVC = PresentViewController()
        let navController = UINavigationController(rootViewController: presentVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }

    // MARK: - Other Methods

    private func configureBarButtonItems() {

        // １つ目の画像ボタン
        let firstBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "ic_users"),
            style: .plain,
            target: self,
            action: #selector(didTapUsersButton))

        // ２つ目の画像のボタン
        let secondBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "ic_setting"),
            style: .plain,
            target: self,
            action: #selector(didTapSettingButton))

        // ボタンを右側に２つ並べる
        self.navigationItem.rightBarButtonItems = [firstBarButtonItem, secondBarButtonItem]
    }

    /// 設定ボタンがタップされたときの処理
    @objc private func didTapSettingButton(_ sender: UIButton) {
        navigateToSetting()
    }

    /// ユーザー切り替えボタンがタップされたときの処理
    @objc private func didTapUsersButton(_ sender: UIButton) {
        navigateToUsers()
    }

    /// 現在のポイントを保存
    private func saveCurrentPoint(currentPoint: Int) {
        guard let userID = Auth.auth().currentUser?.uid,
              let currentUser = UserSession.shared.currentUser else {
            print("未ログインまたはユーザー情報がありません")
            return
        }

        let userName = currentUser.userName
        let saveData: [String: Any] = ["current_point": currentPoint]

        // current_user と users配列の両方を更新
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: userName,
            userData: saveData
        ) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "データの保存エラー", message: error.localizedDescription)
            } else {
                UserSession.shared.updateCurrentPoint(currentPoint)
                print("ポイント保存成功: \(currentPoint)")
            }
        }
    }

    /// データを取得する
    private func fetchData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("未ログインです")
            return
        }
        UserSession.shared.setUserID(accountID: userID)
        firebaseService.fetchDocument(collection: "users", documentID: userID) { (accountData: Account?, error) in
            if let error = error {
                print("取得エラー: \(error)")
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let currentUserData = accountData?.currentUser {
                    print("📊 取得したポイント: \(currentUserData.currentPoint ?? -1)")
                    if let allUsers = accountData?.users {
                        let sessionUsers = allUsers.map { user in
                            UserSessionUser(
                                userName: user.userName ?? "",
                                challengeTask: user.challengeTask ?? "",
                                challengePoint: user.challengePoint ?? 0,
                                bonusPoint: user.bonusPoint ?? 0,
                                goalPoint: user.goalPoint ?? 0,
                                challengeDay: user.challengeDay ?? 0,
                                hiddenPlace: user.hiddenPlace ?? "",
                                profileImage: nil,
                                profileImageURL: user.profileImageURL,
                                currentPoint: user.currentPoint ?? 0,
                                pin: user.pin
                            )
                        }
                        UserSession.shared.setUsers(sessionUsers)
                        print("📝 UserSessionにユーザーをセット: \(sessionUsers.count)人")
                    }
                    // UserSessionUser に変換
                    let user = UserSessionUser(
                        userName: currentUserData.userName ?? "",
                        challengeTask: currentUserData.challengeTask ?? "",
                        challengePoint: currentUserData.challengePoint ?? 0,
                        bonusPoint: currentUserData.bonusPoint ?? 0,
                        goalPoint: currentUserData.goalPoint ?? 0,
                        challengeDay: currentUserData.challengeDay ?? 0,
                        hiddenPlace: currentUserData.hiddenPlace ?? "",
                        profileImage: nil,
                        profileImageURL: currentUserData.profileImageURL,
                        currentPoint: currentUserData.currentPoint ?? 0,
                        pin: currentUserData.pin
                    )

                    // UserSession に反映
                    UserSession.shared.selectCurrentUser(user: user)

                    // UI 更新
                    self.updateUI(with: user)

                    // 画像取得
                    if let profileImageURL = currentUserData.profileImageURL {
                        self.fetchImage(from: profileImageURL)
                    }

                } else {
                    print("current_user が存在しません")
                    navigateToUsers()
                }
            }
        }
    }
    
    /// 画像を取得
    private func fetchImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.userImageView.image = image
                    UserSession.shared.updateProfileImage(image)
                }
            }
        }.resume()
    }

    private func updateUI(with user: UserSessionUser) {
        userNameLabel.text = user.userName
        taskLabel.text = user.challengeTask.isEmpty ? "設定してください" : user.challengeTask
        dailyPointLabel.text = "+\(user.challengePoint) ポイント"
        currentPointLabel.text = "現在　\(user.currentPoint) ポイント"
        bonusPointLabel.text = "ボーナス+\(user.bonusPoint) ポイント"
        goalPointLabel.text = "目標　\(user.goalPoint)　ポイント"
        remainingDaysLabel.text = "\(user.challengeDay) 日"
    }

    /// 設定画面へ遷移
    private func navigateToSetting() {
        let settingVC = SettingViewController()
        settingVC.delegate = self
        let navController = UINavigationController(rootViewController: settingVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }

    /// ユーザー一覧画面へ遷移
    private func navigateToUsers() {
        let userVC = UserListViewController()
        userVC.delegate = self
        let navController = UINavigationController(rootViewController: userVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
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
}

// MARK: - UserListViewControllerDelegete

extension MainViewController: UserListViewControllerDelegete {
    func didSelectCurrentUser() {
        fetchData()
    }
}

// MARK: - SettingViewControllerDelegate

extension MainViewController: SettingViewControllerDelegate {
    func settingViewControllerDidUpdateData() {
        fetchData()
    }
}
