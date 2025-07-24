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
    let firebaseService = FirebaseService.shared
    
    // MARK: - IBOutlets
    
    /// ユーザー画像
    @IBOutlet private weak var userImageView: UIImageView!
    /// ユーザーネームラベル
    @IBOutlet private weak var userNameLabel: UILabel!
    /// 目標（課題）の内容ラベル
    @IBOutlet private weak var taskLabel: UILabel!
    /// 目標（課題）達成時にもらえるポイント数ラベル
    @IBOutlet private weak var dailyPointLabel: UILabel!
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
    
    /// ポイント獲得ボタンを押した時に呼ばれる関数
    @IBAction private func addButtonTapped(_ sender: Any) {
    }
    
    /// ボーナスボタンを押した時に呼ばれる関数
    @IBAction private func addBonusButtonTapped(_ sender: Any) {
    }
    
    /// 残り日数が表示されたボタンを押した時に呼ばれる関数
    @IBAction private func calendarButtonTapped(_ sender: Any) {
    }
    
    /// ご褒美ボタンを押した時に呼ばれる関数
    @IBAction private func presentButtonTapped(_ sender: Any) {
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
        let settingVC = SettingViewController()
        let navController = UINavigationController(rootViewController: settingVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
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
            DispatchQueue.main.async {
                if let error = error {
                    print("取得エラー: \(error)")
                    return
                }
                guard let user = users?.first else {
                    print("ユーザーデータなし")
                    return
                }
                self?.updateUI(with: user)
            }
        }
    }

    private func updateUI(with user: User) {
        userNameLabel.text = user.userName
        taskLabel.text = user.challengeTask
        dailyPointLabel.text = "\(user.challengePoint) ポイント"
//        currentPointLabel.text = "現在　\(user.currentPoint) ポイント"
//        bonusPointButton.setTitle("\(user.bonusPoint) ポイント", for: .normal)
        goalPointLabel.text = "\(user.goalPoint) ポイント"
        remainingDaysLabel.text = "\(user.challengeDay) 日"
    }
}

