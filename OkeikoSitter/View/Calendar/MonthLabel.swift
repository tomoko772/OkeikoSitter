//
//  MonthLabel.swift
//  OkeikoSitter
//
//  Created by 高橋智一 on 2025/12/09.
//

import UIKit
import HorizonCalendar

struct MonthLabel: CalendarItemViewRepresentable {

    typealias View = UILabel

    struct InvariantViewProperties: Hashable {
        let font: UIFont
        let textColor: UIColor
    }

    struct ViewModel: Hashable {
        let text: String
    }

    static func makeView(withInvariantViewProperties invariantViewProperties: InvariantViewProperties) -> UILabel {
        let label = UILabel()
        label.font = invariantViewProperties.font
        label.textColor = invariantViewProperties.textColor
        label.textAlignment = .left
        return label
    }

    // ← これが v1.16.0 から必須
    static func setViewHierarchy(_ view: UILabel, in contentView: UIView) {
        // ラベルを contentView に追加
        contentView.addSubview(view)

        // AutoLayout 必須
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }

    static func setViewModel(_ viewModel: ViewModel, on view: UILabel) {
        view.text = viewModel.text
    }
}
