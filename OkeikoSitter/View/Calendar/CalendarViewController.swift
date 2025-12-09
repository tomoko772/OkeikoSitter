//
//  CalendarViewController.swift
//  OkeikoSitter
//
//  Created by Tomoko T. Nakao on 2025/12/09.
//

import UIKit
import HorizonCalendar

/// カレンダー画面
final class CalendarViewController: UIViewController {

    // MARK: - Properties

    private var selectedDate: Date?
    private var calendarView: CalendarView!

    // MARK: - IBOutlets

    @IBOutlet private weak var calendarContainerView: UIView!

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupCalendar()
    }

    // MARK: - IBActions

    @IBAction private func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - Other Methods

    private func setupCalendar() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -1, to: Date())!
        let endDate   = calendar.date(byAdding: .year, value: 1, to: Date())!
        let dateRange = startDate...endDate

        // 初期コンテンツ作成
        let content = makeContent(
            calendar: calendar,
            visibleDateRange: dateRange,
            selectedDate: selectedDate
        )

        let calendarView = CalendarView(initialContent: content)
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarContainerView.addSubview(calendarView)

        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor)
        ])

        self.calendarView = calendarView

        // 日付タップで selectedDate を更新
        calendarView.daySelectionHandler = { [weak self] day in
            guard let self = self else { return }
            self.selectedDate = calendar.date(from: day.components)

            let newContent = self.makeContent(
                calendar: calendar,
                visibleDateRange: dateRange,
                selectedDate: self.selectedDate
            )
            self.calendarView.setContent(newContent)

            if let selectedDate = self.selectedDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                print("選択された日付: \(formatter.string(from: selectedDate))")
            }
        }
    }

    // MARK: - Helper Methods

    /// CalendarViewContent を作成
    private func makeContent(
        calendar: Calendar,
        visibleDateRange: ClosedRange<Date>,
        selectedDate: Date?
    ) -> CalendarViewContent {

        var jpCalendar = calendar
        jpCalendar.locale = Locale(identifier: "ja_JP")

        return CalendarViewContent(
            calendar: jpCalendar,
            visibleDateRange: visibleDateRange,
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions())
        )
        .interMonthSpacing(24)
        .verticalDayMargin(8)
        .horizontalDayMargin(8)
        .withMonthHeader(jpCalendar: jpCalendar)
        .withDayOfWeek()
        .withDayItems(selectedDate: selectedDate, jpCalendar: jpCalendar)
    }
}

// MARK: - CalendarViewContent Extensions
private extension CalendarViewContent {

    /// 月ヘッダー
    func withMonthHeader(jpCalendar: Calendar) -> CalendarViewContent {
        self.monthHeaderItemProvider { month in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M月"

            let date = jpCalendar.date(from: month.components)!
            let text = formatter.string(from: date)

            return CalendarItemModel<MonthLabel>(
                invariantViewProperties: .init(
                    font: .boldSystemFont(ofSize: 22),
                    textColor: .label
                ),
                viewModel: .init(text: text)
            )
        }
    }

    /// 曜日（日〜土）
    func withDayOfWeek() -> CalendarViewContent {
        self.dayOfWeekItemProvider { _, weekdayIndex in
            let symbols = ["日", "月", "火", "水", "木", "金", "土"]
            let text = symbols[weekdayIndex]

            // ▼ 色分け（日曜=赤、土曜=青）
            let color: UIColor
            switch weekdayIndex {
            case 0: color = .systemRed      // 日曜
            case 6: color = .systemBlue     // 土曜
            default: color = .secondaryLabel
            }

            return CalendarItemModel<WeekdayLabel>(
                invariantViewProperties: .init(
                    font: .systemFont(ofSize: 14)
                ),
                viewModel: .init(
                    text: text,
                    textColor: color
                )
            )
        }
    }
    
    /// 日付セル
    func withDayItems(
        selectedDate: Date?,
        jpCalendar: Calendar
    ) -> CalendarViewContent {
        self.dayItemProvider { day in

            let isSelected: Bool
            if let selectedDate = selectedDate {
                let selectedDay = jpCalendar.dateComponents([.year, .month, .day], from: selectedDate)
                isSelected = (day.components == selectedDay)
            } else {
                isSelected = false
            }

            let invariant = DayLabel.InvariantViewProperties(
                font: .systemFont(ofSize: 18),
                textColor: .label,
                backgroundColor: .clear
            )

            let content = DayLabel.Content(
                day: day,
                isSelected: isSelected
            )

            return CalendarItemModel<DayLabel>(
                invariantViewProperties: invariant,
                viewModel: content
            )
        }
    }
}
