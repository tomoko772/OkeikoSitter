//
//  UserListViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/07.
//

import UIKit
import FirebaseAuth

/// デリゲートのプロトコル
protocol UserListViewControllerDelegete: AnyObject {
    func didSelectCurrentUser()
}

/// ユーザー一覧画面
final class UserListViewController: UIViewController {
    
    // MARK: - Stored Properties
    
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    /// デリゲートのプロパティ
    weak var delegate: UserListViewControllerDelegete?
    
    // MARK: - IBOutlets
    
    /// テーブルビューを表示するためのIBOutlet接続
    @IBOutlet private weak var userTableView: UITableView!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        configureTableView()
        fetchData()
    }
    
    // MARK: - IBActions
    
    /// 追加ボタンをタップした
    @IBAction private func userAddButtonTapped(_ sender: Any) {
        navigateToUserRegister()
    }
    
    // MARK: - Other Methods
    
    private func configureBarButtonItems(){
        // 左端のキャンセルボタン（アイコン）
        let cancelImage = UIImage(named: "cancel")
        let cancelButton = UIBarButtonItem(image: cancelImage,
                                           style: .plain,
                                           target: self,
                                           action: #selector(cancelButtonPressed(_:)))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureTableView() {
        userTableView.dataSource = self
        userTableView.delegate = self
        // カスタムセル
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
        userTableView.register(nib, forCellReuseIdentifier: "Cell")
        userTableView.rowHeight = 78
    }
    
    /// ユーザー登録画面へ遷移
    private func navigateToUserRegister() {
        let vc = UserRegistrationViewController()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 現在のユーザーを登録
    private func saveCurrentUser(selectedUser: UserSessionUser) {
        if let accountID = UserSession.shared.accountID {
            // Firestoreに current_user として保存
            let currentUserData: [String: Any] = [
                "is_parent": selectedUser.isParent,
                "user_name": selectedUser.userName,
                "challenge_task": selectedUser.challengeTask,
                "challenge_point": selectedUser.challengePoint,
                "bonus_point": selectedUser.bonusPoint,
                "goal_point": selectedUser.goalPoint,
                "challenge_day": selectedUser.challengeDay,
                "hidden_place": selectedUser.hiddenPlace,
                "profile_image_url": selectedUser.profileImageURL ?? "",
                "current_point": selectedUser.currentPoint
            ]
            FirebaseService.shared.update(
                collection: "users",
                documentID: accountID,
                data: ["current_user": currentUserData]
            ) { error in
                if let error = error {
                    print("currentUser 保存失敗: \(error.localizedDescription)")
                } else {
                    print("currentUser 保存成功: \(currentUserData)")
                    self.delegate?.didSelectCurrentUser()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    /// データを取得する
    private func fetchData() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        firebaseService.fetchDocument(collection: "users",
                                      documentID: currentUserID) { (accountData: Account?, error) in
            if let error = error {
                print("取得エラー: \(error)")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard let firestoreUsers = accountData?.users, !firestoreUsers.isEmpty else { return }
                
                // UserSession にセット
                let sessionUsers = firestoreUsers.map { user in
                    UserSessionUser(
                        userName: user.userName,
                        challengeTask: user.challengeTask,
                        challengePoint: user.challengePoint,
                        bonusPoint: user.bonusPoint,
                        goalPoint: user.goalPoint,
                        challengeDay: user.challengeDay,
                        hiddenPlace: user.hiddenPlace,
                        profileImage: nil,
                        profileImageURL: user.profileImageURL,
                        currentPoint: user.challengePoint
                    )
                }
                UserSession.shared.setUsers(sessionUsers)
                
                // TableView 更新
                self.userTableView.reloadData()
                
                // 画像を取得
                self.fetchUserImages()
            }
        }
    }
    
    /// プロフィール画像を取得
    private func fetchUserImages() {
        for (index, user) in UserSession.shared.users.enumerated() {
            // 既に画像がある場合は取得しない
            if user.profileImage != nil { continue }
            
            FirebaseService.shared.fetchImageFromStorage(path: "profile_images/\(user.userName).jpg") { image in
                guard let image = image else { return }
                
                // UserSessionUser に画像をセット
                UserSession.shared.updateProfileImage(for: user.userName, image: image)
                
                // 該当セルだけ更新
                DispatchQueue.main.async {
                    self.userTableView.reloadRows(at: [IndexPath(row: index, section: 0)],
                                                  with: .automatic)
                }
            }
        }
    }
    
    /// ユーザーを削除
    private func deleteUser(_ user: UserSessionUser, at indexPath: IndexPath) {
        guard let accountID = UserSession.shared.accountID else { return }

        // ローカル削除
        UserSession.shared.setUsers(
            UserSession.shared.users.filter { $0.userName != user.userName }
        )

        // Firestoreデータ形式に変換
        let updatedUsersData = UserSession.shared.users.map { $0.toDictionary() }

        // Firestoreに書き戻し
        FirebaseService.shared.update(
            collection: "users",
            documentID: accountID,
            data: ["users": updatedUsersData]
        ) { [weak self] error in
            if let error = error {
                print("ユーザー削除失敗: \(error.localizedDescription)")
            } else {
                print("Firestore更新成功: \(user.userName) を削除しました")

                // テーブル更新
                DispatchQueue.main.async {
                    self?.userTableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension UserListViewController: UITableViewDataSource {
    /// データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserSession.shared.users.count
    }
    
    /// 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = UserSession.shared.users[indexPath.row]
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                                 for: indexPath)as! UserTableViewCell
        cell.configure(profileImage: user.profileImage, userName: user.userName)
        cell.delegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate
extension UserListViewController: UITableViewDelegate {
    /// セルをタップされた時のメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = UserSession.shared.users[indexPath.row]
        UserSession.shared.selectCurrentUser(user: selectedUser)
        // Firestore に currentUser を保存
        saveCurrentUser(selectedUser: selectedUser)
    }
}

// MARK: - UserRegistrationViewControllerDelegete

extension UserListViewController: UserRegistrationViewControllerDelegate {
    func didTapSaveButton() {
        fetchData()
    }
}

// MARK: - UserTableViewCellDelegete

extension UserListViewController: UserTableViewCellDelegete {
    func didTapDeleteButton(in cell: UserTableViewCell) {
        guard let indexPath = userTableView.indexPath(for: cell) else { return }
        let user = UserSession.shared.users[indexPath.row]
        
        let alert = UIAlertController(
            title: "削除しますか？",
            message: "\(user.userName) を削除します。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        alert.addAction(UIAlertAction(title: "削除", style: .destructive) { [weak self] _ in
            self?.deleteUser(user, at: indexPath)
        })
        present(alert, animated: true)
    }
}
