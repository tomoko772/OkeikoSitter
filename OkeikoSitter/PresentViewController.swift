//
//  PresentViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/22.
//

import UIKit

/// ご褒美登録画面
class PresentViewController: UIViewController {
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
        let backImage = UIImage(named: "arrow_back")
        let backButton = UIBarButtonItem(image: backImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(backlButtonPressed(_:)))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func backlButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
