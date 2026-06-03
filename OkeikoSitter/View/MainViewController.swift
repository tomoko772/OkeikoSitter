//
//  MainViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/04/07.
//

import UIKit
import SwiftGifOrigin
import FirebaseAuth

/// メイン画面
final class MainViewController: UIViewController {
    
    // MARK: - Properties
    
    /// FirebaseServiceのインスタンス
    private let firebaseService = FirebaseService.shared
    private var hasShownStreakAchievement = false
    
    // MARK: - IBOutlets
    
    /// ユーザー画像
    @IBOutlet private weak var userImageView: UIImageView!
    /// ユーザーネームラベル
    @IBOutlet private weak var userNameLabel: UILabel!
    /// 目標（課題）の内容ラベル
    @IBOutlet private weak var taskLabel: UILabel!
    /// 目標（課題）達成時にもらえるポイント数ラベル
    @IBOutlet private weak var dailyPointLabel: UILabel!
    /// ボーナスポイントラベル
    @IBOutlet private weak var bonusPointLabel: UILabel!
    /// 現在のポイント数の表示ラベル
    @IBOutlet private weak var currentPointLabel: UILabel!
    /// 目標ポイント数ラベル
    @IBOutlet private weak var goalPointLabel: UILabel!
    /// 連続記録日数ラベル
    @IBOutlet private weak var streakDaysLabel: UILabel!
    /// バイオリンのGIF画像
    @IBOutlet private weak var gifImage: UIImageView!
    /// プレゼントのGIF画像
    @IBOutlet private weak var gifImage2: UIImageView!
    /// チャレンジ内容などのビュー
    @IBOutlet private weak var challengeContentView: UIView!
    /// 目標達成ビュー
    @IBOutlet private weak var goalAchievementView: UIView!
    ///　プレゼントのGIF画像（目標達成ビュー）
    @IBOutlet private weak var gifImage3: UIImageView!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        fetchData()
        configureGIFImage()
    }
    
    // MARK: - IBActions
    
    /// ポイント獲得ボタンをタップ
    @IBAction private func addButtonTapped(_ sender: UIButton) {
        guard let currentUser = UserSession.shared.currentUser else { return }
        let currentPoint = currentUser.currentPoint
        let challengePoint = currentUser.challengePoint
        let goalPoint = currentUser.goalPoint
        let newPoint = currentPoint + challengePoint
        
        // ポイント更新
        UserSession.shared.updateCurrentPoint(newPoint)
        currentPointLabel.text = "現在　\(newPoint)　ポイント"
        
        // 目標達成チェック
        shouldShowGoalAchievementView(goalPoint: goalPoint, currentPoint: newPoint)
        
        incrementTodayPointCountIfNeeded()
        
        // 保存
        saveCurrentPoint(currentPoint: newPoint)
    }
    
    /// ボーナスボタンをタップ
    @IBAction private func addBonusButtonTapped(_ sender: UIButton) {
        guard let currentUser = UserSession.shared.currentUser else { return }
        let currentPoint = currentUser.currentPoint
        let bonusPoint = currentUser.bonusPoint
        let goalPoint = currentUser.goalPoint
        UserSession.shared.updateCurrentPoint(currentPoint + bonusPoint)
        currentPointLabel.text = "現在　\(currentPoint + bonusPoint)　ポイント"
        shouldShowGoalAchievementView(goalPoint: goalPoint, currentPoint: currentPoint + bonusPoint)
        
        incrementTodayPointCountIfNeeded()
        
        saveCurrentPoint(currentPoint: currentPoint + bonusPoint)
    }
    
    @IBAction private func minusButtonTapped(_ sender: UIButton) {
        guard let currentUser = UserSession.shared.currentUser else {
            return
        }
        
        let currentPoint = currentUser.currentPoint
        let goalPoint = currentUser.goalPoint
        let newPoint = max(0, currentPoint - 1)
        
        UserSession.shared.updateCurrentPoint(newPoint)
        currentPointLabel.text = "現在　\(newPoint)　ポイント"
        
        shouldShowGoalAchievementView(goalPoint: goalPoint, currentPoint: newPoint)
        
        decrementTodayPointCountIfNeeded()
        
        saveCurrentPoint(currentPoint: newPoint)
    }
    
    /// 連続記録日数が表示されたボタンをタップ
    @IBAction private func calendarButtonTapped(_ sender: UIButton) {
        guard let currentUser = UserSession.shared.currentUser else { return }
        
        print("=== カレンダーボタン押下 ===")
        print("userName: \(currentUser.userName)")
        print("selectedDates: \(formatTimestamps(currentUser.selectedDates ?? []))")
        
        // ★ currentUser ごとの selectedDates を取得するよう変更
        let savedDates: [TimeInterval] = currentUser.selectedDates ?? []
        let selectedDates = Set(savedDates.map { Date(timeIntervalSince1970: $0) })
        
        let calendarVC = CalendarViewController()
        calendarVC.selectedDates = selectedDates
        
        calendarVC.onSaveSelectedDates = nil
        
        present(calendarVC, animated: true)
    }
    
    /// ご褒美ボタンをタップ
    @IBAction private func presentButtonTapped(_ sender: UIButton) {
        guard let currentUser = UserSession.shared.currentUser else { return }
        let isGoalReached = currentUser.goalPoint > 0 && currentUser.currentPoint >= currentUser.goalPoint
        
        let presentVC = PresentViewController(
            isGoalReached: isGoalReached,
            hidingPlace: currentUser.hiddenPlace
        )
        let navController = UINavigationController(rootViewController: presentVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }
    
    // MARK: - Other Methods
    
    private let jpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
    
    private func formatDates(_ dates: [Date]) -> [String] {
        return dates.sorted().map { jpDateFormatter.string(from: $0) }
    }
    
    private func formatTimestamps(_ timestamps: [TimeInterval]) -> [String] {
        return timestamps
            .map { Date(timeIntervalSince1970: $0) }
            .sorted()
            .map { jpDateFormatter.string(from: $0) }
    }
    
    private func configureBarButtonItems() {
        // １つ目の画像ボタン（ユーザー切替）
        let usersButton = UIButton(type: .custom)
        usersButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        if let usersImage = UIImage(named: "ic_users") {
            usersButton.setImage(usersImage, for: .normal)
            usersButton.contentMode = .scaleAspectFit
        }
        usersButton.addTarget(self, action: #selector(didTapUsersButton), for: .touchUpInside)
        let usersBarButtonItem = UIBarButtonItem(customView: usersButton)
        
        // ２つ目の画像ボタン（設定）
        let settingsButton = UIButton(type: .custom)
        settingsButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        if let settingsImage = UIImage(named: "ic_setting") {
            settingsButton.setImage(settingsImage, for: .normal)
            settingsButton.contentMode = .scaleAspectFit
        }
        settingsButton.addTarget(self, action: #selector(didTapSettingButton), for: .touchUpInside)
        let settingsBarButtonItem = UIBarButtonItem(customView: settingsButton)
        
        // スペースを追加して適切な間隔を確保
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceItem.width = 16.0
        
        // ボタンを右側に並べる（間隔を適切に）
        self.navigationItem.rightBarButtonItems = [settingsBarButtonItem, spaceItem, usersBarButtonItem]
    }
    
    /// 設定ボタンがタップされたときの処理
    @objc private func didTapSettingButton(_ sender: UIButton) {
        navigateToSetting()
    }
    
    /// ユーザー切り替えボタンがタップされたときの処理
    @objc private func didTapUsersButton(_ sender: UIButton) {
        navigateToUsers()
    }
    
    /// 現在のポイントを保存
    private func saveCurrentPoint(currentPoint: Int) {
        guard let userID = Auth.auth().currentUser?.uid,
              let currentUser = UserSession.shared.currentUser else {
            print("未ログインまたはユーザー情報がありません")
            return
        }
        
        let userName = currentUser.userName
        let saveData: [String: Any] = ["current_point": currentPoint]
        
        // current_user と users配列の両方を更新
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: userName,
            userData: saveData
        ) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "データの保存エラー", message: error.localizedDescription)
            } else {
                UserSession.shared.updateCurrentPoint(currentPoint)
                print("current_point 保存成功: \(currentPoint)")
            }
        }
    }
    
    /// データを取得する
    private func fetchData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("未ログインです")
            return
        }
        UserSession.shared.setUserID(accountID: userID)
        firebaseService.fetchDocument(collection: "users", documentID: userID) { (accountData: Account?, error) in
            if let error = error {
                print("取得エラー: \(error)")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if let currentUserData = accountData?.currentUser {
                    print("📊 取得したポイント: \(currentUserData.currentPoint ?? -1)")
                    print("📊 取得した streakGoalDays: \(currentUserData.streakGoalDays ?? -1)")
                    if let allUsers = accountData?.users {
                        let sessionUsers = allUsers.map { user in
                            UserSessionUser(
                                userName: user.userName ?? "",
                                challengeTask: user.challengeTask ?? "",
                                challengePoint: user.challengePoint ?? 0,
                                bonusPoint: user.bonusPoint ?? 0,
                                goalPoint: user.goalPoint ?? 0,
                                streakGoalDays: user.streakGoalDays ?? 0,
                                dailyPointTotals: user.dailyPointTotals ?? [:],
                                hiddenPlace: user.hiddenPlace ?? "",
                                profileImage: nil,
                                profileImageURL: user.profileImageURL,
                                currentPoint: user.currentPoint ?? 0,
                                pin: user.pin,
                                selectedDates: user.selectedDates,
                                rewardImageURL: user.rewardImageURL
                            )
                        }
                        UserSession.shared.setUsers(sessionUsers)
                        print("📝 UserSessionにユーザーをセット: \(sessionUsers.count)人")
                    }
                    // UserSessionUser に変換
                    let user = UserSessionUser(
                        userName: currentUserData.userName ?? "",
                        challengeTask: currentUserData.challengeTask ?? "",
                        challengePoint: currentUserData.challengePoint ?? 0,
                        bonusPoint: currentUserData.bonusPoint ?? 0,
                        goalPoint: currentUserData.goalPoint ?? 0,
                        streakGoalDays: currentUserData.streakGoalDays ?? 0,
                        dailyPointTotals: currentUserData.dailyPointTotals ?? [:],
                        hiddenPlace: currentUserData.hiddenPlace ?? "",
                        profileImage: nil,
                        profileImageURL: currentUserData.profileImageURL,
                        currentPoint: currentUserData.currentPoint ?? 0,
                        pin: currentUserData.pin,
                        selectedDates: currentUserData.selectedDates,
                        rewardImageURL: currentUserData.rewardImageURL
                    )
                    
                    // UserSession に反映
                    UserSession.shared.selectCurrentUser(user: user)
                    
                    // UI 更新
                    self.updateUI(with: user)
                    
                    // 画像取得
                    if let profileImageURL = currentUserData.profileImageURL {
                        self.fetchImage(from: profileImageURL)
                    }
                    
                } else {
                    print("current_user が存在しません")
                    navigateToUsers()
                }
            }
        }
    }
    
    /// 画像を取得
    private func fetchImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.userImageView.image = image
                    UserSession.shared.updateProfileImage(image)
                }
            }
        }.resume()
    }
    
    /// 画面を再読み込みする必要があることをマークするメソッド
    /// 他の画面から呼び出せるように追加
    func setNeedsReload() {
        print("MainViewController: 再読み込みが予定されています")
        DispatchQueue.main.async { [weak self] in
            self?.fetchData()
        }
    }
    
    private func updateUI(with user: UserSessionUser) {
        userNameLabel.text = user.userName
        
        taskLabel.text = user.challengeTask.isEmpty ? "設定してください" : user.challengeTask
        dailyPointLabel.text = "+\(user.challengePoint) ポイント"
        bonusPointLabel.text = "ボーナス+\(user.bonusPoint) ポイント"
        currentPointLabel.text = "現在　\(user.currentPoint) ポイント"
        goalPointLabel.text = "目標　\(user.goalPoint)　ポイント"
        
        let streak = calculateCurrentStreak(from: user.selectedDates)
        streakDaysLabel.text = "連続記録 \(streak)日"
        
        shouldShowGoalAchievementView(goalPoint: user.goalPoint, currentPoint: user.currentPoint)
        showStreakAchievementIfNeeded(streak: streak, streakGoalDays: user.streakGoalDays)
    }
    
    private func shouldShowGoalAchievementView(goalPoint: Int, currentPoint: Int) {
        if goalPoint > 0,
           goalPoint <= currentPoint {
            goalAchievementView.isHidden = false
            challengeContentView.isHidden = true
        } else {
            goalAchievementView.isHidden = true
            challengeContentView.isHidden = false
        }
    }
    
    /// 設定画面へ遷移
    private func navigateToSetting() {
        let settingVC = SettingViewController()
        settingVC.delegate = self
        let navController = UINavigationController(rootViewController: settingVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }
    
    /// ユーザー一覧画面へ遷移
    private func navigateToUsers() {
        let userVC = UserListViewController()
        userVC.delegate = self
        let navController = UINavigationController(rootViewController: userVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController?.present(navController, animated: true)
    }
    
    /// アラートを表示
    private func showAlert(title: String, message: String = "",
                           completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    private func configureGIFImage() {
        gifImage.clipsToBounds = true
        gifImage.contentMode = .center
        gifImage.loadGif(name: "violin")
        gifImage2.loadGif(name: "present")
        gifImage3.loadGif(name: "present")
    }
    
    private func saveSelectedDatesToFirebase(_ dates: Set<Date>) {
        guard let currentUser = UserSession.shared.currentUser,
              let userID = Auth.auth().currentUser?.uid else { return }
        
        let timestamps = dates.map { $0.timeIntervalSince1970 }
        let data: [String: Any] = ["selected_dates": timestamps]
        
        FirebaseService.shared.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: currentUser.userName,
            userData: data
        ) { error in
            if let error = error {
                print("日付保存失敗: \(error)")
            } else {
                let formattedDates = dates.sorted().map { String(describing: $0) }
                print("日付保存成功: \(formattedDates)")
            }
        }
    }
    
    private func calculateCurrentStreak(from timestamps: [TimeInterval]?) -> Int {
        guard let timestamps = timestamps, !timestamps.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let normalizedDates = timestamps.map {
            calendar.startOfDay(for: Date(timeIntervalSince1970: $0))
        }
        
        let uniqueDates = Array(Set(normalizedDates)).sorted()
        guard let lastDate = uniqueDates.last else { return 0 }
        
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        print("=== calculateCurrentStreak ===")
        print("timestamps: \(formatTimestamps(timestamps))")
        print("uniqueDates: \(formatDates(uniqueDates))")
        print("lastDate: \(jpDateFormatter.string(from: lastDate))")
        print("today: \(jpDateFormatter.string(from: today))")
        print("yesterday: \(jpDateFormatter.string(from: yesterday))")
        
        if !calendar.isDate(lastDate, inSameDayAs: today) &&
            !calendar.isDate(lastDate, inSameDayAs: yesterday) {
            return 0
        }
        
        var streak = 1
        var currentDate = lastDate
        
        for date in uniqueDates.dropLast().reversed() {
            let diff = calendar.dateComponents([.day], from: date, to: currentDate).day ?? 0
            
            print("compare: date=\(jpDateFormatter.string(from: date)), currentDate=\(jpDateFormatter.string(from: currentDate)), diff=\(diff)")
            
            if diff == 1 {
                streak += 1
                currentDate = date
            } else if diff > 1 {
                break
            }
        }
        
        print("streak: \(streak)")
        return streak
    }
    
    private func addTodayToSelectedDatesIfNeeded() {
        guard let currentUser = UserSession.shared.currentUser,
              let userID = Auth.auth().currentUser?.uid else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var timestamps = currentUser.selectedDates ?? []
        
        let alreadyExists = timestamps.contains {
            calendar.isDate(Date(timeIntervalSince1970: $0), inSameDayAs: today)
        }
        
        guard !alreadyExists else { return }
        
        timestamps.append(today.timeIntervalSince1970)
        
        UserSession.shared.updateSelectedDates(for: currentUser.userName, timestamps: timestamps)
        
        if var updatedUser = UserSession.shared.currentUser {
            updatedUser.selectedDates = timestamps
            UserSession.shared.selectCurrentUser(user: updatedUser)
            updateUI(with: updatedUser)
        }
        
        let saveData: [String: Any] = ["selected_dates": timestamps]
        
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: currentUser.userName,
            userData: saveData
        ) { [weak self] error in
            if let error = error {
                print("selected_dates 保存失敗: \(error)")
            } else {
                if var updatedUser = UserSession.shared.currentUser {
                    updatedUser.selectedDates = timestamps
                    UserSession.shared.selectCurrentUser(user: updatedUser)
                    self?.updateUI(with: updatedUser)
                }
                print("selected_dates 保存成功")
                print("selected_dates 保存前: \(String(describing: self?.formatTimestamps(currentUser.selectedDates ?? [])))")
                print("selected_dates 保存後: \(String(describing: self?.formatTimestamps(timestamps)))")
                
                let formatter = DateFormatter()
                formatter.calendar = Calendar.current
                formatter.locale = Locale(identifier: "ja_JP")
                formatter.timeZone = TimeZone.current
                formatter.dateFormat = "M月d日"
                
                let formattedDates = timestamps
                    .map { Date(timeIntervalSince1970: $0) }
                    .sorted()
                    .map { formatter.string(from: $0) }
                
                print("selected_dates 保存後: \(formattedDates)")
            }
        }
    }
    
    private func removeTodayFromSelectedDatesIfNeeded() {
        guard let currentUser = UserSession.shared.currentUser,
              let userID = Auth.auth().currentUser?.uid else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let oldTimestamps = currentUser.selectedDates ?? []
        
        let newTimestamps = oldTimestamps.filter {
            !calendar.isDate(Date(timeIntervalSince1970: $0), inSameDayAs: today)
        }
        
        guard newTimestamps.count != oldTimestamps.count else { return }
        
        UserSession.shared.updateSelectedDates(for: currentUser.userName, timestamps: newTimestamps)
        
        if var updatedUser = UserSession.shared.currentUser {
            updatedUser.selectedDates = newTimestamps
            UserSession.shared.selectCurrentUser(user: updatedUser)
            updateUI(with: updatedUser)
        }
        
        let saveData: [String: Any] = ["selected_dates": newTimestamps]
        
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: currentUser.userName,
            userData: saveData
        ) { [weak self] error in
            if let error = error {
                print("selected_dates 削除失敗: \(error)")
            } else {
                if var updatedUser = UserSession.shared.currentUser {
                    updatedUser.selectedDates = newTimestamps
                    UserSession.shared.selectCurrentUser(user: updatedUser)
                    self?.updateUI(with: updatedUser)
                }
                print("selected_dates 削除成功")
                print("selected_dates 削除前: \(oldTimestamps)")
                print("selected_dates 削除後: \(newTimestamps)")
            }
        }
    }
    
    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func incrementTodayPointCountIfNeeded() {
        guard let currentUser = UserSession.shared.currentUser,
              let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = todayKey()
        var totals = currentUser.dailyPointTotals ?? [:]
        let oldCount = totals[key] ?? 0
        let newCount = oldCount + 1
        totals[key] = newCount
        
        let saveData: [String: Any] = ["daily_point_totals": totals]
        
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: currentUser.userName,
            userData: saveData
        ) { error in
            if let error = error {
                print("daily_point_totals 保存失敗: \(error)")
            } else {
                if var updatedUser = UserSession.shared.currentUser {
                    updatedUser.dailyPointTotals = totals
                    UserSession.shared.selectCurrentUser(user: updatedUser)
                }
                print("daily_point_totals 保存成功: \(totals)")
            }
        }
        
        if oldCount == 0 && newCount == 1 {
            addTodayToSelectedDatesIfNeeded()
        }
    }
    
    private func decrementTodayPointCountIfNeeded() {
        guard let currentUser = UserSession.shared.currentUser,
              let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = todayKey()
        var totals = currentUser.dailyPointTotals ?? [:]
        let oldCount = totals[key] ?? 0
        
        guard oldCount > 0 else { return }
        
        let newCount = oldCount - 1
        
        if newCount > 0 {
            totals[key] = newCount
        } else {
            totals.removeValue(forKey: key)
        }
        
        let saveData: [String: Any] = ["daily_point_totals": totals]
        
        firebaseService.updateUserAndCurrentUser(
            collection: "users",
            documentID: userID,
            userName: currentUser.userName,
            userData: saveData
        ) { error in
            if let error = error {
                print("daily_point_totals 更新失敗: \(error)")
            } else {
                if var updatedUser = UserSession.shared.currentUser {
                    updatedUser.dailyPointTotals = totals
                    UserSession.shared.selectCurrentUser(user: updatedUser)
                }
                print("daily_point_totals 全体: \(totals)")
            }
        }
        
        if newCount <= 0 {
            removeTodayFromSelectedDatesIfNeeded()
        }
    }
    
    private func showStreakAchievementIfNeeded(streak: Int, streakGoalDays: Int) {
        guard streakGoalDays > 0 else { return }
        
        if streak >= streakGoalDays {
            if !hasShownStreakAchievement {
                hasShownStreakAchievement = true
                showAlert(title: "連続記録達成！", message: "\(streakGoalDays)日連続を達成しました！")
            }
        } else {
            hasShownStreakAchievement = false
        }
    }
}

// MARK: - UserListViewControllerDelegete

extension MainViewController: UserListViewControllerDelegete {
    func didSelectCurrentUser() {
        // fetchDataの前にURL検証を行う
        if let currentUser = UserSession.shared.currentUser,
           let rewardURL = currentUser.rewardImageURL,
           !rewardURL.isEmpty {
            
            print("DEBUG-メイン画面: ユーザー切替後確認")
            print("DEBUG-メイン画面: ユーザー名=\(currentUser.userName)")
            print("DEBUG-メイン画面: 隠し場所=\(currentUser.hiddenPlace)")
            print("DEBUG-メイン画面: 画像URL=\(rewardURL)")
            
            // URLにユーザー名が含まれるか確認
            if let url = URL(string: rewardURL) {
                if url.path.contains(currentUser.userName.replacingOccurrences(of: " ", with: "_")) {
                    print("DEBUG-メイン画面: URL確認OK - ユーザー名を含む")
                } else {
                    print("DEBUG-メイン画面: ⚠️ URL不一致の可能性: \(url.path)はユーザー\(currentUser.userName)のものではない可能性")
                }
            }
        }
        
        fetchData()
    }
}

// MARK: - SettingViewControllerDelegate

extension MainViewController: SettingViewControllerDelegate {
    func settingViewControllerDidUpdateData() {
        fetchData()
    }
}
