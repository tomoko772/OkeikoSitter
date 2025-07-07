//
//  Setting.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/07/02.
//

import Foundation
import Firebase

struct Setting {
    let documentID: String
    /// ユーザーネーム
    let userName: String
    /// 目標達成時にもらえるポイント数
    let challengePoint: Int
    /// ボーナスポイント数
    let bonusPoint: Int
    /// 目標達成に必要な合計ポイント数
    let goalPoint: Int
    /// 目標達成の期日（日数）
    let challengeDay: Int
    /// 目標達成の課題内容
    let challengeTask: String
}

extension Setting {
    func toDictionary() -> [String: Any] {
        return [
            "document_id": documentID,
            "user_name": userName,
            "challenge_point": challengePoint,
            "bonus_point": bonusPoint,
            "goalPoint": goalPoint,
            "challenge_day": challengeDay
        ]
    }
}
