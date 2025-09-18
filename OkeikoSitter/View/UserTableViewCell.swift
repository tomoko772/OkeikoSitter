//
//  UserTableViewCell.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/16.
//

import UIKit

/// ユーザー登録画面のセル
final class UserTableViewCell: UITableViewCell {
    // MARK: - IBOutlets
    
    /// ユーザーイメージビュー
    @IBOutlet private weak var userImageView: UIImageView!
    /// ユーザー名ラベル
    @IBOutlet private weak var userNameLabel: UILabel!
    
    // MARK: - Other Methods
    
    func configure(profileImage: UIImage?, userName: String) {
        if let profileImage = profileImage {
            self.userImageView.image = profileImage
        } else {
            self.userImageView.image = UIImage(systemName: "person.circle")
        }
        self.userNameLabel.text = userName
    }
    
}
