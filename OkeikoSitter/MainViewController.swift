//
//  ViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/04/07.
//

import UIKit
import SwiftGifOrigin

class MainViewController: UIViewController {
    
    // MARK: - View Life-Cycle Methods
    
    @IBOutlet weak var gifImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gifImage.loadGif(name: "violin")
        gifImage.clipsToBounds = true
        gifImage.contentMode = .center
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

