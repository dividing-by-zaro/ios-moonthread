import SwiftUI
import Charts

struct CycleLengthChart: View {
    let vm: StatsViewModel

    var body: some View {
        if vm.cycleLengths.count >= 2 {
            Chart {
                if let avg = vm.averageCycleLength {
                    RuleMark(y: .value("Average", avg))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        .foregroundStyle(AppColor.textMuted)
                        .annotation(position: .top, alignment: .trailing) {
                            Text("average \(Int(avg.rounded()))d")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textMuted)
                        }
                }

                ForEach(vm.cycleLengths) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Days", point.length)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColor.accent.opacity(0.3), AppColor.accent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Days", point.length)
                    )
                    .foregroundStyle(AppColor.accent)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Days", point.length)
                    )
                    .foregroundStyle(AppColor.accent)
                    .symbolSize(20)
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
            emptyState
        }
    }

    private var emptyState: some View {
        Text("Not enough data")
            .font(AppFont.body)
            .foregroundStyle(AppColor.textMuted)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
    }
}
