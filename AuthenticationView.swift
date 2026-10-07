import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "checklist")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.tint)
                VStack(spacing: 8) {
                    Text(viewModel.isCreatingAccount ? "Create your account" : "Welcome back")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Keep your tasks organized and in sync.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("auth.email")

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(viewModel.isCreatingAccount ? .newPassword : .password)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("auth.password")

                    if viewModel.isCreatingAccount {
                        SecureField("Confirm password", text: $viewModel.confirmation)
                            .textContentType(.newPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if let message = viewModel.errorMessage {
                    Label(message, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("auth.error")
                }
                if let message = viewModel.informationMessage {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await viewModel.authenticate() }
                } label: {
                    HStack {
                        if viewModel.isLoading { ProgressView().tint(.white) }
                        Text(viewModel.isCreatingAccount ? "Create account" : "Sign in")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("auth.submit")

                if !viewModel.isCreatingAccount {
                    Button("Forgot password?") {
                        Task { await viewModel.resetPassword() }
                    }
                    .disabled(viewModel.isLoading)
                }

                Button {
                    viewModel.isCreatingAccount.toggle()
                    viewModel.errorMessage = nil
                    viewModel.informationMessage = nil
                    viewModel.confirmation = ""
                } label: {
                    Text(viewModel.isCreatingAccount
                         ? "Already have an account? Sign in"
                         : "New here? Create an account")
                        .font(.subheadline.weight(.medium))
                }
                .disabled(viewModel.isLoading)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}
