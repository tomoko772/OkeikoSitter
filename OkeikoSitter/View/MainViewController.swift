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
    /// ユーザー情報
    private var user: User?
    /// プロフィール画像
    private var profileImage: UIImage?
    /// 現在のポイント
    private var currentPoint: Int = 0
    /// チャレンジポイント
    private var challengePoint: Int = 0
    /// ボーナスポイント
    private var bonusPoint: Int = 0
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }
    
    // MARK: - IBActions
    
    /// ポイント獲得ボタンをタップ
    @IBAction private func addButtonTapped(_ sender: UIButton) {
        currentPoint = currentPoint + challengePoint
        currentPointLabel.text = "現在　\(currentPoint)　ポイント"
    }
    
    /// ボーナスボタンをタップ
    @IBAction private func addBonusButtonTapped(_ sender: UIButton) {
        currentPoint = currentPoint + bonusPoint
        currentPointLabel.text = "現在　\(currentPoint)　ポイント"
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
        let userVC = UserViewController()
        let navController = UINavigationController(rootViewController: userVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }
    
    /// データを取得する
    private func fetchData() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("未ログインです")
            return
        }
        
        firebaseService.fetchByQuery(collection: "users",
                                     field: "user_id",
                                     isEqualTo: currentUserID,
                                     as: User.self) { [weak self] users, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("取得エラー: \(error)")
                    return
                }
                guard let user = users?.first else {
                    print("ユーザーデータなし")
                    self.navigateToSetting()
                    return
                }
                self.challengePoint = user.challengePoint
                self.bonusPoint = user.bonusPoint
                self.user = user
                self.fetchImage(userID: user.userID)
                self.updateUI(with: user)
                UserSession.shared.setUserID(userID: user.userID, familyID: user.familyID)
            }
        }
    }
    
    /// 画像を取得
    private func fetchImage(userID: String) {
        FirebaseService.shared.fetchImageFromStorage(path: "profile_images/\(userID).jpg") { image in
            if let image = image {
                self.userImageView.image = image
                self.profileImage = image
            } else {
                print("画像の読み込みに失敗しました")
            }
        }
    }
    
    private func updateUI(with user: User) {
        userNameLabel.text = user.userName
        taskLabel.text = user.challengeTask
        dailyPointLabel.text = "+\(user.challengePoint) ポイント"
        currentPointLabel.text = "現在　\(currentPoint) ポイント"
        bonusPointLabel.text = "ボーナス+\(user.bonusPoint) ポイント"
        goalPointLabel.text = "目標　\(user.goalPoint)　ポイント"
        remainingDaysLabel.text = "\(user.challengeDay) 日"
    }
    
    /// 設定画面へ遷移
    private func navigateToSetting() {
        let settingVC = SettingViewController(image: profileImage, user: user)
        let navController = UINavigationController(rootViewController: settingVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }
}

