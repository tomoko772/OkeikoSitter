//
//  CalendarViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/12/09.
//

import UIKit
import HorizonCalendar

struct DayLabel: CalendarItemViewRepresentable {
    typealias ViewModel = <#type#>
    
    // ViewType は UILabel にする
    typealias ViewType = UILabel
    
    // 変更されないプロパティ（フォントや色など）をまとめる
    struct InvariantViewProperties: Hashable {
        let font: UIFont
        let textColor: UIColor
    }
    
    // 動的なコンテンツ（その日に関する情報）
    struct Content: Hashable {
        let day: Day
    }
    
    // View を作る
    static func makeView(for invariantViewProperties: InvariantViewProperties) -> UILabel {
        let label = UILabel()
        label.font = invariantViewProperties.font
        label.textColor = invariantViewProperties.textColor
        label.textAlignment = .center
        return label
    }
    
    // Content を View に適用する（更新されるたびに呼ばれる）
    static func setContent(_ content: Content, on view: UILabel, with bookkeeping: inout Set<AnyHashable>) {
        view.text = "\(content.day.day)"
    }
    
    // 便利構築子（サンプルの形に合わせた API）
    static func calendarItemModel(
        invariantViewProperties: InvariantViewProperties,
        content: Content
    ) -> CalendarItem<DayLabel, Day> {
        return CalendarItem<DayLabel, Day>(
            invariantViewProperties: invariantViewProperties,
            content: content
        )
    }
}

/// カレンダー画面
final class CalendarViewController: UIViewController {
    
    // MARK: - Properties
    
    private var calendarView: CalendarView!
    
    // MARK: - View Life-Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupCalendar()
    }
    
    // MARK: - IBAction
    
    @IBAction private func closeButtonTapped(_ sender: Any) { dismiss(animated: true)
    }
    
    // MARK: - Other Methods
    
    private func setupCalendar() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -1, to: Date())!
        let endDate   = calendar.date(byAdding: .year, value: 1, to: Date())!
        let dateRange = startDate...endDate
        
        // selectedDate を使って色を変える例のためにキャプチャ
        let content = makeContent(calendar: calendar, visibleDateRange: dateRange, selectedDate: selectedDate)
        
        calendarView = CalendarView(initialContent: content)
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 日付タップで selectedDate を更新してカレンダーを再セット
        calendarView.daySelectionHandler = { [weak self] day in
            guard let self = self else { return }
            self.selectedDate = calendar.date(from: day.components)
            let newContent = self.makeContent(calendar: calendar, visibleDateRange: dateRange, selectedDate: self.selectedDate)
            self.calendarView.setContent(newContent)
            print("選択: \(String(describing: self.selectedDate))")
        }
    }
    
    // CalendarViewContent を作るヘルパー
    private func makeContent(calendar: Calendar, visibleDateRange: ClosedRange<Date>, selectedDate: Date?) -> CalendarViewContent {
        return CalendarViewContent(
            calendar: calendar,
            visibleDateRange: visibleDateRange,
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions())
        )
        .withDayItemProvider { day -> CalendarItem<DayLabel, Day> in
            // DayLabel の invariant プロパティ（フォント・色）
            let invariant = DayLabel.InvariantViewProperties(
                font: .systemFont(ofSize: 16),
                textColor: .label
            )
            // content（day 情報）と選択色例
            let content = DayLabel.Content(day: day)
            
            // ここで選択日の判定を行い、必要なら Invariant/View の別パターンを返すことも可能
            // （今回は単純表示）
            return DayLabel.calendarItemModel(
                invariantViewProperties: invariant,
                content: content
            )
        }
    }
}
