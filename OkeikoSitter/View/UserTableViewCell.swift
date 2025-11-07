//
//  UserTableViewCell.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/16.
//

import UIKit

/// デリゲートのプロトコル
protocol UserTableViewCellDelegete: AnyObject {
    func didTapDeleteButton(in cell: UserTableViewCell)
}

/// ユーザー登録画面のセル
final class UserTableViewCell: UITableViewCell {
    // MARK: - Properties
    
    /// デリゲートのプロパティ
    weak var delegate: UserTableViewCellDelegete?

    // MARK: - IBOutlets
    
    /// ユーザーイメージビュー
    @IBOutlet private weak var userImageView: UIImageView!
    /// ユーザー名ラベル
    @IBOutlet private weak var userNameLabel: UILabel!
    
    // MARK: - IBActions
    
    /// 削除ボタンを押した
    @IBAction private func deleteButtonTapped(_ sender: UIButton) {
        delegate?.didTapDeleteButton(in: self)
    }
    
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
