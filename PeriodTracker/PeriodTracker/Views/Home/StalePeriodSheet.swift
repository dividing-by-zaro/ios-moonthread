import SwiftUI

struct StalePeriodSheet: View {
    let period: Period
    let daysSinceStart: Int
    let suggestedEndDate: Date
    let errorMessage: String?
    let onConfirm: (Date) async -> Void

    @State private var endDate: Date
    @State private var isSubmitting = false

    init(
        period: Period,
        daysSinceStart: Int,
        suggestedEndDate: Date,
        errorMessage: String?,
        onConfirm: @escaping (Date) async -> Void
    ) {
        self.period = period
        self.daysSinceStart = daysSinceStart
        self.suggestedEndDate = suggestedEndDate
        self.errorMessage = errorMessage
        self.onConfirm = onConfirm
        _endDate = State(initialValue: suggestedEndDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColor.periodGold)

                    VStack(spacing: 8) {
                        Text("Still on your period?")
                            .font(AppFont.headline)
                            .foregroundStyle(AppColor.textPrimary)

                        Text("It's been \(daysSinceStart) days since you marked the start of your period.")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("END DATE")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                        DatePicker(
                            "",
                            selection: $endDate,
                            in: period.startDate...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppColor.accent)
                        .colorScheme(.dark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        isSubmitting = true
                        Task {
                            await onConfirm(endDate)
                            isSubmitting = false
                        }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView()
                                    .tint(AppColor.background)
                            } else {
                                Text("End Period")
                                    .font(AppFont.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColor.periodGold)
                        .foregroundStyle(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isSubmitting)

                    if let error = errorMessage {
                        Text(error)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.error)
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }
}
