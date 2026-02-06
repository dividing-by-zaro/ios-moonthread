import SwiftUI

struct ActionButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isActive ? "stop.circle" : "play.circle")
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(AppFont.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isActive ? AppColor.periodGold : AppColor.accent)
            .foregroundStyle(AppColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
