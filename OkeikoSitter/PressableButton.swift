//
//  Untitled.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/06/11.
//
import UIKit

/// ボタンを押した感じにするクラス
class PressableButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted
                ? CGAffineTransform(scaleX: 0.85, y: 0.85)
                : .identity
            }
        }
    }
}
