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

    private var calendarView: CalendarView!
    private var startDate: Date!
    private var endDate: Date!
    private var selectedDates: Set<Date> = []

    // MARK: - IBOutlets

    @IBOutlet private weak var calendarContainerView: UIView!

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        loadSelectedDates()
        setupCalendar()
    }

    // MARK: - IBActions

    @IBAction private func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - Other Methods

    private func setupCalendar() {
        let calendar = Calendar.current
        startDate = calendar.date(byAdding: .year, value: -1, to: Date())!
        endDate   = calendar.date(byAdding: .year, value: 1, to: Date())!
        let dateRange = startDate...endDate

        // 初期コンテンツ作成
        let content = makeContent(
            calendar: calendar,
            visibleDateRange: dateRange,
            selectedDates: selectedDates
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
        calendarView.daySelectionHandler = { [weak self] (day: Day) in
            guard let self = self else { return }
            let calendar = Calendar.current
            let date = calendar.date(from: day.components)!

            if self.selectedDates.contains(date) {
                self.selectedDates.remove(date)
            } else {
                self.selectedDates.insert(date)
            }

            self.saveSelectedDates()

            // 再描画
            let newContent = self.makeContent(
                calendar: calendar,
                visibleDateRange: self.startDate...self.endDate,
                selectedDates: self.selectedDates
            )
            self.calendarView.setContent(newContent)
        }
    }

    /// Day → Date → 保存
    private func saveSelectedDates() {
        let timestamps = selectedDates.map { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(timestamps, forKey: "selectedDates")
    }


    /// UserDefaults → Day に復元
    private func loadSelectedDates() {
        guard let timestamps = UserDefaults.standard.array(forKey: "selectedDates") as? [TimeInterval] else { return }
        selectedDates = Set(timestamps.map { Date(timeIntervalSince1970: $0) })
    }

    // MARK: - Helper Methods

    /// CalendarViewContent を作成
    private func makeContent(
        calendar: Calendar,
        visibleDateRange: ClosedRange<Date>,
        selectedDates: Set<Date>
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
        .withDayItems(selectedDates: selectedDates, jpCalendar: jpCalendar)
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
        selectedDates: Set<Date>,
        jpCalendar: Calendar
    ) -> CalendarViewContent {
        self.dayItemProvider { day in
            let date = jpCalendar.date(from: day.components)!
            let isSelected = selectedDates.contains(date)

            let viewModel = DayLabel.ViewModel(
                year: day.month.year,
                month: day.month.month,
                day: day.day,
                isSelected: isSelected
            )

            return CalendarItemModel<DayLabel>(
                invariantViewProperties: DayLabel.InvariantViewProperties(
                    font: .systemFont(ofSize: 16),
                    textColor: .label,
                    selectedFillColor: .clear,
                    selectedTextColor: .label,
                    diameter: 40
                ),
                viewModel: viewModel
            )
        }
    }
}
