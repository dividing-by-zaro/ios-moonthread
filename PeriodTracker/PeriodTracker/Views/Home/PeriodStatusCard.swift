import SwiftUI

struct PeriodStatusCard: View {
    let statusText: String
    let subtitleText: String
    let isActive: Bool
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Pulsing ring for active period
                if isActive {
                    Circle()
                        .stroke(AppColor.periodGold.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)
                        .opacity(2 - Double(pulseScale))
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                                pulseScale = 1.8
                            }
                        }
                }

                Circle()
                    .stroke(
                        isActive ? AppColor.periodGold : AppColor.accentDim.opacity(0.3),
                        lineWidth: isActive ? 3 : 1
                    )
                    .frame(width: 160, height: 160)

                Text(statusText)
                    .font(AppFont.statValue)
                    .foregroundStyle(isActive ? AppColor.periodGold : AppColor.textPrimary)
            }

            Text(subtitleText)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}
