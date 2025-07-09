//
//  MainViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/04/07.
//

import UIKit
import SwiftGifOrigin

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
    /// ボーナスポイント数ボタン
    @IBOutlet private weak var bonusPointButton: UIButton!
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
    
    /// 目標が表示されたボタンを押した時に呼ばれる関数
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
        firebaseService.fetchDataFromFirestore(collection: "setting") { [weak self] documents, error in
            guard let self = self else { return }
            if let error = error {
                print("データの取得エラー: \(error)")
            } else if let documents = documents {
                // 取得したデータを処理
                let settings: [Setting] = documents.compactMap { doc in
                    guard let data = doc.data() else {
                        return nil
                    }
                    guard
                        let userName = data["user_name"] as? String,
                        let challengePoint = data["challenge_point"] as? Int,
                        let bonusPoint = data["bonus_point"] as? Int,
                        let goalPoint = data["goalPoint"] as? Int,
                        let challengeDay = data["challenge_day"] as? Int,
                        let challengeTask = data["challenge_task"] as? String
                    else {
                        return nil
                    }
                    
                    return Setting(
                        documentID: doc.documentID,
                        userName: userName,
                        challengePoint: challengePoint,
                        bonusPoint: bonusPoint,
                        goalPoint: goalPoint,
                        challengeDay: challengeDay,
                        challengeTask: challengeTask
                    )
                }
                print("データの取得: \(settings)")
            }
        }
    }
}

