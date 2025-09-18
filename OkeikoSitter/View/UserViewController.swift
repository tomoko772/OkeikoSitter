//
//  UserViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/07.
//

import UIKit

/// デリゲートのプロトコル
protocol UserViewControllerDelegete: AnyObject {
    func didSelectCurrentUser()
}

/// ユーザー登録画面
final class UserViewController: UIViewController {

    // MARK: - Stored Properties

    /// デリゲートのプロパティ
    weak var delegate: UserViewControllerDelegete?
    private var users: [UserSessionUser] = UserSession.shared.users

    // MARK: - IBOutlets
    
    /// テーブルビューを表示するためのIBOutlet接続
    @IBOutlet private weak var userTableView: UITableView!

    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        configureTableView()
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

}
// MARK: - UITableViewDataSource

extension UserViewController: UITableViewDataSource {
    /// データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    /// 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = users[indexPath.row]
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)as! UserTableViewCell
        cell.configure(profileImage: user.profileImage, userName: user.userName)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension UserViewController: UITableViewDelegate {
    /// セルをタップされた時のメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = users[indexPath.row]
        UserSession.shared.selectCurrentUser(user: selectedUser)
        // Firestore に currentUser を保存
        saveCurrentUser(selectedUser: selectedUser)
    }
}

// MARK: - UserRegistrationViewControllerDelegete

extension UserViewController: UserRegistrationViewControllerDelegete {
    func didTapSaveButton() {
        users = UserSession.shared.users
        userTableView.reloadData()
    }
}

