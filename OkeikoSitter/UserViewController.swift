//
//  UserViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/07.
//

import UIKit

/// ユーザー登録画面
class UserViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        
    }
    
    // MARK: - IBActions
    
    
    
    // MARK: - Other Methods
    
    private func configureBarButtonItems(){
        // 左端のキャンセルボタン（アイコン）
        let cancelImage = UIImage(named: "cancel")
        let cancelButton = UIBarButtonItem(image: cancelImage,
                                           style: .plain,
                                           target: self,
                                           action: #selector(cancelButtonPressed(_:)))
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

