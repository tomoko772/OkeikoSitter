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
    
    @IBOutlet private weak var userImage: UIImageView!
    
    @IBOutlet private weak var userName: UIView!
    
    @IBOutlet private weak var goal: UIView!
    
    @IBOutlet private weak var dailyPoint: UILabel!
    
    @IBOutlet private weak var bonusPoint: UIButton!
    
    @IBOutlet private weak var currentPoint: UILabel!
    
    @IBOutlet private weak var goalPoint: UILabel!
    
    @IBOutlet private weak var remainingDays: UIButton!
    
    @IBOutlet private weak var calendar: UIButton!
    
    @IBOutlet private weak var gifImage: UIImageView!
    
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

