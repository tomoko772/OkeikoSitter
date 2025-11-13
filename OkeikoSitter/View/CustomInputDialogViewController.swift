//
//  CustomInputDialogViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/11/12.
//

import UIKit

/// 保護者の方に入力してもらってくださいダイアログ　
final class CustomInputDialogViewController: UIViewController {
    
    // MARK: - Properties
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    
    // MARK: - IBOutlets
    
    /// 隠し場所テキストフィールド
    @IBOutlet private weak var hiddenPlaceTextField: UITextField!
    /// 暗唱番号テキストフィールド
    @IBOutlet private weak var pinTextField: UITextField!
    
    /// ピンクビュー
    @IBOutlet private weak var pinkView: UIView!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pinkView.layer.cornerRadius = 8
        pinkView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        pinkView.clipsToBounds = true
    }
    
    // MARK: - IBActions
    
    /// 登録ボタンをタップした
    @IBAction private func registerTapped(_ sender: UIButton) {
        guard let hiddenPlaceText = hiddenPlaceTextField.text,
              let pinText = pinTextField.text else { return }
        if hiddenPlaceText.isEmpty || pinText.isEmpty {
            showAlert(title: "隠し場所と暗唱番号を入力してください", message: "")
            return
        } else {
            registerHiddenPlace(hiddenPlace: hiddenPlaceText, pin: pinText)
        }
    }
    
    /// キャンセルボタンをタップした
    @IBAction private func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    // MARK: - Other Methods
    
    /// 隠し場所を登録
    private func registerHiddenPlace(hiddenPlace: String, pin: String) {
        guard let userID = UserSession.shared.accountID else { return }
        let saveToData: [String: Any] = [
            "hidden_place": hiddenPlace,
            "pin": pin
        ]
        saveData(userID: userID, saveData: saveToData)
    }
    
    /// データを保存
    private func saveData(userID: String, saveData: [String: Any]) {
        self.firebaseService.update(collection: "users", documentID: userID, data: saveData) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(title: "データの保存エラー", message: error.localizedDescription)
            } else {
                print("保存データ：\(saveData)")
                print("userID：\(userID)")
                self.dismiss(animated: true)
                self.showAlert(title: "登録しました！", message: "")
                
            }
        }
    }
    
    /// アラートを表示
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
