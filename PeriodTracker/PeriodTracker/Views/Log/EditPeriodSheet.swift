import SwiftUI

struct EditPeriodSheet: View {
    let period: Period
    let onSave: (Date, Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hasEndDate: Bool

    init(period: Period, onSave: @escaping (Date, Date?) -> Void) {
        self.period = period
        self.onSave = onSave
        _startDate = State(initialValue: period.startDate)
        _endDate = State(initialValue: period.endDate ?? Date())
        _hasEndDate = State(initialValue: period.endDate != nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("START DATE")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                        DatePicker(
                            "",
                            selection: $startDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppColor.accent)
                        .colorScheme(.dark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("END DATE")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textSecondary)
                        if hasEndDate {
                            HStack {
                                DatePicker(
                                    "",
                                    selection: $endDate,
                                    in: startDate...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(AppColor.accent)
                                .colorScheme(.dark)

                                Button {
                                    hasEndDate = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(AppColor.textMuted)
                                }
                            }
                        } else {
                            Button {
                                endDate = startDate
                                hasEndDate = true
                            } label: {
                                Text("Add end date")
                                    .font(AppFont.body)
                                    .foregroundStyle(AppColor.accent)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Edit Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColor.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(startDate, hasEndDate ? endDate : nil)
                        dismiss()
                    }
                    .foregroundStyle(AppColor.accent)
                }
            }
        }
    }
}
