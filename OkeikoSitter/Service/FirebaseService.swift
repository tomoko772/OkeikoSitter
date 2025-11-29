//
//  FirebaseService.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/07/02.
//

import Firebase
import FirebaseStorage

/// Firebaseの管理クラス
final class FirebaseService {
    
    // MARK: - Properties
    
    /// シングルトンパターン
    static let shared = FirebaseService()
    /// Firestoreのインスタンス
    private let db = Firestore.firestore()
    /// FirebaseStorageのインスタンス
    private let storage = Storage.storage()
    
    // MARK: - Firestore
    
    /// 保存または追加 (documentIDがあれば上書き、なければ追加)
    func save(collection: String,
              documentID: String? = nil,
              data: [String: Any],
              merge: Bool = false,
              completion: @escaping (Error?) -> Void) {
        if let documentID = documentID {
            db.collection(collection).document(documentID).setData(data, merge: merge, completion: completion)
        } else {
            db.collection(collection).addDocument(data: data, completion: completion)
        }
    }
    
    /// 取得
    func fetchDocument<T: Codable>(
        collection: String,
        documentID: String,
        completion: @escaping (T?, Error?) -> Void
    ) {
        let docRef = db.collection(collection).document(documentID)
        docRef.getDocument { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil, nil)
                return
            }
            let object = self.decodeDocument(snapshot, as: T.self)
            completion(object, nil)
        }
    }
    
    func decodeDocument<T: Codable>(_ doc: DocumentSnapshot, as type: T.Type) -> T? {
        guard var data = doc.data() else { return nil }
        
        // 🔹 TimestampをDateに変換
        for (key, value) in data {
            if let timestamp = value as? Timestamp {
                let formatter = ISO8601DateFormatter()
                data[key] = formatter.string(from: timestamp.dateValue())
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            let object = try JSONDecoder().decode(T.self, from: jsonData)
            return object
        } catch {
            print("Firestoreドキュメントのデコードに失敗: \(error)")
            return nil
        }
    }
    
    /// 更新（部分更新）
    func update(collection: String,
                documentID: String,
                data: [String: Any],
                completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(documentID).setData(data, merge: true, completion: completion)
    }
    
    /// 削除
    func delete(collection: String,
                documentID: String,
                completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(documentID).delete(completion: completion)
    }
    
    // MARK: - Storage
    
    /// 画像などのデータをStorageにアップロードするメソッド
    func uploadDataToStorage(data: Data,
                             path: String,
                             completion: @escaping (URL?, Error?) -> Void) {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        ref.putData(data, metadata: metadata) { _, error in
            if let error = error {
                completion(nil, error)
                return
            }
            ref.downloadURL { url, error in
                completion(url, error)
            }
        }
    }
    
    /// Storage内の画像データをUIImageとして取得するメソッド
    func fetchImageFromStorage(path: String,
                               maxSizeInMB: Int = 5,
                               completion: @escaping (UIImage?) -> Void) {
        let ref = storage.reference().child(path)
        let maxSize = Int64(maxSizeInMB) * 1024 * 1024
        
        ref.getData(maxSize: maxSize) { data, error in
            if let error = error {
                print("画像取得失敗: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("画像データの変換に失敗")
                completion(nil)
                return
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    /// Storage内のファイルを削除するメソッド
    func deleteFileFromStorage(path: String,
                               completion: @escaping (Error?) -> Void) {
        let ref = storage.reference().child(path)
        ref.delete(completion: completion)
    }

    /// users配列内の特定ユーザーとcurrent_userを同時に更新
    func updateUserAndCurrentUser(
        collection: String,
        documentID: String,
        userName: String,
        userData: [String: Any],
        completion: @escaping (Error?) -> Void
    ) {
        let docRef = db.collection(collection).document(documentID)

        // まず現在のドキュメントを取得
        docRef.getDocument { snapshot, error in
            if let error = error {
                completion(error)
                return
            }

            guard let snapshot = snapshot,
                  snapshot.exists,
                  var data = snapshot.data(),
                  var users = data["users"] as? [[String: Any]] else {
                completion(NSError(domain: "FirebaseService",
                                   code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "ユーザーデータが見つかりません"]))
                return
            }

            // users配列内の該当ユーザーを検索して更新
            if let index = users.firstIndex(where: {
                ($0["user_name"] as? String) == userName
            }) {
                // 既存のユーザーデータに新しいデータをマージ
                users[index].merge(userData) { (_, new) in new }
            } else {
                // ユーザーが見つからない場合はエラー
                completion(NSError(domain: "FirebaseService",
                                   code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "ユーザーが見つかりません"]))
                return
            }

            // current_user と users を両方更新
            let updateData: [String: Any] = [
                "current_user": userData,
                "users": users
            ]

            docRef.setData(updateData, merge: true, completion: completion)
        }
    }
}
