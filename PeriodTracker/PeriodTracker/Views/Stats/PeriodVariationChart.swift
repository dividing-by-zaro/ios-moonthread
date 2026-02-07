import SwiftUI
import Charts

struct PeriodVariationChart: View {
    let vm: StatsViewModel

    var body: some View {
        let durations = vm.periodDurations

        if durations.count >= 2 {
            let avg = vm.averageDuration ?? 0
            let stdDev = vm.durationStdDev ?? 0

            Chart {
                // Standard deviation band
                if stdDev > 0 {
                    RectangleMark(
                        xStart: .value("Start", durations.first!.date),
                        xEnd: .value("End", durations.last!.date),
                        yStart: .value("Low", max(0, avg - stdDev)),
                        yEnd: .value("High", avg + stdDev)
                    )
                    .foregroundStyle(AppColor.periodGoldDim.opacity(0.25))
                }

                // Average line
                RuleMark(y: .value("Average", avg))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .foregroundStyle(AppColor.textMuted)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("average \(String(format: "%.1f", avg))d")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textMuted)
                    }

                // Individual points
                ForEach(durations) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Duration", point.duration)
                    )
                    .foregroundStyle(AppColor.periodGold)
                    .symbolSize(40)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)d")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textMuted)
                        }
                    }
                    AxisGridLine()
                        .foregroundStyle(AppColor.textMuted.opacity(0.2))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(vm.selectedYear == nil
                                ? date.formatted(.dateTime.year())
                                : date.formatted(.dateTime.month(.abbreviated)))
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
