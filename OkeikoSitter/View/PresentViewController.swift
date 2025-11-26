//
//  PresentViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/22.
//

import UIKit

/// ご褒美登録画面
final class PresentViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 隠し場所
    private var hidingPlace: String = ""
    /// 目標達成の有無
    private var isGoalReached: Bool = false
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    
    // MARK: - IBOutlets
    
    /// ご褒美画像
    @IBOutlet private weak var rewardImageView: UIImageView!
    /// プレゼントマーク
    @IBOutlet private weak var presentMarkImageView: UIImageView!
    /// 隠し場所ラベル
    @IBOutlet private weak var hiddenPlaceLabel: UILabel!
    /// クエスチョンマーク
    @IBOutlet private weak var quesitonMarkImageView: UIImageView!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        configureUI()
    }
    
    // MARK: - IBActions
    
    /// カメラボタンをタップした
    @IBAction private func cameraButtonTapped(_ sender: Any) {
        showActionSheet()
    }
    
    /// 隠し場所登録・変更ボタンをタップした
    @IBAction private func registrationButtonTapped(_ sender: Any) {
        // 現在選択中のユーザーを取得
        guard let currentUser = UserSession.shared.currentUser else { return }
        let childID = currentUser.userName // IDとして扱う

        // PIN登録済みかを確認する
        checkPinRegistered(for: childID) { [weak self] isRegistered, pin, hiddenPlace in
            guard let self = self else { return }
            let mode: DialogMode = isRegistered ? .pinOnly : .registerHiddenPlaceAndPin
            let dialogVC = CustomInputDialogViewController(pin: pin, dialogMode: mode)

            // 登録コールバック
            dialogVC.onRegister = { [weak self] hiddenPlace, pin in
                self?.saveHiddenPlaceAndPin(hiddenPlace: hiddenPlace, pin: pin, userID: childID)
                dialogVC.dismiss(animated: true)
            }

            // PIN認証コールバック
            dialogVC.onValidate = { enteredPin in
                guard let hiddenPlace = hiddenPlace else { return }
                if enteredPin == pin {
                    // 認証成功 → ダイアログを閉じずに入力モードに切替
                    dialogVC.switchToRegisterMode(withHiddenPlace: hiddenPlace)
                } else {
                    dialogVC.showAlert(title: "暗唱番号が違います", message: "")
                }
            }

            dialogVC.modalPresentationStyle = .overCurrentContext
            dialogVC.modalTransitionStyle = .crossDissolve
            self.present(dialogVC, animated: true)
        }
    }


    // MARK: - Other Methods
    
    private func configureBarButtonItems(){
        // 左端のキャンセルボタン（アイコン）
        let backImage = UIImage(named: "cancel")
        let backButton = UIBarButtonItem(image: backImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(backlButtonPressed(_:)))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func backlButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureUI() {
        if isGoalReached {
            hiddenPlaceLabel.text = hidingPlace
            hiddenPlaceLabel.isHidden = false
            quesitonMarkImageView.isHidden = true
        } else {
            hiddenPlaceLabel.isHidden = true
            quesitonMarkImageView.isHidden = false
        }
    }
    
    /// アクションシートを表示
    private func showActionSheet() {
        let actionSheet = UIAlertController(title: "アクションを選択",
                                            message: "以下から選択してください",
                                            preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "カメラで撮影", style: .default, handler: { _ in
            self.presentImagePicker(sourceType: .camera)
        }))
        actionSheet.addAction(UIAlertAction(title: "写真から選択", style: .default, handler: { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }))
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel))

        present(actionSheet, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true)
    }

    /// アラートを表示
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    ///Firebase から PIN 登録の有無を確認
    private func checkPinRegistered(for userID: String,
                                    completion: @escaping (Bool, Int?, String?) -> Void) {
        firebaseService.fetchDocument(collection: "users", documentID: userID) { (user: User?, error) in
            guard let user = user, error == nil else {
                completion(false, nil, nil)
                return
            }
            let pin = user.pin
            let hiddenPlace = user.hiddenPlace
            if pin != nil {
                completion(true, pin, hiddenPlace)
            } else {
                completion(false, nil, hiddenPlace)
            }
        }
    }

    /// Firebaseに保存
    private func saveHiddenPlaceAndPin(hiddenPlace: String, pin: Int, userID: String) {
        let saveData: [String: Any] = [
            "hidden_place": hiddenPlace,
            "pin": pin
        ]
        firebaseService.update(collection: "users", documentID: userID, data: saveData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "保存エラー", message: error.localizedDescription)
                } else {
                    self?.hidingPlace = hiddenPlace
                    self?.showAlert(title: "登録しました！", message: "")
                }
            }
        }
    }

    /// PIN認証処理
    private func validatePin(_ enteredPin: Int, correctPin: Int?) {
        guard let correctPin = correctPin else {
            showAlert(title: "暗唱番号が未登録です", message: "")
            return
        }

        if enteredPin == correctPin {
            // 認証成功 → アラート表示
            showAlert(title: "認証成功", message: "")

            // 認証成功後にPIN＆隠し場所ダイアログを表示
            guard let currentUser = UserSession.shared.currentUser else { return }
            let childID = currentUser.userName
            let dialogVC = CustomInputDialogViewController(pin: correctPin,
                                                           dialogMode: .registerHiddenPlaceAndPin)
            dialogVC.onRegister = { [weak self] hiddenPlace, pin in
                self?.saveHiddenPlaceAndPin(hiddenPlace: hiddenPlace, pin: pin, userID: childID)
                dialogVC.dismiss(animated: true)
            }
            dialogVC.modalPresentationStyle = .overCurrentContext
            dialogVC.modalTransitionStyle = .crossDissolve // フワッと表示
            self.present(dialogVC, animated: true)
        } else {
            // 認証失敗
            showAlert(title: "暗唱番号が違います", message: "")
        }
    }
}

// MARK: - Extension

extension PresentViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    /// 写真撮影後の処理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            // 撮影した画像を利用
            rewardImageView.image = image
            presentMarkImageView.isHidden = true
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    /// イメージピッカーコントローラーをキャンセルした
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
