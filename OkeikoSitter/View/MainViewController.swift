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
//        deleteData()
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
        guard let userID = Auth.auth().currentUser?.uid else {
            print("未ログインです")
            return
        }
        let saveData: [String: Any] = ["current_point": currentPoint]
        self.firebaseService.update(collection: "users",
                                    documentID: userID,
                                    data: ["current_user": saveData]) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(title: "データの保存エラー", message: error.localizedDescription)
            } else {
                print("保存データ：\(saveData)")
                self.dismiss(animated: true)
            }
        }
    }

    /// データを取得する
    private func fetchData() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("未ログインです")
            return
        }

        // アカウントIDを設定
        UserSession.shared.setUserID(accountID: currentUserID)

        // Firestore から単一ドキュメントを取得
        firebaseService.fetchDocument(collection: "users", documentID: currentUserID) { (accountData: Account?, error) in
            if let error = error {
                print("取得エラー: \(error)")
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let currentUserData = accountData?.currentUser {
                    // UserSessionUser に変換
                    let user = UserSessionUser(
                        userName: currentUserData.userName ?? "",
                        challengeTask: currentUserData.challengeTask ?? "",
                        challengePoint: currentUserData.challengePoint ?? 0,
                        bonusPoint: currentUserData.bonusPoint ?? 0,
                        goalPoint: currentUserData.goalPoint ?? 0,
                        challengeDay: currentUserData.challengeDay ?? 0,
                        hiddenPlace: currentUserData.hiddenPlace ?? "",
                        profileImage: UIImage(),
                        profileImageURL: currentUserData.profileImageURL,
                        currentPoint: currentUserData.currentPoint ?? 0,
                        pin: currentUserData.pin ?? 0
                    )

                    // 現在のユーザーにセット
                    UserSession.shared.selectCurrentUser(user: user)
                    print("ユーザー情報：\(user)")

                    // UI 更新
                    self.updateUI(with: user)

                    // 画像取得
                    if let profileImageURLString = currentUserData.profileImageURL {
                        fetchImage(from: profileImageURLString)
                    }
                } else {
                    print("カレントユーザーがいない")
                    self.navigateToUsers()
                }
            }
        }
    }
    
    /// 画像を取得
    private func fetchImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        // URL から UIImage を取得（キャッシュなどは任意）
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
// TODO: デバッグ用で使うので、最終的には消す
//    /// データを削除する
//    private func deleteData() {
//        guard let currentUserID = Auth.auth().currentUser?.uid else {
//            print("未ログインです")
//            return
//        }
//        FirebaseService.shared.delete(collection: "users", documentID: currentUserID) { error in
//            if let error = error {
//                print("削除エラー: \(error)")
//            } else {
//                print("削除成功")
//            }
//        }
//    }
}

// MARK: - UserListViewControllerDelegete

extension MainViewController: UserListViewControllerDelegete {
    func didSelectCurrentUser() {
        fetchData()
    }
}
