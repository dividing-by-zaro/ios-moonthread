import SwiftUI
import Charts

struct MonthlyDaysChart: View {
    let vm: StatsViewModel

    var body: some View {
        let data = vm.monthlyPeriodDays
        let hasData = data.contains { $0.days > 0 }

        if hasData {
            Chart(data) { item in
                BarMark(
                    x: .value("Month", item.monthName),
                    y: .value("Days", item.days)
                )
                .foregroundStyle(AppColor.periodGold)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
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
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self) {
                            Text(name)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textMuted)
                        }
                    }
                }
            }
            .frame(height: 200)
        } else {
            Text("Not enough data")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
        }
    }
}
