//
//  UserSessionUser.swift
//  OkeikoSitter
//
//  Created by 高橋智一 on 2025/09/18.
//

import UIKit

struct UserSessionUser {

    // MARK: - Type Properties

    /// ユーザー名
    var userName: String
    /// チャレンジ内容
    var challengeTask: String
    /// チャレンジポイント
    var challengePoint: Int
    /// ボーナスポイント
    var bonusPoint: Int
    /// 目標ポイント
    var goalPoint: Int
    /// 目標達成連続記録日数
    var streakGoalDays: Int
    /// 1日ごとのポイント増減合計
    var dailyPointTotals: [String: Int]?
    /// ご褒美の隠し場所
    var hiddenPlace: String
    /// プロフィール画像
    var profileImage: UIImage?
    var profileImageURL: String?
    /// 現在のポイント
    var currentPoint: Int = 0
    /// 暗証番号
    var pin: Int?
    /// 達成した日
    var selectedDates: [TimeInterval]? = []
    /// ご褒美画像のURL
    var rewardImageURL: String?

    // MARK: - Initializers

    init(userName: String,
         challengeTask: String = "",
         challengePoint: Int = 0,
         bonusPoint: Int = 0,
         goalPoint: Int = 0,
         streakGoalDays: Int = 0,
         dailyPointTotals: [String: Int]? = [:],
         hiddenPlace: String = "",
         profileImage: UIImage?,
         profileImageURL: String?,
         currentPoint: Int,
         pin: Int?,
         selectedDates: [TimeInterval]? = [],
         rewardImageURL: String? = nil) {
        self.userName = userName
        self.challengeTask = challengeTask
        self.challengePoint = challengePoint
        self.bonusPoint = bonusPoint
        self.goalPoint = goalPoint
        self.streakGoalDays = streakGoalDays
        self.dailyPointTotals = dailyPointTotals 
        self.hiddenPlace = hiddenPlace
        self.profileImage = profileImage
        self.profileImageURL = profileImageURL
        self.currentPoint = currentPoint
        self.pin = pin
        self.selectedDates = selectedDates
        self.rewardImageURL = rewardImageURL
    }
    
    // MARK: - Methods
    
    /// Firestoreに保存するためのデータ変換
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "user_name": userName,
            "challenge_task": challengeTask,
            "challenge_point": challengePoint,
            "bonus_point": bonusPoint,
            "goal_point": goalPoint,
            "streak_goal_days": streakGoalDays,
            "hidden_place": hiddenPlace,
            "current_point": currentPoint
        ]
        
        if let profileImageURL = profileImageURL {
            dict["profile_image_url"] = profileImageURL
        }
        
        if let pin = pin {
            dict["pin"] = pin
        }
        
        if let selectedDates = selectedDates {
            dict["selected_dates"] = selectedDates
        }
        
        if let dailyPointTotals = dailyPointTotals {
        dict["daily_point_totals"] = dailyPointTotals
        }
        
        // ご褒美画像URLはそのまま保存（検証しない）
        if let rewardURL = rewardImageURL, !rewardURL.isEmpty {
            dict["reward_image_url"] = rewardURL
        } else {
            dict["reward_image_url"] = ""
        }
        
        return dict
    }
}
