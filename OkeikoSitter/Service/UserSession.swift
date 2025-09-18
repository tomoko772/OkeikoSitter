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

    /// ユーザー画像を更新
    func updateProfileImage(_ image: UIImage) {
        currentUser?.profileImage = image
    }

    /// 現在のポイントを更新
    func updateCurrentPoint(_ currentPoint: Int) {
        currentUser?.currentPoint = currentPoint
    }

    /// 現在のボーナスポイントを更新
    func updateBonusPoint(_ bonusPoint: Int) {
        currentUser?.bonusPoint = bonusPoint
    }

    /// クリアしたいとき（ログアウトなど）
    func clear() {
        self.accountID = nil
        self.users = []
        self.currentUser = nil
    }
}
