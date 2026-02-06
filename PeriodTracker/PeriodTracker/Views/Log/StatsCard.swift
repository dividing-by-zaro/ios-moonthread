import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(AppFont.statLabel)
                .foregroundStyle(AppColor.textMuted)
                .textCase(.uppercase)
                .tracking(1)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(AppFont.statValue)
                    .foregroundStyle(AppColor.textPrimary)

                Text(unit)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
