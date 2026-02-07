import SwiftUI
import Charts

struct DayOfWeekChart: View {
    let vm: StatsViewModel

    var body: some View {
        let data = vm.dayOfWeekCounts
        let hasData = data.contains { $0.count > 0 }

        if hasData {
            Chart(data) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Day", item.dayName)
                )
                .foregroundStyle(item.isMax ? AppColor.accent : AppColor.accentDim)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textMuted)
                        }
                    }
                    AxisGridLine()
                        .foregroundStyle(AppColor.textMuted.opacity(0.2))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self) {
                            Text(name)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 220)
        } else {
            Text("Not enough data")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
        }
    }
}
