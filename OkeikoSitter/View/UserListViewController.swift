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
        // カスタムボタンを作成
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        // キャンセルアイコンを設定
        if let cancelImage = UIImage(named: "cancel") {
            button.setImage(cancelImage, for: .normal)
            button.contentMode = .scaleAspectFit
        }
        
        // ボタンアクションを設定
        button.addTarget(self, action: #selector(cancelButtonPressed(_:)), for: .touchUpInside)
        
        // UIBarButtonItem化して設定
        let customBarButton = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = customBarButton
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
        guard let accountID = UserSession.shared.accountID else {
            print("❌ accountIDがnil")
            return
        }
        
        // Firestoreから最新データを取得して確実に最新状態を維持する
        firebaseService.fetchDocument(collection: "users", documentID: accountID) { [weak self] (accountData: Account?, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ アカウントデータ取得失敗: \(error.localizedDescription)")
                return
            }
            
            guard let accountData = accountData else {
                print("❌ アカウントデータが見つかりません")
                return
            }
            
            // 最新のユーザーデータを取得
            let users = accountData.users
            guard let latestUserData = users.first(where: { $0.userName == selectedUser.userName }) else {
                print("❌ ユーザー \(selectedUser.userName) のデータが見つかりません")
                return
            }
            
            // 最新のデータでUserSessionUserを更新
            let updatedUser = UserSessionUser(
                userName: latestUserData.userName ?? "",
                challengeTask: latestUserData.challengeTask ?? "",
                challengePoint: latestUserData.challengePoint ?? 0,
                bonusPoint: latestUserData.bonusPoint ?? 0,
                goalPoint: latestUserData.goalPoint ?? 0,
                challengeDay: latestUserData.challengeDay ?? 0,
                hiddenPlace: latestUserData.hiddenPlace ?? "",
                profileImage: selectedUser.profileImage, // 元のプロフィール画像は維持
                profileImageURL: latestUserData.profileImageURL,
                currentPoint: latestUserData.currentPoint ?? 0,
                pin: latestUserData.pin,
                selectedDates: latestUserData.selectedDates,
                rewardImageURL: latestUserData.rewardImageURL
            )
            
            let userName = updatedUser.userName
            // selectedUser から辞書生成（toDictionary を使用して完全に同じ構造にする）
            let currentUserData = updatedUser.toDictionary()
            
            // 重要なフィールドについてログ出力
            print("📝 ユーザー切り替え: \(updatedUser.userName)")
            print("📝 hiddenPlace: \(updatedUser.hiddenPlace)")
            print("📝 rewardImageURL: \(updatedUser.rewardImageURL ?? "なし")")
            
            // 修正後のユーザーを先にセット
            UserSession.shared.selectCurrentUser(user: updatedUser)
            
            print("📝 ユーザー切り替え: \(userName), ポイント: \(updatedUser.currentPoint)")
            
            // updateUserAndCurrentUser を使用して両方更新
            self.firebaseService.updateUserAndCurrentUser(
                collection: "users",
                documentID: accountID,
                userName: userName,
                userData: currentUserData
            ) { [weak self] error in
                if let error = error {
                    print("❌ currentUser 保存失敗: \(error.localizedDescription)")
                } else {
                    print("✅ currentUser 保存成功")
                    self?.delegate?.didSelectCurrentUser()
                    self?.dismiss(animated: true, completion: nil)
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
                guard let accountData = accountData else { return }
            
            // users配列を直接取得（非Optionalの配列なのでnilチェックは不要）
            let firestoreUsers = accountData.users
            if firestoreUsers.isEmpty { return }
                
                // UserSession にセット
                let sessionUsers = firestoreUsers.map { user in
                    UserSessionUser(
                        userName: user.userName ?? "",
                        challengeTask: user.challengeTask ?? "",
                        challengePoint: user.challengePoint ?? 0,
                        bonusPoint: user.bonusPoint ?? 0,
                        goalPoint: user.goalPoint ?? 0,
                        challengeDay: user.challengeDay ?? 0,
                        hiddenPlace: user.hiddenPlace ?? "",
                        profileImage: nil,
                        profileImageURL: user.profileImageURL,
                        currentPoint: user.currentPoint ?? 0,
                        pin: user.pin
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
        if let fileURL = rewardImageFileURL(for: user) {
                do {
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        try FileManager.default.removeItem(at: fileURL)
                        print("ご褒美画像を削除しました: \(fileURL.lastPathComponent)")
                    }
                } catch {
                    print("ご褒美画像削除失敗: \(error.localizedDescription)")
                }
            }
        
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
    
    /// 指定ユーザーのご褒美画像ファイルURL
    private func rewardImageFileURL(for user: UserSessionUser) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                          in: .userDomainMask).first
        
        let safeUserName = user.userName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        return documentsDirectory?.appendingPathComponent("reward_\(safeUserName).jpg")
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
