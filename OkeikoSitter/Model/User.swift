//
//  User.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/07/02.
//

/// ユーザーの情報
struct User: Codable {
    
    // MARK: - Enums
    
    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case challengeTask = "challenge_task"
        case challengePoint = "challenge_point"
        case bonusPoint = "bonus_point"
        case goalPoint = "goal_point"
        case challengeDay = "challenge_day"
        case hiddenPlace = "hidden_place"
        case currentPoint = "current_point"
        case profileImageURL = "profile_image_url"
        case pin = "pin"
    }
    
    // MARK: - Properties
    
    /// ユーザーの名前
    let userName: String?
    /// チャレンジ内容
    let challengeTask: String?
    /// チャレンジポイント
    let challengePoint: Int?
    /// ボーナスポイント
    let bonusPoint: Int?
    /// 目標ポイント
    let goalPoint: Int?
    /// チャレンジ日数
    let challengeDay: Int?
    /// ご褒美の隠し場所
    let hiddenPlace: String?
    /// 現在のポイント
    let currentPoint: Int?
    /// プロフィール画像
    let profileImageURL: String?
    /// 暗唱番号
    let pin: Int?
}
