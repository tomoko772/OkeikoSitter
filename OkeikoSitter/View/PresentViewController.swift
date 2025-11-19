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
    /// 暗唱番号が登録されているかどうか
    private var isPinRegistered: Bool = false
    
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
        guard let userID = UserSession.shared.accountID else { return }
        checkPinRegistered(for: userID) { [weak self] (isRegistered, pin) in
            DispatchQueue.main.async {
                if isRegistered {
                    self?.presentPinInputDialog(pin: pin)
                } else {
                    let dialogVC = CustomInputDialogViewController(pin: pin,
                                                                   dialogMode: .registerHiddenPlaceAndPin)
                    dialogVC.modalPresentationStyle = .overCurrentContext
                    self?.present(dialogVC, animated: true)
                }
            }
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
        
        // カメラで撮影
        let cameraAction = UIAlertAction(title: "カメラで撮影",
                                         style: .default,
                                         handler: { (action: UIAlertAction) -> Void in
            // ボタンが押された時の処理
            self.presentImagePicker(sourceType: .camera)
        })
        
        // 写真から選択
        let photoAction = UIAlertAction(title: "写真から選択",
                                        style: .default,
                                        handler: { (action: UIAlertAction) -> Void in
            // ボタンが押された時の処理
            self.presentImagePicker(sourceType: .photoLibrary)
            
        })
        
        // キャンセルボタン
        let cancelAction = UIAlertAction(title: "キャンセル",
                                         style: .cancel,
                                         handler: { (action: UIAlertAction) -> Void in
            // ボタンが押された時の処理
        })
        
        // UIAlertControllerにActionを追加
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(photoAction)
        actionSheet.addAction(cancelAction)
        
        // ActionSheetを表示
        present(actionSheet, animated: true, completion: nil)
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
    
    /// 暗唱番号が登録済みかのチェック
    private func checkPinRegistered(for userID: String, completion: @escaping (Bool, Int?) -> Void) {
        firebaseService.fetchDocument(collection: "users", documentID: userID) { (user: User?, error) in
            guard let user = user, error == nil else {
                completion(false, nil)
                return
            }
            if let pin = user.pin {
                completion(true, pin)
            } else {
                completion(false, nil)
            }
        }
    }
    
    /// 登録済みの場合のダイアログを表示
    private func presentPinInputDialog(pin: Int?) {
        let dialogVC = CustomInputDialogViewController(pin: pin, dialogMode: .pinOnly)
        dialogVC.modalPresentationStyle = .overCurrentContext
        present(dialogVC, animated: true)
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
