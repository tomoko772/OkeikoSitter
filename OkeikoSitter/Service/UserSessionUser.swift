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
    let challengeTask: String
    /// チャレンジポイント
    let challengePoint: Int
    /// ボーナスポイント
    var bonusPoint: Int
    /// 目標ポイント
    let goalPoint: Int
    /// チャレンジ日数
    let challengeDay: Int
    /// ご褒美の隠し場所
    let hiddenPlace: String
    /// プロフィール画像
    var profileImage: UIImage?
    var profileImageURL: String?
    /// 現在のポイント
    var currentPoint: Int = 0
    /// 暗証番号
    var pin: Int?

    // MARK: - Initializers

    init(userName: String,
         challengeTask: String = "",
         challengePoint: Int = 0,
         bonusPoint: Int = 0,
         goalPoint: Int = 0,
         challengeDay: Int = 0,
         hiddenPlace: String = "",
         profileImage: UIImage?,
         profileImageURL: String?,
         currentPoint: Int,
         pin: Int?) {
        self.userName = userName
        self.challengeTask = challengeTask
        self.challengePoint = challengePoint
        self.bonusPoint = bonusPoint
        self.goalPoint = goalPoint
        self.challengeDay = challengeDay
        self.hiddenPlace = hiddenPlace
        self.profileImage = profileImage
        self.profileImageURL = profileImageURL
        self.currentPoint = currentPoint
        self.pin = pin
    }
}
