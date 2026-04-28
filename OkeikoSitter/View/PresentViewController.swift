//
//  PresentViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/22.
//

import UIKit
import FirebaseAuth

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
    
    // MARK: - Initializers
    
    init(isGoalReached: Bool = false, hidingPlace: String = "") {
        self.isGoalReached = isGoalReached
        self.hidingPlace = hidingPlace
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        configureUI()
        loadSavedRewardImage()
    }
    
    // MARK: - IBActions
    
    /// カメラボタンをタップした
    @IBAction private func cameraButtonTapped(_ sender: Any) {
        showActionSheet()
    }
    
    /// 隠し場所登録・変更ボタンをタップした
    @IBAction private func registrationButtonTapped(_ sender: Any) {
        // 現在選択中のユーザーを取得
        guard let currentUser = UserSession.shared.currentUser,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        let documentID = uid
        let userName = currentUser.userName
        
        // 選択中ユーザー用のPIN登録済みかを確認する
        checkPinRegistered(for: documentID, userName: userName) { [weak self] isRegistered, pin, hiddenPlace in
            guard let self = self else { return }
            let mode: DialogMode = isRegistered ? .pinOnly : .registerHiddenPlaceAndPin
            let dialogVC = CustomInputDialogViewController(pin: pin, dialogMode: mode)
            
            // 登録コールバック
            dialogVC.onRegister = { [weak self] hiddenPlace, pin in
                self?.saveHiddenPlaceAndPin(hiddenPlace: hiddenPlace, pin: pin, userID: documentID, userName: userName)
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
    
    @IBAction func ewardImageSaveButtonTapped(_ sender: Any) {
        saveRewardImage()
    }
    
    @IBAction func rewardImageDeleteButtonTapped(_ sender: Any) {
        deleteRewardImage()
    }
    
    // MARK: - Other Methods
    
    private func configureBarButtonItems(){
        // カスタムボタンを作成
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        // キャンセルアイコンを設定
        if let cancelImage = UIImage(named: "cancel") {
            button.setImage(cancelImage, for: .normal)
            button.contentMode = .scaleAspectFit
        }
        
        // ボタンアクションを設定
        button.addTarget(self, action: #selector(backlButtonPressed(_:)), for: .touchUpInside)
        
        // UIBarButtonItem化して設定
        let customBarButton = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = customBarButton
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
    
    ///Firebase から PIN 登録の有無を確認 (ユーザー名指定)
    private func checkPinRegistered(for userID: String,
                                    userName: String,
                                    completion: @escaping (Bool, Int?, String?) -> Void) {
        firebaseService.checkPinRegistered(
            collection: "users",
            documentID: userID,
            userName: userName,
            completion: completion
        )
    }
    
    /// Firebaseに保存 (ユーザー名指定)
    private func saveHiddenPlaceAndPin(hiddenPlace: String, pin: Int, userID: String, userName: String) {
        // 現在のユーザー情報に対して、hiddenPlaceとpinを更新
        let userData: [String: Any] = [
            "hidden_place": hiddenPlace,
            "pin": pin
        ]
        
        // ユーザー名を指定した更新処理
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: userName,
            userData: userData
        ) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "保存エラー", message: error.localizedDescription)
                } else {
                    self?.hidingPlace = hiddenPlace
                    self?.showAlert(title: "登録しました！", message: "")
                    
                    // UserSessionも更新
                    UserSession.shared.updateCurrentUser(hiddenPlace: hiddenPlace, pin: pin)
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
            guard let currentUser = UserSession.shared.currentUser,
                  let uid = Auth.auth().currentUser?.uid else { return }
            let documentID = uid
            let userName = currentUser.userName
            let dialogVC = CustomInputDialogViewController(pin: correctPin,
                                                           dialogMode: .registerHiddenPlaceAndPin)
            dialogVC.onRegister = { [weak self] hiddenPlace, pin in
                self?.saveHiddenPlaceAndPin(hiddenPlace: hiddenPlace, pin: pin, userID: documentID, userName: userName)
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
    
    /// ご褒美画像の保存先URL
    private func rewardImageFileURL() -> URL? {
        guard let currentUser = UserSession.shared.currentUser else { return nil }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                          in: .userDomainMask).first
        
        let safeUserName = currentUser.userName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        return documentsDirectory?.appendingPathComponent("reward_\(safeUserName).jpg")
    }
    
    /// ご褒美画像を保存（Firebase Storageを使用）
    private func saveRewardImage() {
        guard let image = rewardImageView.image else {
            showAlert(title: "画像がありません", message: "先にご褒美画像を選択してください。")
            return
        }
        
        // Firebase Storageに画像をアップロード
        uploadToFirebaseStorage(image)
    }
    
    /// 保存済みご褒美画像を読み込む（Firebase Storage対応）
    private func loadSavedRewardImage() {
        guard let currentUser = UserSession.shared.currentUser else { return }
        
        // ローカルファイルをまず確認（後方互換性のため）
        if let fileURL = rewardImageFileURL(),
           FileManager.default.fileExists(atPath: fileURL.path),
           let savedImage = UIImage(contentsOfFile: fileURL.path) {
            rewardImageView.image = savedImage
            presentMarkImageView.isHidden = true
            return
        }
        
        // この時点でcurrentUserのrewardImageURLがあるか確認
        if let rewardImageURL = currentUser.rewardImageURL, !rewardImageURL.isEmpty {
            // すでにUserSessionに保存されている画像URLを使用
            UIImage.load(from: rewardImageURL) { [weak self] image in
                guard let self = self, let image = image else { return }
                
                DispatchQueue.main.async {
                    self.rewardImageView.image = image
                    self.presentMarkImageView.isHidden = true
                }
            }
            return
        }
        
        // ここまでくると画像は設定されていない
        rewardImageView.image = nil
        presentMarkImageView.isHidden = false
    }
    
    /// ご褒美画像を削除（Firebase Storage対応）
    private func deleteRewardImage() {
        guard let currentUser = UserSession.shared.currentUser, 
              let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "削除エラー", message: "選択中ユーザーを取得できませんでした。")
            return
        }
        
        // ローカルファイルがあれば削除（後方互換性のため）
        if let fileURL = rewardImageFileURL(), FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("ローカルファイル削除エラー: \(error.localizedDescription)")
            }
        }
        
        // Firebase Storageから削除
        let safeUserName = currentUser.userName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let path = "reward_images/\(safeUserName).jpg"
        
        firebaseService.deleteFileFromStorage(path: path) { [weak self] error in
            if let error = error {
                print("Firebase Storage削除エラー: \(error.localizedDescription)")
            }
            
            // Firestoreのユーザー情報も更新（URLを削除）
            let userData: [String: Any] = [
                "reward_image_url": ""
            ]
            
            self?.firebaseService.updateUserAndCurrentUser(
                collection: "users",
                documentID: uid,
                userName: currentUser.userName,
                userData: userData
            ) { [weak self] error in
                DispatchQueue.main.async {
                    // 画面表示を元に戻す
                    self?.rewardImageView.image = nil
                    self?.presentMarkImageView.isHidden = false
                    
                    if let error = error {
                        self?.showAlert(title: "削除エラー", message: error.localizedDescription)
                    } else {
                        // UserSessionのcurrentUserも更新（メモリ上）
                        UserSession.shared.updateCurrentUser(rewardImageURL: "")
                        self?.showAlert(title: "削除しました！", message: "")
                    }
                }
            }
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
            
            // 自動的にFirebase Storageにアップロード
            uploadToFirebaseStorage(image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    /// イメージピッカーコントローラーをキャンセルした
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    /// Firebase Storageに画像をアップロード
    private func uploadToFirebaseStorage(_ image: UIImage) {
        guard let currentUser = UserSession.shared.currentUser,
              let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "エラー", message: "ユーザー情報が取得できませんでした")
            return
        }
        
        // JPEGデータに変換
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showAlert(title: "エラー", message: "画像データの変換に失敗しました")
            return
        }
        
        // 保存パス（ユーザー名を含む）
        let safeUserName = currentUser.userName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let path = "reward_images/\(safeUserName).jpg"
        
        // Firebase Storageにアップロード
        firebaseService.uploadDataToStorage(data: imageData, path: path) { [weak self] url, error in
            if let error = error {
                self?.showAlert(title: "画像アップロード失敗", message: error.localizedDescription)
                return
            }
            
            guard let downloadURL = url else {
                self?.showAlert(title: "画像URL取得失敗", message: "")
                return
            }
            
            print("ご褒美画像アップロード成功: \(downloadURL)")
            
            // Firestoreにユーザー情報の一部としてURLを保存
            self?.saveRewardImageURL(downloadURL.absoluteString, userName: currentUser.userName, userID: uid)
        }
    }
    
    /// ご褒美画像URLをFirestoreに保存
    private func saveRewardImageURL(_ urlString: String, userName: String, userID: String) {
        // ご褒美画像のURL情報を更新
        let userData: [String: Any] = [
            "reward_image_url": urlString
        ]
        
        // ユーザー名を指定した更新処理
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: userName,
            userData: userData
        ) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "画像URL保存エラー", message: error.localizedDescription)
                } else {
                    // UserSessionのcurrentUserを更新（メモリ上）
                    UserSession.shared.updateCurrentUser(rewardImageURL: urlString)
                    self?.showAlert(title: "ご褒美画像を保存しました！", message: "")
                }
            }
        }
    }
}
