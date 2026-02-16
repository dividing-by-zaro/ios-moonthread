import SwiftUI

struct DatePickerSheet: View {
    let label: String
    let buttonTitle: String
    let dateRange: ClosedRange<Date>
    let errorMessage: String?
    let onConfirm: (Date) async -> Void
    let onCancel: () -> Void

    @State private var selectedDate: Date
    @State private var isSubmitting = false

    init(
        label: String,
        buttonTitle: String,
        dateRange: ClosedRange<Date>,
        initialDate: Date,
        errorMessage: String?,
        onConfirm: @escaping (Date) async -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.label = label
        self.buttonTitle = buttonTitle
        self.dateRange = dateRange
        self.errorMessage = errorMessage
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _selectedDate = State(initialValue: initialDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(label)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: dateRange,
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
                            await onConfirm(selectedDate)
                            isSubmitting = false
                        }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView()
                                    .tint(AppColor.background)
                            } else {
                                Text(buttonTitle)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
