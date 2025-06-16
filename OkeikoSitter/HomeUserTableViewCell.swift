//
//  HomeUserTableViewCell.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/16.
//

import UIKit

///ユーザー登録画面のセル
class HomeUserTableViewCell: UITableViewCell {
    // MARK: - IBOutlets
    ///ユーザーイメージビュー
    @IBOutlet private weak var userImageView: UIImageView!
    ///ユーザー名ラベル
    @IBOutlet private weak var userNameLabel: UILabel!
    
    
    // MARK: - View Life-Cycle Methods
    
    
    // MARK: - IBActions
    
    ///ユーザー選択ボタン
    @IBAction private func UserSelectionButtonTapped(_ sender: Any) {
    }
    
    // MARK: - Other Methods
    func configure(imageString: String, userName: String) {
        self.userImageView.image = UIImage(named: imageString)
        self.userNameLabel.text = userName
    }
    
}
