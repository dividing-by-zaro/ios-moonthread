import SwiftUI
import Charts

struct CycleLengthChart: View {
    let vm: StatsViewModel

    var body: some View {
        if vm.cycleLengths.count >= 2 {
            Chart {
                ForEach(vm.cycleLengthMovingAverage) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Moving Average", point.average)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColor.accent.opacity(0.22), AppColor.accent.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Moving Average", point.average)
                    )
                    .foregroundStyle(AppColor.accent)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    if point.date == vm.cycleLengthMovingAverage.last?.date {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Moving Average", point.average)
                        )
                        .foregroundStyle(AppColor.accent)
                        .symbolSize(28)
                    }
                }

                ForEach(vm.cycleLengths) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Days", point.length)
                    )
                    .foregroundStyle(AppColor.textMuted.opacity(0.45))
                    .symbolSize(16)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v.rounded()))d")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textMuted)
                        } else if let v = value.as(Int.self) {
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
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let plotFrame = proxy.plotFrame,
                       let recentAverage = vm.cycleLengthMovingAverage.last?.average {
                        let frame = geometry[plotFrame]

                        VStack {
                            HStack {
                                Spacer()
                                Text("Recent average \(Int(recentAverage.rounded()))d")
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppColor.textMuted)
                                    .padding(.top, 6)
                                    .padding(.trailing, 6)
                            }
                            Spacer()
                        }
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
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
