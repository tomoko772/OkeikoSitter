//
//  DayLabel.swift
//  OkeikoSitter
//
//  Created by 高橋智一 on 2025/12/09.
//

import UIKit
import HorizonCalendar

struct DayLabel: CalendarItemViewRepresentable {

    // 使用する View
    typealias View = UILabel

    // 不変プロパティ
    struct InvariantViewProperties: Hashable {
        let font: UIFont
        let textColor: UIColor
        let selectedFillColor: UIColor
        let selectedTextColor: UIColor
        let diameter: CGFloat
    }

    // 表示データ（DayComponents を保持）
    struct ViewModel: Hashable {
        let year: Int
        let month: Int
        let day: Int
        let isSelected: Bool
    }


    // 1) View を一度作る
    static func makeView(withInvariantViewProperties invariantViewProperties: InvariantViewProperties) -> UILabel {
        let label = UILabel()
        label.font = invariantViewProperties.font
        label.textColor = invariantViewProperties.textColor
        label.textAlignment = .center
        label.numberOfLines = 1
        label.backgroundColor = .clear
        label.clipsToBounds = true
        return label
    }

    // 2) view を contentView に入れてレイアウトする（必須）
    static func setViewHierarchy(_ view: UILabel, in contentView: UIView) {
        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        // 中央に置き、幅/高さは invariant の diameter に従う（constraint を作成）
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        // 幅高さ制約は create once -> keep, we'll toggle active in setViewModel if needed
        // To avoid creating duplicate constraints multiple times, attach them to the view once:
        if view.constraints.first(where: { $0.identifier == "day_diameter_width" }) == nil {
            let w = view.widthAnchor.constraint(equalToConstant: 0)
            w.identifier = "day_diameter_width"
            w.isActive = true

            let h = view.heightAnchor.constraint(equalToConstant: 0)
            h.identifier = "day_diameter_height"
            h.isActive = true
        }
    }

    // 3) ViewModel を反映する（必須）
    static func setViewModel(_ viewModel: ViewModel, on view: UILabel) {
        view.text = "\(viewModel.day)"
        view.textColor = .label
        view.backgroundColor = .clear

        // 幅高さの制約を取得
        let widthConstraint = view.constraints.first { $0.identifier == "day_diameter_width" }
        let heightConstraint = view.constraints.first { $0.identifier == "day_diameter_height" }

        let diameter: CGFloat = 40

        widthConstraint?.constant = diameter
        heightConstraint?.constant = diameter

        if viewModel.isSelected {
            view.layer.cornerRadius = diameter / 2
            view.layer.borderWidth = 2
            view.layer.borderColor = UIColor.systemRed.cgColor
        } else {
            view.layer.cornerRadius = diameter / 2
            view.layer.borderWidth = 0
            view.layer.borderColor = UIColor.clear.cgColor
        }
    }
}
