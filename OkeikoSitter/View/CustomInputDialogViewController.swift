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

    /// 隠し場所・PIN を親に渡すコールバック
    var onRegister: ((String, Int) -> Void)?
    /// 入力PIN を親に渡すコールバック
    var onValidate: ((Int) -> Void)?
    /// 暗唱番号
    var pin: Int?

    // MARK: - Computed Properties

    /// 表示モード
    var dialogMode: DialogMode {
        didSet { updateUIForMode() }
    }

    // MARK: - IBOutlets

    /// タイトルラベル
    @IBOutlet private weak var titleLabel: UILabel!
    /// ピンクビューとのパディング
    @IBOutlet private weak var pinkViewBottomConstraint: NSLayoutConstraint!
    /// 隠し場所テキストフィールド
    @IBOutlet private weak var hiddenPlaceTextField: UITextField!
    /// 暗唱番号テキストフィールド
    @IBOutlet private weak var pinTextField: UITextField!
    /// ピンクビュー
    @IBOutlet private weak var pinkView: UIView!
    /// 隠し場所の入力ビュー
    @IBOutlet private weak var inputHiddenPlaceView: UIView!
    /// 登録ボタン
    @IBOutlet private weak var registrationButton: PressableButton!
    /// 認証するボタン
    @IBOutlet private weak var certificationButton: PressableButton!

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
        pinTextField.delegate = self
        pinTextField.keyboardType = .numberPad
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
        // 隠し場所・PIN が入力されているかチェック
        guard let hidden = hiddenPlaceTextField.text, !hidden.isEmpty,
              let pinText = pinTextField.text, !pinText.isEmpty else {
            showAlert(title: "隠し場所と暗唱番号を入力してください", message: "")
            return
        }

        // PINは数字4桁まで
        guard pinText.count == 4, let pin = Int(pinText) else {
            showAlert(title: "暗唱番号は4桁の数字で入力してください", message: "")
            return
        }

        // 登録コールバック
        onRegister?(hidden, pin)
    }
    
    /// キャンセルボタンをタップした
    @IBAction private func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    /// 認証するボタンをタップした
    @IBAction private func certificationButtonTapped(_ sender: UIButton) {
        // PIN入力があるかチェック
        guard let pinText = pinTextField.text, !pinText.isEmpty else {
            showAlert(title: "暗唱番号を入力してください", message: "")
            return
        }

        // PINは数字4桁まで
        guard pinText.count == 4, let pin = Int(pinText) else {
            showAlert(title: "暗唱番号は4桁の数字で入力してください", message: "")
            return
        }

        // 認証コールバック
        onValidate?(pin)
    }
    

    // MARK: - Other Methods
    
    private func configureUI() {
        updateUIForMode()
    }

    private func updateUIForMode() {
        switch dialogMode {
        case .pinOnly:
            titleLabel.text = "認証してください"
            pinkViewBottomConstraint.constant = 32
            inputHiddenPlaceView.isHidden = true
            certificationButton.isHidden = false
            registrationButton.isHidden = true
        case .registerHiddenPlaceAndPin:
            titleLabel.text = "保護者の方に\n入力してもらって\nください"
            pinkViewBottomConstraint.constant = 18
            inputHiddenPlaceView.isHidden = false
            certificationButton.isHidden = true
            registrationButton.isHidden = false
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    /// 認証成功後にUIを隠し場所入力モードに切り替える
    func switchToRegisterMode(withHiddenPlace hiddenPlace: String) {
        self.dialogMode = .registerHiddenPlaceAndPin
        self.titleLabel.text = "変更しますか？"

        // 隠し場所をテキストフィールドに表示
        self.hiddenPlaceTextField.text = hiddenPlace

        // UIの切り替え
        self.inputHiddenPlaceView.isHidden = false
        self.registrationButton.isHidden = false
        self.certificationButton.isHidden = true
    }
}

extension CustomInputDialogViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard textField == pinTextField else { return true }

        // 入力後のテキストを計算
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        // 数字のみかつ4桁まで
        let isNumeric = string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        return updatedText.count <= 4 && isNumeric
    }
}
