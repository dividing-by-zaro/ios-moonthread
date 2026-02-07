import SwiftUI

struct RegularityGauge: View {
    let vm: StatsViewModel

    private let startAngle = Angle.degrees(135)
    private let endAngle = Angle.degrees(405)
    private let lineWidth: CGFloat = 14

    var body: some View {
        if let score = vm.regularityScore {
            VStack(spacing: 16) {
                ZStack {
                    // Background track
                    arcPath
                        .stroke(AppColor.surfaceElevated, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                    // Gradient fill
                    arcPath
                        .trim(from: 0, to: score / 100)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [AppColor.periodGold, AppColor.accentDim, AppColor.accent]),
                                center: .center,
                                startAngle: startAngle,
                                endAngle: endAngle
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )

                    // Score text
                    VStack(spacing: 4) {
                        Text("\(Int(score.rounded()))")
                            .font(AppFont.statValue)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("/ 100")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textMuted)
                    }
                }
                .frame(width: 180, height: 180)

                Text(vm.regularityLabel)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } else {
            Text("Not enough data")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
        }
    }

    private var arcPath: Path {
        Path { p in
            p.addArc(
                center: CGPoint(x: 90, y: 90),
                radius: 90 - lineWidth / 2,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
    }
}
