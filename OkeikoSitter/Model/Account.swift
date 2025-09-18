//
//  Account.swift
//  OkeikoSitter
//
//  Created by 高橋智一 on 2025/09/18.
//

struct Account: Codable {

    // MARK: - Enums

    enum CodingKeys: String, CodingKey {
        case accountID = "account_id"
        case users = "users"
        case currentUser = "current_user"
    }

    // MARK: - Properties

    let accountID: String?
    let users: [User]
    let currentUser: User?
}
