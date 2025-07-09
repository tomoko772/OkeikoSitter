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
    func fetchByQuery<T: Codable>(
        collection: String,
        field: String,
        isEqualTo value: Any,
        as type: T.Type,
        completion: @escaping ([T]?, Error?) -> Void
    ) {
        db.collection(collection)
            .whereField(field, isEqualTo: value)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let objects = documents.compactMap { self.decodeDocument($0, as: T.self) }
                completion(objects, nil)
            }
    }
    
    func decodeDocument<T: Codable>(_ doc: DocumentSnapshot, as type: T.Type) -> T? {
        guard let data = doc.data() else { return nil }
        
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
    
    /// Storage内のファイルを削除するメソッド
    func deleteFileFromStorage(path: String,
                               completion: @escaping (Error?) -> Void) {
        let ref = storage.reference().child(path)
        ref.delete(completion: completion)
    }
}
