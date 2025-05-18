//
//  MainViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/04/07.
//

import UIKit
import SwiftGifOrigin

final class MainViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    /// ユーザー画像
    @IBOutlet private weak var userImage: UIImageView!
    /// ユーザーネーム
    @IBOutlet private weak var userName: UIView!
    /// 目標（課題）の内容
    @IBOutlet weak var task: UILabel!
    /// 目標（課題）達成時にもらえるポイント数
    @IBOutlet private weak var dailyPoint: UILabel!
    /// ボーナスポイント数
    @IBOutlet private weak var bonusPoint: UIButton!
    /// 現在のポイント数の表示
    @IBOutlet private weak var currentPoint: UILabel!
    /// 目標ポイント数
    @IBOutlet private weak var goalPoint: UILabel!
    /// 残りの日数
    @IBOutlet weak var remainingDays: UILabel!
    /// GIF画像を表示するためにIBOutlet接続
    @IBOutlet private weak var gifImage: UIImageView!
    /// GIF画像を表示するためにIBOutlet接
    @IBOutlet private weak var gifImage2: UIImageView!
    
    /// 目標が表示されたボタンを押した時に呼ばれる関数
    @IBAction func addButtonTapped(_ sender: Any) {
    }
    
    /// ボーナスボタンを押した時に呼ばれる関数
    @IBAction func addBonusButtonTapped(_ sender: Any) {
    }
    
    /// 残り日数が表示されたボタンを押した時に呼ばれる関数
    @IBAction func calendarButtonTapped(_ sender: Any) {
    }
    
    /// ご褒美ボタンを押した時に呼ばれる関数
    @IBAction func presentButtonTapped(_ sender: Any) {
    }
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gifImage.loadGif(name: "violin")
        gifImage.clipsToBounds = true
        gifImage.contentMode = .center
        gifImage2.loadGif(name: "present")
        configureBarButtonItems()
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
    
    @objc private func didTapSettingButton() {
        // 設定ボタンがタップされたときの処理
        print("設定ボタンがタップされました")
    }
    
    @objc private func didTapUsersButton() {
        // ユーザー切り替えボタンがタップされたときの処理
        print("ユーザー切り替えボタンがタップされました")
    }
 
}

