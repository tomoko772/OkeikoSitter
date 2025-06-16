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
    @IBOutlet private weak var UserImageView: UIImageView!
    ///ユーザー名ラベル
    @IBOutlet private weak var UserNameLabel: UILabel!
    
    
    // MARK: - View Life-Cycle Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - IBActions
    
    ///ユーザー選択ボタン
    @IBAction private func UserSelectionButtonTapped(_ sender: Any) {
    }
    
}
