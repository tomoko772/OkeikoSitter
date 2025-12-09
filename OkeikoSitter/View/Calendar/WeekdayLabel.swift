//
//  WeekdayLabel.swift
//  OkeikoSitter
//
//  Created by 高橋智一 on 2025/12/09.
//

import UIKit
import HorizonCalendar

struct WeekdayLabel: CalendarItemViewRepresentable {

    typealias View = UILabel

    struct InvariantViewProperties: Hashable {
        let font: UIFont
    }

    struct ViewModel: Hashable {
        let text: String
        let textColor: UIColor
    }

    static func makeView(
        withInvariantViewProperties invariantViewProperties: InvariantViewProperties
    ) -> UILabel {
        let label = UILabel()
        label.font = invariantViewProperties.font
        label.textAlignment = .center
        return label
    }

    static func setViewHierarchy(_ view: UILabel, in contentView: UIView) {
        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    static func setViewModel(_ viewModel: ViewModel, on view: UILabel) {
        view.text = viewModel.text
        view.textColor = viewModel.textColor
    }
}
