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
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  error == nil,
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
