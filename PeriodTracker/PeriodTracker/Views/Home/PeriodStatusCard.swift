import SwiftUI

struct PeriodStatusCard: View {
    let statusText: String
    let subtitleText: String
    let isActive: Bool
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 20) {
            if isActive {
                activeView
            } else {
                inactiveView
            }
        }
    }

    private var activeView: some View {
        VStack(spacing: 20) {
            ZStack {
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

                Circle()
                    .stroke(AppColor.periodGold, lineWidth: 3)
                    .frame(width: 160, height: 160)

                Text(statusText)
                    .font(AppFont.statValue)
                    .foregroundStyle(AppColor.periodGold)
            }

            Text(subtitleText)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var inactiveView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars")
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(AppColor.accentDim)

            VStack(spacing: 6) {
                Text(statusText)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)

                if !subtitleText.isEmpty {
                    Text(subtitleText)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }
}

struct StarField: View {
    let count: Int

    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    // Simple deterministic hash to get pseudo-random 0..1 values
    private static func hash(_ seed: Int) -> Double {
        var x = UInt32(truncatingIfNeeded: seed &* 2654435761)
        x ^= x >> 16
        x &*= 0x45d9f3b
        x ^= x >> 16
        return Double(x & 0x7FFFFFFF) / Double(0x7FFFFFFF)
    }

    private var stars: [Star] {
        // Cluster centers for natural grouping
        let clusters: [(cx: Double, cy: Double)] = [
            (0.20, 0.15), (0.75, 0.10), (0.85, 0.45),
            (0.15, 0.70), (0.65, 0.80), (0.40, 0.40),
        ]
        return (0..<count).map { i in
            let h1 = Self.hash(i * 3 + 1)
            let h2 = Self.hash(i * 3 + 2)
            let h3 = Self.hash(i * 3 + 3)
            let h4 = Self.hash(i * 5 + 7)
            let h5 = Self.hash(i * 7 + 11)

            let x: Double
            let y: Double
            // ~40% of stars cluster near a center, rest are fully scattered
            if h5 < 0.4 {
                let cluster = clusters[i % clusters.count]
                let spread = 0.12
                x = cluster.cx + (h1 - 0.5) * spread
                y = cluster.cy + (h2 - 0.5) * spread
            } else {
                x = h1
                y = h2
            }

            let size = 1.5 + h3 * 2.0
            let opacity = 0.15 + h4 * 0.45
            return Star(id: i, x: x, y: y, size: size, opacity: opacity)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                Circle()
                    .fill(AppColor.accentDim.opacity(star.opacity))
                    .frame(width: star.size, height: star.size)
                    .position(
                        x: star.x * geo.size.width,
                        y: star.y * geo.size.height
                    )
            }
        }
    }
}
