//
//  ViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/04/07.
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
    }
    
    // MARK: - Other Methods
    
    
    
    
    
    private func configureBarButtonItems() {
        
        // １つ目の画像ボタン
        let image1 = UIImage(named: "ic_users")
        let button1 = UIBarButtonItem(
            image: image1,
            style: .plain,
            target: self,
            action: #selector(didTapUsersButton))
    
        // ２つ目の画像のボタン
        let image2 = UIImage(named: "ic_setting")
        let button2 = UIBarButtonItem(
            image: image2,
            style: .plain,
            target: self,
            action: #selector(didTapSettingButton))
        
        // ボタンを右側に２つ並べる
        self.navigationItem.rightBarButtonItems = [button1, button2]
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

