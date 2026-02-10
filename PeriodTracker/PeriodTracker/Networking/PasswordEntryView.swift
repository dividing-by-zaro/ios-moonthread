import SwiftUI

struct PasswordEntryView: View {
    @Binding var isAuthenticated: Bool
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "lock.shield")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(AppColor.accent)

                Text("MoonThread")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Enter your API password")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)

                VStack(spacing: 16) {
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textPrimary)
                        .padding()
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(AppColor.accentDim.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isFocused)
                        .onSubmit { connect() }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.error)
                    }

                    Button(action: connect) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(AppColor.background)
                            } else {
                                Text("Connect")
                                    .font(AppFont.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.accent)
                        .foregroundStyle(AppColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(password.isEmpty || isLoading)
                    .opacity(password.isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
        .onAppear { isFocused = true }
    }

    private func connect() {
        guard !password.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        KeychainHelper.save(password: password)

        Task {
            do {
                _ = try await APIClient.shared.fetchStats()
                await MainActor.run {
                    isAuthenticated = true
                }
            } catch let error as APIError where error.errorDescription == "Invalid API key" {
                KeychainHelper.delete()
                await MainActor.run {
                    errorMessage = "Wrong password. Try again."
                    isLoading = false
                }
            } catch {
                KeychainHelper.delete()
                await MainActor.run {
                    errorMessage = "Connection failed. Check your network and try again."
                    isLoading = false
                }
            }
        }
    }
}
