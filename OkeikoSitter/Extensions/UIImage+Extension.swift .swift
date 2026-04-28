//
//  UIImage+Extension.swift .swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/07/30.
//

import UIKit

extension UIImage {
    static func load(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("URLの作成に失敗: \(urlString)")
            completion(nil)
            return
        }
        
        print("画像読み込み開始: \(url.lastPathComponent)")
        
        // シンプルにURLSessionで画像を取得（キャッシュ無効）
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("画像読み込みエラー: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data,
                  let image = UIImage(data: data) else {
                print("画像データの変換に失敗")
                completion(nil)
                return
            }
            
            print("画像読み込み成功: \(url.lastPathComponent), サイズ: \(data.count) bytes")
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    /// 指定したサイズにリサイズしたイメージを返す
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// 互換性のためのダミーメソッド（キャッシュ無効化のため空実装）
    static func clearImageCache() {
        // キャッシュ制御は使用しない
    }
}