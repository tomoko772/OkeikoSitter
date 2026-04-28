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
    // 選択済みの日付を保持
    private(set) var selectedDates: [TimeInterval] = []

    // MARK: - Initializers

    private init() {}

    // MARK: - Other Methods

    /// 選択日を currentUser と users 配列に反映
    func updateSelectedDates(for userName: String, timestamps: [TimeInterval]) {
        // users 配列内の該当ユーザーを更新
        if let index = users.firstIndex(where: { $0.userName == userName }) {
            users[index].selectedDates = timestamps
        }
        // currentUser がそのユーザーなら反映
        if currentUser?.userName == userName {
            currentUser?.selectedDates = timestamps
        }
    }

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
    func updateCurrentUser(
        userName: String? = nil,
        challengeTask: String? = nil,
        challengePoint: Int? = nil,
        bonusPoint: Int? = nil,
        goalPoint: Int? = nil,
        challengeDay: Int? = nil,
        hiddenPlace: String? = nil,
        profileImage: UIImage? = nil,
        profileImageURL: String? = nil,
        currentPoint: Int? = nil,
        pin: Int? = nil,
        selectedDates: [TimeInterval]? = nil,
        rewardImageURL: String? = nil
    ) {
        guard var user = currentUser else { return }

        if let userName = userName { user.userName = userName }
        if let challengeTask = challengeTask { user.challengeTask = challengeTask }
        if let challengePoint = challengePoint { user.challengePoint = challengePoint }
        if let bonusPoint = bonusPoint { user.bonusPoint = bonusPoint }
        if let goalPoint = goalPoint { user.goalPoint = goalPoint }
        if let challengeDay = challengeDay { user.challengeDay = challengeDay }
        if let hiddenPlace = hiddenPlace { user.hiddenPlace = hiddenPlace }
        if let profileImage = profileImage { user.profileImage = profileImage }
        if let profileImageURL = profileImageURL { user.profileImageURL = profileImageURL }
        if let currentPoint = currentPoint { user.currentPoint = currentPoint }
        if let pin = pin { user.pin = pin }
        if let selectedDates = selectedDates { user.selectedDates = selectedDates }
        if let rewardImageURL = rewardImageURL { user.rewardImageURL = rewardImageURL }
        self.currentUser = user

        // users配列内の該当ユーザーも更新
        if let index = users.firstIndex(where: { $0.userName == user.userName }) {
            users[index] = user
        }
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

// 注: toDictionary実装はUserSessionUser.swiftに移動されました
// 重複コードと不整合を防ぐため、そちらを参照してください
// このエクステンションは互換性のために残していますが、
// 常に内部でUserSessionUserの実装を呼び出して動作を統一します
extension UserSessionUser {
    // UserSessionUser.swiftにセーフティチェック付きの実装があります
}
