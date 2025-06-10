//
//  SettingViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/05/21.
//

import UIKit

class SettingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 左端のキャンセルボタン（アイコン）
        let cancelImage = UIImage(named: "cancel")
        let cancelButton = UIBarButtonItem(image: cancelImage, style: .plain, target: self, action: #selector(cancelButtonPressed(_:)))
        navigationItem.leftBarButtonItem = cancelButton
        
        // 右端の削除ボタン（アイコン）
        let deleteImage = UIImage(named: "delete")
        let deleteButton = UIBarButtonItem(image: deleteImage, style: .plain, target: self, action: #selector(deleteButtonPressed(_:)))
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func deleteButtonPressed(_ sender: UIBarButtonItem) {
        print("ユーザーが削除されます")
    }
}

// MARK: - IBActions



// MARK: - Other Methods

private func configureBarButtonItems() {
    
}

