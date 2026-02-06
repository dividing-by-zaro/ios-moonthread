import SwiftUI

struct PeriodRow: View {
    let period: Period

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateFormatter.string(from: period.startDate))
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)

                if let end = period.endDate {
                    Text("to \(Self.dateFormatter.string(from: end))")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                } else {
                    Text("In progress")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.periodGold)
                }
            }

            Spacer()

            if let duration = period.durationDays {
                Text("\(duration)d")
                    .font(AppFont.title2)
                    .foregroundStyle(AppColor.textMuted)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(AppColor.periodGold)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
