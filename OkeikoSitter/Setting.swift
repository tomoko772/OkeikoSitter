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
    let userName: String
    let challengePoint: Int
    let bonusPoint: Int
    let goalPoint: Int
    let challengeDay: Int
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
