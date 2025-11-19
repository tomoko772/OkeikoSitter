//
//  CustomInputDialogViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/11/12.
//

import UIKit

enum DialogMode {
    /// 暗唱番号入力だけを表示
    case pinOnly
    /// 隠し場所と暗唱番号入力を表示
    case registerHiddenPlaceAndPin
}

/// 保護者の方に入力してもらってくださいダイアログ
final class CustomInputDialogViewController: UIViewController {
    
    // MARK: - Properties
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    /// 表示モード
    var dialogMode: DialogMode
    /// 暗唱番号
    var pin: Int?
    
    // MARK: - IBOutlets
    
    /// 隠し場所テキストフィールド
    @IBOutlet private weak var hiddenPlaceTextField: UITextField!
    /// 暗唱番号テキストフィールド
    @IBOutlet private weak var pinTextField: UITextField!
    /// ピンクビュー
    @IBOutlet private weak var pinkView: UIView!
    
    // MARK: - Initializers
    
    init(pin: Int?, dialogMode: DialogMode) {
        self.pin = pin
        self.dialogMode = dialogMode
        super.init(nibName: "CustomInputDialogViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.pin = nil
        self.dialogMode = .registerHiddenPlaceAndPin
        super.init(coder: coder)
    }
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
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
        switch dialogMode {
        case .pinOnly:
            guard let pinText = pinTextField.text, !pinText.isEmpty else {
                showAlert(title: "暗唱番号を入力してください", message: "")
                return
            }
            if let pin = Int(pinText) {
                validatePin(pin)
            } else {
                showAlert(title: "数字を入力してください", message: "")
            }
            
        case .registerHiddenPlaceAndPin:
            guard let hiddenPlaceText = hiddenPlaceTextField.text, !hiddenPlaceText.isEmpty,
                  let pinText = pinTextField.text, !pinText.isEmpty else {
                showAlert(title: "隠し場所と暗唱番号を入力してください", message: "")
                return
            }
            if let pin = Int(pinText) {
                registerHiddenPlace(hiddenPlace: hiddenPlaceText, pin: pin)
            } else {
                showAlert(title: "数字を入力してください", message: "")
            }
        }
    }
    
    /// キャンセルボタンをタップした
    @IBAction private func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    // MARK: - Other Methods
    
    private func configureUI() {
        switch dialogMode {
        case .pinOnly:
            hiddenPlaceTextField.isHidden = true
            pinTextField.isHidden = false
            pinTextField.placeholder = "暗唱番号を入力してください"
        case .registerHiddenPlaceAndPin:
            hiddenPlaceTextField.isHidden = false
            pinTextField.isHidden = false
            hiddenPlaceTextField.placeholder = "隠し場所を入力してください"
            pinTextField.placeholder = "暗唱番号を入力してください"
        }
    }
    
    /// 隠し場所を登録
    private func registerHiddenPlace(hiddenPlace: String, pin: Int) {
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
    
    /// 暗唱番号の検証
    private func validatePin(_ pin: Int) {
        // Userモデルにpinプロパティがある前提
        if self.pin == pin {
            // 正しい場合の処理（画面遷移やご褒美表示など）
            self.showAlert(title: "認証成功", message: "")
            self.dismiss(animated: true)
        } else {
            // 誤りの場合
            self.showAlert(title: "暗唱番号が違います", message: "")
        }
    }
}
