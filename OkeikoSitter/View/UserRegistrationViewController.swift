//
//  UserRegistrationViewController.swift
//  OkeikoSitter
//
//  Created by 高橋智一 on 2025/09/18.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

/// デリゲートのプロトコル
protocol UserRegistrationViewControllerDelegete: AnyObject {
    /// 登録ボタンがタップされた
    func didTapSaveButton()
}

/// ユーザーを登録する画面
final class UserRegistrationViewController: UIViewController {
    
    // MARK: - Stored Properties
    
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    /// 選択した画像
    private var selectedImage: UIImage?
    /// デリゲートのプロパティ
    weak var delegate: UserRegistrationViewControllerDelegete?
    
    // MARK: - IBOutlets
    
    /// プロフィール画像
    @IBOutlet private weak var profileImageView: UIImageView!
    /// ユーザー名テキストフィールド
    @IBOutlet private weak var userNameTextField: UITextField!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gifImage2.loadGif(name: "present")
        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK: - IBActions
    
    /// 画像選択ボタンをタップした
    @IBAction private func imageSelectionButtonTapped(_ sender: Any) {
        presentImagePicker()
    }
    /// 登録ボタンをタップした
    @IBAction private func saveButtonTapped(_ sender: Any) {
        guard let userName = userNameTextField.text, let image = selectedImage else { return }
        uploadProfileImage(image, userName: userName)
    }
    
    // MARK: - IBOutlets
    
    /// GIF画像を表示するためにIBOutlet接続
    @IBOutlet private weak var gifImage2: UIImageView!
    
    // MARK: - Other Methods
    
    /// プロフィール画像をアップロード
    private func uploadProfileImage(_ image: UIImage, userName: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let userID = Auth.auth().currentUser?.uid else { return }
        let path = "profile_images/\(userName).jpg"
        
        firebaseService.uploadDataToStorage(data: imageData, path: path) { [weak self] url, error in
            if let error = error {
                self?.showAlert(title: "画像アップロード失敗", message: error.localizedDescription)
                return
            }
            guard let downloadURL = url else {
                self?.showAlert(title: "画像URL取得失敗")
                return
            }
            print("アップロード成功: \(downloadURL)")
            // Firestoreのユーザードキュメントに画像URLを保存したい場合はここで更新
            self?.saveProfileImageURL(downloadURL.absoluteString,
                                      userID: userID,
                                      userName: userName)
        }
    }
    
    /// プロフィール画像を保存
    private func saveProfileImageURL(_ urlString: String, userID: String, userName: String) {
        let imageData = ["profile_image_url": urlString]
        firebaseService.update(collection: "users", documentID: userID, data: imageData) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(title: "プロフィール画像URL保存失敗", message: error.localizedDescription)
            }
            self.saveData(userID: userID, userName: userName, profileImageURL: urlString)
        }
    }
    
    /// ユーザーを保存
    private func saveData(userID: String, userName: String, profileImageURL: String) {
        let newUserData: [String: Any] = [
            "is_parent": true,
            "user_name": userName,
            "challenge_task": "",
            "challenge_point": 0,
            "bonus_point": 0,
            "goal_point": 0,
            "challenge_day": 0,
            "hidden_place": "",
            "current_point": 0,
            "profile_image_url": profileImageURL
        ]
        
        firebaseService.update(
            collection: "users",
            documentID: userID,
            data: ["users": FieldValue.arrayUnion([newUserData])]
        ) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(title: "ユーザー登録失敗", message: error.localizedDescription)
            } else {
                // UserSession に追加
                let newUser = UserSessionUser(
                    isParent: true,
                    userName: userName,
                    challengeTask: "",
                    challengePoint: 0,
                    bonusPoint: 0,
                    goalPoint: 0,
                    challengeDay: 0,
                    hiddenPlace: "",
                    profileImage: nil,
                    profileImageURL: profileImageURL,
                    currentPoint: 0
                )
                UserSession.shared.addUser(user: newUser)
                
                self.showAlert(title: "登録しました！") {
                    self.delegate?.didTapSaveButton()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    /// アラートを表示
    private func showAlert(title: String, message: String = "",
                           completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension UserRegistrationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /// イメージピッカーを表示
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    /// 選択完了時
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let selectedImage = info[.originalImage] as? UIImage {
            profileImageView.image = selectedImage
            self.selectedImage = selectedImage
        }
    }
    
    /// キャンセル時
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
