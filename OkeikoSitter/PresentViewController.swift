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
    
    @IBOutlet private weak var hiddenPlaceImageView: UIImageView!
    @IBOutlet private weak var presentMarkImageView: UIImageView!
    @IBOutlet private weak var hiddenPlaceLabel: UILabel!
    @IBOutlet private weak var quesitonMarkImageView: UIImageView!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtonItems()
        configureUI()
    }
    
    // MARK: - IBActions
    
    @IBAction private func cameraButtonTapped(_ sender: Any) {
    }
    
    @IBAction private func registrationButtonTapped(_ sender: Any) {
    }
    
    // MARK: - Other Methods
    
    private func configureBarButtonItems(){
        // 左端のキャンセルボタン（アイコン）
        let backImage = UIImage(named: "cancel")
        let backButton = UIBarButtonItem(image: backImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(backlButtonPressed(_:)))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func backlButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureUI() { hiddenPlaceImageView.isHidden = true
        hiddenPlaceLabel.isHidden = true
    }
    
}
