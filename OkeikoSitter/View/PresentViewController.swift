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
    private var isDeletingRewardImage = false
    private var isLoadingRewardImage = false
    private var skipNextImageLoad = false

    /// 保存ボタンで保存する対象画像
    private var selectedRewardImage: UIImage?
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

        // ここでは画像ロードしない。
        // viewWillAppear -> Firestore最新取得 -> loadSavedRewardImage に一本化する。
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard !isDeletingRewardImage else {
            print("⚠️ 削除中のためviewWillAppearの再取得をスキップ")
            return
        }

        if skipNextImageLoad {
            print("⚠️ 削除直後のためviewWillAppearの再取得をスキップ")
            skipNextImageLoad = false
            return
        }

        fetchLatestUserDataFromFirestore()
    }

    // MARK: - IBActions

    /// カメラボタンをタップした
    @IBAction private func cameraButtonTapped(_ sender: Any) {
        showActionSheet()
    }

    /// 隠し場所登録・変更ボタンをタップした
    @IBAction private func registrationButtonTapped(_ sender: Any) {
        guard let currentUser = UserSession.shared.currentUser,
              let uid = Auth.auth().currentUser?.uid else { return }

        let documentID = uid
        let userName = currentUser.userName

        checkPinRegistered(for: documentID, userName: userName) { [weak self] isRegistered, pin, hiddenPlace in
            guard let self = self else { return }

            let mode: DialogMode = isRegistered ? .pinOnly : .registerHiddenPlaceAndPin
            let dialogVC = CustomInputDialogViewController(pin: pin, dialogMode: mode)

            dialogVC.onRegister = { [weak self] hiddenPlace, pin in
                self?.saveHiddenPlaceAndPin(
                    hiddenPlace: hiddenPlace,
                    pin: pin,
                    userID: documentID,
                    userName: userName
                )
                dialogVC.dismiss(animated: true)
            }

            dialogVC.onValidate = { enteredPin in
                guard let hiddenPlace = hiddenPlace else { return }

                if enteredPin == pin {
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
        guard !isDeletingRewardImage else {
            showAlert(title: "保存できません", message: "画像削除中です。")
            return
        }

        guard let image = selectedRewardImage else {
            showAlert(title: "画像がありません", message: "先にご褒美画像を選択してください")
            return
        }

        isManualSave = true
        showLoading()
        uploadToFirebaseStorage(image)
    }

    @IBAction func rewardImageDeleteButtonTapped(_ sender: Any) {
        deleteRewardImage()
    }

    // MARK: - Firestore Load

    private func fetchLatestUserDataFromFirestore() {
        guard let uid = Auth.auth().currentUser?.uid,
              let currentUser = UserSession.shared.currentUser else {
            return
        }

        showLoading()

        let userName = currentUser.userName

        print("🔄 Firestoreから最新データを取得: \(userName)")

        firebaseService.fetchDocument(collection: "users", documentID: uid) { [weak self] (account: Account?, error) in
            guard let self = self else { return }

            self.hideLoading()

            if let error = error {
                print("❌ Firestore取得エラー: \(error.localizedDescription)")
                return
            }

            guard let account = account else {
                print("❌ アカウントデータが見つかりません")
                return
            }

            guard let matchedUser = account.users.first(where: { $0.userName == userName }) else {
                print("❌ ユーザー \(userName) のデータが見つかりません")
                return
            }

            let updatedUser = UserSessionUser(
                userName: matchedUser.userName ?? "",
                challengeTask: matchedUser.challengeTask ?? "",
                challengePoint: matchedUser.challengePoint ?? 0,
                bonusPoint: matchedUser.bonusPoint ?? 0,
                goalPoint: matchedUser.goalPoint ?? 0,
                challengeDay: matchedUser.challengeDay ?? 0,
                hiddenPlace: matchedUser.hiddenPlace ?? "",
                profileImage: currentUser.profileImage,
                profileImageURL: matchedUser.profileImageURL,
                currentPoint: matchedUser.currentPoint ?? 0,
                pin: matchedUser.pin,
                selectedDates: matchedUser.selectedDates,
                rewardImageURL: matchedUser.rewardImageURL
            )

            UserSession.shared.selectCurrentUser(user: updatedUser)

            print("✅ Firestore最新データ取得完了")
            print("📸 rewardImageURL: \(updatedUser.rewardImageURL ?? "なし")")

            self.loadSavedRewardImage()
        }
    }

    // MARK: - Loading

    private func setupActivityIndicator() {
        activityIndicator.color = .gray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func showLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.startAnimating()
            self?.view.isUserInteractionEnabled = false
        }
    }

    private func hideLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.view.isUserInteractionEnabled = true
        }
    }

    private func configureBarButtonItems() {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

        if let cancelImage = UIImage(named: "cancel") {
            button.setImage(cancelImage, for: .normal)
            button.contentMode = .scaleAspectFit
        }

        button.addTarget(self, action: #selector(backlButtonPressed(_:)), for: .touchUpInside)

        let customBarButton = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = customBarButton
    }

    @objc func backlButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
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

    private func showActionSheet() {
        let actionSheet = UIAlertController(
            title: "アクションを選択",
            message: "以下から選択してください",
            preferredStyle: .actionSheet
        )

        actionSheet.addAction(UIAlertAction(title: "カメラで撮影", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .camera)
        })

        actionSheet.addAction(UIAlertAction(title: "写真から選択", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })

        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel))

        present(actionSheet, animated: true)
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            showAlert(title: "使用できません", message: "この端末では選択した機能を使用できません。")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true)
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })

        present(alert, animated: true)
    }

    // MARK: - PIN

    private func checkPinRegistered(
        for userID: String,
        userName: String,
        completion: @escaping (Bool, Int?, String?) -> Void
    ) {
        firebaseService.checkPinRegistered(
            collection: "users",
            documentID: userID,
            userName: userName,
            completion: completion
        )
    }

    private func saveHiddenPlaceAndPin(
        hiddenPlace: String,
        pin: Int,
        userID: String,
        userName: String
    ) {
        let userData: [String: Any] = [
            "hidden_place": hiddenPlace,
            "pin": pin
        ]

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
                    UserSession.shared.updateCurrentUser(hiddenPlace: hiddenPlace, pin: pin)
                }
            }
        }
    }

    // MARK: - Reward Image Load

    private func loadSavedRewardImage() {
        guard !isDeletingRewardImage else {
            print("⚠️ 削除中のため画像読み込みを中止")
            hideLoading()
            return
        }

        guard !isLoadingRewardImage else {
            print("⚠️ 画像読み込み中のため二重ロードを中止")
            return
        }

        if skipNextImageLoad {
            print("⚠️ 削除直後のため画像読み込みをスキップ")
            skipNextImageLoad = false
            hideLoading()
            return
        }

        guard let currentUser = UserSession.shared.currentUser else {
            return
        }

        selectedRewardImage = nil
        rewardImageView.image = nil
        presentMarkImageView.isHidden = false

        guard let rewardImageURL = currentUser.rewardImageURL,
              !rewardImageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("REWARD DEBUG: 画像URLなし")
            hideLoading()
            return
        }

        isLoadingRewardImage = true
        showLoading()

        let loadStartUsername = currentUser.userName
        let loadStartURL = rewardImageURL

        print("REWARD DEBUG: 画像読み込み開始")
        print("REWARD DEBUG: user = \(loadStartUsername)")
        print("REWARD DEBUG: url = \(loadStartURL)")

        UIImage.load(from: rewardImageURL) { [weak self] image in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoadingRewardImage = false
                self.hideLoading()

                guard !self.isDeletingRewardImage else {
                    print("⚠️ 削除中のため画像表示を無視")
                    return
                }

                let currentUsername = UserSession.shared.currentUser?.userName ?? ""
                let currentURL = UserSession.shared.currentUser?.rewardImageURL ?? ""

                guard currentUsername == loadStartUsername,
                      currentURL == loadStartURL,
                      !currentURL.isEmpty else {
                    print("⚠️ 古い画像ロード結果を無視")
                    return
                }

                if let image = image {
                    self.rewardImageView.image = image
                    self.presentMarkImageView.isHidden = true
                    print("✅ 画像表示成功")
                } else {
                    self.rewardImageView.image = nil
                    self.presentMarkImageView.isHidden = false
                    print("⚠️ 画像取得失敗")
                }
            }
        }
    }

    // MARK: - Reward Image Save

    private func uploadToFirebaseStorage(_ image: UIImage) {
        guard !isDeletingRewardImage else {
            hideLoading()
            return
        }

        guard let currentUser = UserSession.shared.currentUser,
              let uid = Auth.auth().currentUser?.uid else {
            hideLoading()
            showAlert(title: "エラー", message: "ユーザー情報が取得できませんでした")
            return
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            hideLoading()
            showAlert(title: "エラー", message: "画像データの変換に失敗しました")
            return
        }

        let oldImageURL = currentUser.rewardImageURL

        let safeUsername = currentUser.userName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ".", with: "_")

        // 固定パスではなくUUIDを入れる。
        // これで削除後に古いURLやキャッシュで上書き表示されにくくなる。
        let fileName = "\(safeUsername)_\(UUID().uuidString).jpg"
        let path = "users/\(uid)/rewards/\(fileName)"

        print("📸 ご褒美画像アップロード開始: \(path)")

        firebaseService.uploadDataToStorage(data: imageData, path: path) { [weak self] url, error in
            guard let self = self else { return }

            if self.isDeletingRewardImage {
                self.hideLoading()
                return
            }

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

            self.saveRewardImageURL(
                downloadURL.absoluteString,
                userName: currentUser.userName,
                userID: uid,
                oldImageURL: oldImageURL
            )
        }
    }

    private func saveRewardImageURL(
        _ urlString: String,
        userName: String,
        userID: String,
        oldImageURL: String?
    ) {
        guard !isDeletingRewardImage else {
            hideLoading()
            return
        }

        let userData: [String: Any] = [
            "reward_image_url": urlString
        ]

        let shouldShowSaveAlert = isManualSave

        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: userName,
            userData: userData
        ) { [weak self] error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.hideLoading()

                if self.isDeletingRewardImage {
                    return
                }

                if let error = error {
                    self.showAlert(title: "画像URL保存エラー", message: error.localizedDescription)
                    return
                }

                UserSession.shared.updateCurrentUser(rewardImageURL: urlString)

                self.selectedRewardImage = nil
                self.isManualSave = false

                // 新URL保存成功後に、古いStorage画像を削除
                if let oldImageURL,
                   !oldImageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   oldImageURL != urlString {
                    self.deleteStorageImageIfNeeded(urlString: oldImageURL)
                }

                if shouldShowSaveAlert {
                    self.showAlert(title: "ご褒美画像を保存しました", message: "")
                }
            }
        }
    }

    // MARK: - Reward Image Delete

    private func deleteRewardImage() {
        guard let currentUser = UserSession.shared.currentUser,
              let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "削除エラー", message: "選択中ユーザーを取得できませんでした。")
            return
        }

        let oldImageURL = currentUser.rewardImageURL

        guard let oldImageURL,
              !oldImageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            selectedRewardImage = nil
            rewardImageView.image = nil
            presentMarkImageView.isHidden = false
            showAlert(title: "削除するデータがありません", message: "")
            return
        }

        isDeletingRewardImage = true
        isManualSave = false
        isLoadingRewardImage = false
        skipNextImageLoad = true
        selectedRewardImage = nil

        showLoading()

        rewardImageView.image = nil
        presentMarkImageView.isHidden = false

        // メモリ上のURLを先に空にする。
        // これで古い非同期ロード結果が戻ってきても表示されにくくなる。
        UserSession.shared.updateCurrentUser(rewardImageURL: "")

        let userData: [String: Any] = [
            "reward_image_url": ""
        ]

        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: uid,
            userName: currentUser.userName,
            userData: userData
        ) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.hideLoading()
                    self.isDeletingRewardImage = false
                    self.skipNextImageLoad = false
                    self.showAlert(title: "削除エラー", message: error.localizedDescription)
                }
                return
            }

            self.deleteStorageImageIfNeeded(urlString: oldImageURL)

            DispatchQueue.main.async {
                self.hideLoading()

                self.rewardImageView.image = nil
                self.presentMarkImageView.isHidden = false
                self.selectedRewardImage = nil
                self.isManualSave = false

                self.showAlert(title: "画像を削除しました", message: "") { [weak self] in
                    guard let self = self else { return }
                    self.isDeletingRewardImage = false
                    self.skipNextImageLoad = false
                }
            }
        }

        if let presentingVC = presentingViewController as? UINavigationController,
           let mainVC = presentingVC.viewControllers.first as? MainViewController {
            mainVC.setNeedsReload()
        } else {
            print("⚠️ MainViewControllerが見つかりません")
        }
    }

    private func deleteStorageImageIfNeeded(urlString: String) {
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let storageRef = Storage.storage().reference(forURL: urlString)

        storageRef.delete { error in
            if let error = error {
                print("⚠️ Storage削除エラー: \(error.localizedDescription)")
            } else {
                print("✅ Storage内の実ファイル削除完了")
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension PresentViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        guard !isDeletingRewardImage else {
            picker.dismiss(animated: true)
            return
        }

        if let image = info[.originalImage] as? UIImage {
            selectedRewardImage = image
            rewardImageView.image = image
            presentMarkImageView.isHidden = true

            isManualSave = false
            skipNextImageLoad = false

            print("📸 画像を選択しました。保存ボタンを押すまでFirebaseには保存しません。")
        }

        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
