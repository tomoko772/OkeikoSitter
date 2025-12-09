//
//  DayLabel.swift
//  OkeikoSitter
//
//  Created by 高橋智一 on 2025/12/09.
//

import HorizonCalendar
import UIKit

/// DayLabel の定義
struct DayLabel: CalendarItemViewRepresentable {

    // ViewType は UILabel にする
    typealias ViewType = UILabel

    // 変更されないプロパティ（フォントや色など）をまとめる
    struct InvariantViewProperties: Hashable {
        let font: UIFont
        let textColor: UIColor
        let backgroundColor: UIColor
    }

    // 動的なコンテンツ（その日に関する情報）
    struct Content: Hashable {
        let day: Day
        let isSelected: Bool
    }

    // View を作る
    static func makeView(withInvariantViewProperties invariantViewProperties: InvariantViewProperties) -> UILabel {
        let label = UILabel()
        label.font = invariantViewProperties.font
        label.textColor = invariantViewProperties.textColor
        label.backgroundColor = invariantViewProperties.backgroundColor
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }

    // Content を View に適用する（更新されるたびに呼ばれる）
    static func setContent(_ content: Content, on view: UILabel) {
        view.text = "\(content.day.day)"

        // 選択状態で背景色を変える
        if content.isSelected {
            view.backgroundColor = .systemBlue
            view.textColor = .white
        } else {
            view.backgroundColor = .clear
            view.textColor = .label
        }
    }

    static func setViewModel(_ viewModel: Content, on view: UILabel) {
        setContent(viewModel, on: view)
    }
}
