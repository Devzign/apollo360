//
//  BiometricLockView.swift
//  Apollo360
//

import SwiftUI

struct BiometricLockView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var didAttempt = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Green gradient background — matches the login screen
            LinearGradient(
                colors: [AppColor.green, AppColor.green.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                Image("apolloLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                    .padding(.bottom, 40)

                // Card
                VStack(spacing: 28) {
                    // Face ID icon ring
                    ZStack {
                        Circle()
                            .fill(AppColor.green.opacity(0.12))
                            .frame(width: 96, height: 96)
                        Circle()
                            .stroke(AppColor.green.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 96, height: 96)
                        Image(systemName: "faceid")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(AppColor.green)
                    }

                    VStack(spacing: 8) {
                        Text("Welcome back!")
                            .font(AppFont.display(size: 26, weight: .bold))
                            .foregroundColor(AppColor.black)
                        Text("Unlock with Face ID to continue")
                            .font(AppFont.body(size: 14))
                            .foregroundColor(AppColor.grey)
                            .multilineTextAlignment(.center)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(AppFont.body(size: 13))
                            .foregroundColor(AppColor.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    // Unlock button
                    Button(action: attemptUnlock) {
                        Label("Unlock with Face ID", systemImage: "faceid")
                            .font(AppFont.body(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppColor.green)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: AppColor.green.opacity(0.35), radius: 12, y: 5)
                    }

                    // Fallback: go back to full login
                    Button("Sign in with a different account") {
                        session.clearSession()
                    }
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.grey)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.14), radius: 24, x: 0, y: 10)
                )
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            // Delay slightly so the view is fully rendered before the system prompt
            if !didAttempt {
                didAttempt = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    attemptUnlock()
                }
            }
        }
    }

    private func attemptUnlock() {
        errorMessage = nil
        session.unlockWithBiometrics { result in
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#if DEBUG
struct BiometricLockView_Previews: PreviewProvider {
    static var previews: some View {
        BiometricLockView()
            .environmentObject(SessionManager())
    }
}
#endif
