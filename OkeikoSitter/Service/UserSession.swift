//
//  UserSession.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/09/17.
//

import UIKit

/// ログインユーザーの情報を管理するシングルトン
final class UserSession {

    // MARK: - Type Properties

    static let shared = UserSession()

    // MARK: - Stored Properties

    /// アカウントIDを保持
    private(set) var accountID: String?
    /// ユーザー一覧を保持
    private(set) var users: [UserSessionUser] = []
    /// 現在のユーザーを保持
    private(set) var currentUser: UserSessionUser?

    // MARK: - Initializers

    private init() {}

    // MARK: - Other Methods

    /// 初回取得時に設定する
    func setUserID(accountID: String) {
        self.accountID = accountID
    }

    /// 現在のユーザーを決定
    func selectCurrentUser(user: UserSessionUser) {
        self.currentUser = user
    }

    /// ユーザー名と画像を更新
    func addUser(user: UserSessionUser) {
        self.users.append(user)
    }

    /// ユーザー一覧をまとめてセット
    func setUsers(_ users: [UserSessionUser]) {
        self.users = users
    }

    /// 画像を更新
    func updateProfileImage(for userName: String, image: UIImage) {
        guard let index = users.firstIndex(where: { $0.userName == userName }) else { return }
        users[index].profileImage = image
    }

    /// カレントユーザー情報を更新
    func updateCurrentUser(profileImageURL: String?, profileImage: UIImage?) {
        guard var user = currentUser else { return }
        user.profileImageURL = profileImageURL
        user.profileImage = profileImage
        currentUser = user
    }

    /// ユーザー画像を更新
    func updateProfileImage(_ image: UIImage) {
        currentUser?.profileImage = image
    }

    /// 現在のポイントを更新
    func updateCurrentPoint(_ currentPoint: Int) {
        currentUser?.currentPoint = currentPoint
    }

    /// クリアしたいとき（ログアウトなど）
    func clear() {
        self.accountID = nil
        self.users = []
        self.currentUser = nil
    }
}
