//
//  PresentViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/22.
//

import UIKit
import FirebaseAuth
import FirebaseStorage

/// ご褒美登録画面
final class PresentViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 隠し場所
    private var hidingPlace: String = ""
    /// 目標達成の有無
    private var isGoalReached: Bool = false
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    /// 手動保存かどうか（アラート表示制御用）
    private var isManualSave = false
    /// ローディングインジケータ
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    
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
        setupActivityIndicator()
        // 起動時にフラグをリセット
        isManualSave = false
        loadSavedRewardImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 画面表示時に必ずFirestoreから最新データを再取得
        fetchLatestUserDataFromFirestore()
    }
    
    /// Firestoreから最新のユーザーデータを取得
    private func fetchLatestUserDataFromFirestore() {
        guard let uid = Auth.auth().currentUser?.uid,
              let currentUser = UserSession.shared.currentUser else {
            return
        }
        
        // ローディング表示
        showLoading()
        
        // 現在のユーザー名を保持
        let userName = currentUser.userName
        
        print("🔄 Firestoreから最新データを取得: \(userName)")
        
        // ユーザードキュメントを取得
        firebaseService.fetchDocument(collection: "users", documentID: uid) { [weak self] (account: Account?, error) in
            guard let self = self else { return }
            
            // ローディング非表示
            self.hideLoading()
            
            if let error = error {
                print("❌ Firestore取得エラー: \(error.localizedDescription)")
                return
            }
            
            guard let account = account else {
                print("❌ アカウントデータが見つかりません")
                return
            }
            
            // 現在選択中のユーザーと同名のユーザーデータを探す
            let users = account.users
            guard let matchedUser = users.first(where: { $0.userName == userName }) else {
                print("❌ ユーザー \(userName) のデータが見つかりません")
                return
            }
            
            // UserSessionのキャッシュも更新
            let updatedUser = UserSessionUser(
                userName: matchedUser.userName ?? "",
                challengeTask: matchedUser.challengeTask ?? "",
                challengePoint: matchedUser.challengePoint ?? 0,
                bonusPoint: matchedUser.bonusPoint ?? 0,
                goalPoint: matchedUser.goalPoint ?? 0,
                challengeDay: matchedUser.challengeDay ?? 0,
                hiddenPlace: matchedUser.hiddenPlace ?? "",
                profileImage: currentUser.profileImage, // 既存の画像は維持
                profileImageURL: matchedUser.profileImageURL,
                currentPoint: matchedUser.currentPoint ?? 0,
                pin: matchedUser.pin,
                selectedDates: matchedUser.selectedDates,
                rewardImageURL: matchedUser.rewardImageURL
            )
            
            // UserSessionの内容を更新
            UserSession.shared.selectCurrentUser(user: updatedUser)
            
            print("✅ Firestoreから最新データを取得完了: \(userName)")
            print("📸 rewardImageURL: \(updatedUser.rewardImageURL ?? "なし")")
            
            // 最新データに基づいて画像を読み込む
            self.loadSavedRewardImage()
        }
    }
    
    /// ローディングインジケータの設定
    private func setupActivityIndicator() {
        // スタイル設定
        activityIndicator.color = .gray
        activityIndicator.hidesWhenStopped = true
        
        // 画面中央に配置
        activityIndicator.center = view.center
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // 制約を設定
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    /// ローディング表示の開始
    private func showLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.startAnimating()
            self?.view.isUserInteractionEnabled = false
        }
    }
    
    /// ローディング表示の終了
    private func hideLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.view.isUserInteractionEnabled = true
        }
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
        
        // PINがすでに設定されているか確認
        if let pin = currentUser.pin {
            print("✅ PINはすでに設定済み: \(userName), PIN: \(pin)")
        }
        
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
        // 既にrewardImageViewに画像がある場合のみ処理
        guard let image = rewardImageView.image else {
            showAlert(title: "画像がありません", message: "先にご褒美画像を選択してください")
            return
        }
        
        // 手動保存フラグを常にtrueに設定（画像選択時の自動保存は行わないため）
        isManualSave = true
        
        // ローディング表示開始
        showLoading()
        
        // Firebase Storageに直接アップロード
        uploadToFirebaseStorage(image)
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
    
    /// 保存済みご褒美画像を読み込む（Firebase Storage対応）
    private func loadSavedRewardImage() {
        guard let currentUser = UserSession.shared.currentUser else { return }
        
        // 毎回必ず画像表示をリセット
        rewardImageView.image = nil
        presentMarkImageView.isHidden = false
        
        // ローディングインジケータを表示
        showLoading()
        
        print("REWARD DEBUG: =========================================")
        print("REWARD DEBUG: 現在のユーザー: \(currentUser.userName)")
        print("REWARD DEBUG: 隠し場所: \(currentUser.hiddenPlace)")
        print("REWARD DEBUG: 画像URL: \(currentUser.rewardImageURL ?? "なし")")
        print("REWARD DEBUG: =========================================")
        
        // URLがないか空の場合はデフォルト表示のままにしてローディングを終了
        guard let rewardImageURL = currentUser.rewardImageURL, !rewardImageURL.isEmpty else {
            print("REWARD DEBUG: 画像URLなし - \(currentUser.userName)のデフォルト表示")
            hideLoading()
            return
        }
        
        // URL存在チェック
        guard let url = URL(string: rewardImageURL) else {
            print("REWARD DEBUG: 無効なURL形式")
            hideLoading()
            return
        }
        
        // URLのパスとユーザー名（デバッグログのみ）
        let path = url.path
        let safeUsername = currentUser.userName.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ".", with: "_")
        
        print("REWARD DEBUG: URL検証: \(url.absoluteString)")
        print("REWARD DEBUG: URL検証: ユーザー名一致確認: \(safeUsername).jpg")
        
        // 現在のユーザー名を保存して、コールバック時に確認
        let loadStartUsername = currentUser.userName
        
        UIImage.load(from: rewardImageURL) { [weak self] image in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // ローディングを終了
                self.hideLoading()
                
                // 現在表示中のユーザーが読み込み開始時と同じか確認
                let currentUsername = UserSession.shared.currentUser?.userName ?? ""
                if currentUsername == loadStartUsername {
                    if let image = image {
                        print("REWARD DEBUG: \(loadStartUsername)の画像取得成功: サイズ=\(image.size)")
                        self.rewardImageView.image = image
                        self.presentMarkImageView.isHidden = true
                    } else {
                        print("REWARD DEBUG: \(loadStartUsername)の画像取得失敗")
                        // 画像取得に失敗した場合もデフォルト表示に戻す
                        self.rewardImageView.image = nil
                        self.presentMarkImageView.isHidden = false
                    }
                } else {
                    print("REWARD DEBUG: ユーザー切り替え済み - 古い画像ロードを無視: \(loadStartUsername) → \(currentUsername)")
                }
            }
        }
    }
    
    /// ご褒美画像を削除（Firebase Storage対応）
    private func deleteRewardImage() {
        guard let currentUser = UserSession.shared.currentUser, 
              let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "削除エラー", message: "選択中ユーザーを取得できませんでした。")
            return
        }
        
        // ローディング表示開始
        showLoading()
        
        // まず画像表示をクリア
        rewardImageView.image = nil
        presentMarkImageView.isHidden = false
        
        // ローカルファイルがあれば削除（後方互換性のため）
        if let fileURL = rewardImageFileURL(), FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("ローカルファイルを削除しました: \(fileURL.path)")
            } catch {
                print("ローカルファイル削除エラー: \(error.localizedDescription)")
            }
        }
        
        // まず既存の画像URLを確認
        if let existingURL = currentUser.rewardImageURL, !existingURL.isEmpty {
            // この時点で保存されているURLが存在する場合、直接そのURLの参照を削除
            print("削除: 既存の画像URL: \(existingURL)")
            
            // urlからStorageの参照を取得
            let storageRef = Storage.storage().reference(forURL: existingURL)
            // 直接その参照を削除
            storageRef.delete { error in
                if let error = error {
                    print("Firebase Storage削除エラー: \(error.localizedDescription)")
                } else {
                    print("Firebase Storage: 既存画像を削除しました")
                }
            }
        } else {
            print("削除対象の画像URLが見つかりません")
        }
        
        // UserSessionのcurrentUserも先に更新（メモリ上）
        UserSession.shared.updateCurrentUser(rewardImageURL: "")
        
        // 以降はFirestoreのユーザー情報も更新
            
        // Firestoreのユーザー情報も更新（URLを削除）
        let userData: [String: Any] = [
            "reward_image_url": ""
        ]
            
        print("Firestore: ユーザー情報のURL参照を削除します")
        
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: uid,
            userName: currentUser.userName,
            userData: userData
        ) { [weak self] error in
            DispatchQueue.main.async {
                // ローディング表示終了
                self?.hideLoading()
                
                if let error = error {
                    print("Firestore更新エラー: \(error.localizedDescription)")
                    self?.showAlert(title: "削除エラー", message: error.localizedDescription)
                } else {
                    print("Firestore: ユーザーデータからURLを削除しました")
                    // isManualSaveをリセットして保存アラートが表示されないようにする
                    self?.isManualSave = false
                    self?.showAlert(title: "削除しました！", message: "")
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
            
            // 自動保存フラグをリセット（アラート表示しない）
            isManualSave = false
            
            // ImagePickerを閉じるだけ（保存しない）
            picker.dismiss(animated: true)
        } else {
            picker.dismiss(animated: true)
        }
    }
    
    /// イメージピッカーコントローラーをキャンセルした
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    /// Firebase Storageに画像をアップロード
    private func uploadToFirebaseStorage(_ image: UIImage) {
        guard let currentUser = UserSession.shared.currentUser,
              let uid = Auth.auth().currentUser?.uid else {
            hideLoading()
            showAlert(title: "エラー", message: "ユーザー情報が取得できませんでした")
            return
        }
        
        // UserSessionのURLクリア
        UserSession.shared.updateCurrentUser(rewardImageURL: "")
        
        // まず既存の画像を削除
        if let existingURL = currentUser.rewardImageURL, !existingURL.isEmpty {
            // この時点で保存されているURLが存在する場合、直接そのURLの参照を削除
            print("上書き: 既存の画像URL: \(existingURL)")
            
            // urlからStorageの参照を取得
            let storageRef = Storage.storage().reference(forURL: existingURL)
            // 直接その参照を削除
            storageRef.delete { error in
                if let error = error {
                    print("Firebase Storage削除エラー: \(error.localizedDescription)")
                } else {
                    print("Firebase Storage: 既存画像を削除しました")
                }
            }
        }
        
        // JPEGデータに変換
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            self.hideLoading()
            self.showAlert(title: "エラー", message: "画像データの変換に失敗しました")
            return
        }
        
        // 子ユーザーごとに固有のパスを生成
        let username = currentUser.userName
        
        // 各子ユーザーに固有のディレクトリ構造（パス情報に子ユーザー名を含める）
        let safeUsername = username.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ".", with: "_")
        
        // 各子ユーザーにユニークなパス（rewards_simple/ユーザー名.jpg）
        let path = "rewards_simple/\(safeUsername).jpg"
        
        print("新しい画像をアップロード: \(path)")
        
        // Firebase Storageにアップロード
        self.firebaseService.uploadDataToStorage(data: imageData, path: path) { [weak self] url, error in
            guard let self = self else { return }
                
                if let error = error {
                    self.hideLoading()
                    self.showAlert(title: "画像アップロード失敗", message: error.localizedDescription)
                    return
                }
                
                guard let downloadURL = url else {
                    self.hideLoading()
                    self.showAlert(title: "画像URL取得失敗", message: "")
                    return
                }
                
                print("ご褒美画像アップロード成功: \(downloadURL)")
                
                // Firestoreにユーザー情報の一部としてURLを保存
                self.saveRewardImageURL(downloadURL.absoluteString, userName: currentUser.userName, userID: uid)
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
                // ローディング表示終了
                self?.hideLoading()
                
                if let error = error {
                    self?.showAlert(title: "画像URL保存エラー", message: error.localizedDescription)
                } else {
                    // UserSessionのcurrentUserを更新（メモリ上）
                    UserSession.shared.updateCurrentUser(rewardImageURL: urlString)
                    
                    // 画像選択後の自動保存時はサイレントに処理、ボタン押下時のみ表示
                    if self?.isManualSave == true {
                        self?.showAlert(title: "ご褒美画像を保存しました！", message: "")
                        self?.isManualSave = false
                    }
                }
            }
        }
    }
}