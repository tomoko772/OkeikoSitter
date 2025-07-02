//
//  SettingViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/05/21.
//

import UIKit

/// 設定画面
class SettingViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    /// ユーザー画像
    @IBOutlet private weak var userImageView: UIImageView!
    /// ユーザー名テキストフィールド
    @IBOutlet private weak var userNameTextField: UITextField!
    /// チャレンジ内容ラベル
    @IBOutlet private weak var challengeTaskLabel: UILabel!
    /// もらえるポイント数ラベル
    @IBOutlet private weak var challengePointLabel: UILabel!
    /// ボーナスポイント数ラベル
    @IBOutlet private weak var bonusPointLabel: UILabel!
    /// 目標ポイント数ラベル
    @IBOutlet private weak var goalPointLabel: UILabel!
    /// チャレンジ日数
    @IBOutlet private weak var challengeDaysLabel: UILabel!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        
    }
    
    // MARK: - IBActions
    
    /// もらえるポイント数メニューボタンをタップした
    @IBAction private func challengePointMenuButtonTapped(_ sender: UIButton) {
    }
    
    /// ボーナスポイント数メニューボタンをタップした
    @IBAction private func bonusPointMenuButtonTapped(_ sender: UIButton) {
    }
    
    /// 目標ポイント数メニューボタンをタップした
    @IBAction private func goalPointMenuButtonTapped(_ sender: UIButton) {
    }
    
    /// チャレンジ日数メニューボタンをタップした
    @IBAction private func challengeDaysMenuButtonTapped(_ sender: UIButton) {
    }
    
    /// ご褒美登録ボタンをタップした
    @IBAction private func presentRegisterButtonTapped(_sender: UIButton) {
        let presentVC = PresentViewController()
        let navController = UINavigationController(rootViewController: presentVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }
    
    /// 完了ボタンをタップした
    @IBAction private func doneButtonTapped(_ sender: UIButton) {
    }
    
    // MARK: - Other Methods
    
    private func configureBarButtonItems() {
        // 左端のキャンセルボタン（アイコン）
        let cancelImage = UIImage(named: "cancel")
        let cancelButton = UIBarButtonItem(image: cancelImage,
                                           style: .plain,
                                           target: self,
                                           action: #selector(cancelButtonPressed(_:)))
        navigationItem.leftBarButtonItem = cancelButton
        
        // 右端の削除ボタン（アイコン）
        let deleteImage = UIImage(named: "delete")
        let deleteButton = UIBarButtonItem(image: deleteImage,
                                           style: .plain,
                                           target: self,
                                           action: #selector(deleteButtonPressed(_:)))
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func deleteButtonPressed(_ sender: UIBarButtonItem) {
        print("ユーザーが削除されます")
    }
    
    // ご褒美登録ボタンがタップされたときの処理
    private func presentRegisterButtonTapped() {
        
    }
}
