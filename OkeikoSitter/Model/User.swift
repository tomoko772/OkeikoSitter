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
        case userID = "user_id"
        case familyID = "family_id"
        case userName = "user_name"
        case challengeTask = "challenge_task"
        case challengePoint = "challenge_point"
        case bonusPoint = "bonus_point"
        case goalPoint = "goal_point"
        case challengeDay = "challenge_day"
        case hiddenPlace = "hidden_place"
    }
    
    // MARK: - Properties
    
    let userID: String
    let familyID: String
    let userName: String
    let challengeTask: String
    let challengePoint: Int
    let bonusPoint: Int
    let goalPoint: Int
    let challengeDay: Int
    let hiddenPlace: String
}
