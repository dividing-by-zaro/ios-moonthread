import SwiftUI

struct HomeView: View {
    @State private var vm = HomeViewModel()
    @Binding var isAuthenticated: Bool

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                if vm.isLoading && vm.stats == nil {
                    ProgressView()
                        .tint(AppColor.accent)
                        .scaleEffect(1.5)
                } else {
                    PeriodStatusCard(
                        statusText: vm.statusText,
                        subtitleText: vm.subtitleText,
                        isActive: vm.isActive
                    )
                }

                Spacer()

                if vm.stats != nil {
                    ActionButton(
                        title: vm.actionButtonTitle,
                        isActive: vm.isActive
                    ) {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        Task { await vm.togglePeriod() }
                    }
                    .padding(.horizontal, 32)
                }

                if let error = vm.errorMessage, !vm.showUnauthorized {
                    Text(error)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.error)
                        .padding(.horizontal)
                }

                Spacer()
                    .frame(height: 20)
            }
        }
        .task { await vm.load() }
        .onChange(of: vm.showUnauthorized) { _, val in
            if val { isAuthenticated = false }
        }
    }
}
