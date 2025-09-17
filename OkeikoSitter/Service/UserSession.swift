//
//  UserSession.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/09/17.
//

import Foundation

/// ログインユーザーの情報を管理するシングルトン
final class UserSession {
    static let shared = UserSession()
    
    /// ユーザーIDを保持
    private(set) var userID: String?
    
    /// 初回取得時に設定する
    func setUserID(userID: String) {
        self.userID = userID
    }
    
    /// クリアしたいとき（ログアウトなど）
    func clear() {
        self.userID = nil
    }
}









