import SwiftUI

struct DayCell: View {
    let date: Date
    let isPeriodDay: Bool
    let isToday: Bool
    var isPredicted: Bool = false

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            if isPeriodDay {
                Circle()
                    .fill(AppColor.periodGold.opacity(0.25))

                Circle()
                    .stroke(AppColor.periodGold.opacity(0.5), lineWidth: 1)
            } else if isPredicted {
                Circle()
                    .fill(AppColor.periodGold.opacity(0.10))

                Circle()
                    .stroke(AppColor.periodGold.opacity(0.30),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }

            if isToday && !isPeriodDay && !isPredicted {
                Circle()
                    .stroke(AppColor.accent, lineWidth: 1.5)
            }

            Text(dayNumber)
                .font(AppFont.body)
                .foregroundStyle(
                    isPeriodDay ? AppColor.periodGold :
                    isPredicted ? AppColor.periodGold.opacity(0.6) :
                    isToday ? AppColor.accent :
                    AppColor.textPrimary
                )
        }
        .frame(width: 36, height: 36)
    }
}
