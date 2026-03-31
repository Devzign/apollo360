//
//  AppointmentView.swift
//  Apollo360
//
//  Created by Amit Sinha on 14/01/26.
//

import SwiftUI
import AVFoundation

struct AppointmentView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: AppointmentViewModel
    let horizontalPadding: CGFloat
    @State private var visibleAppointments: Set<UUID> = []
    @State private var pendingJoinAppointment: AppointmentCard?
    @State private var activeAlert: AppointmentAlert?

    private enum AppointmentAlert: Identifiable {
        case joinError
        case permissionPrompt
        case settingsPrompt

        var id: Int {
            switch self {
            case .joinError: return 0
            case .permissionPrompt: return 1
            case .settingsPrompt: return 2
            }
        }
    }

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
        _viewModel = StateObject(wrappedValue: AppointmentViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 18) {
                Text("Upcoming Appointments")
                    .font(AppFont.display(size: 26, weight: .semibold))
                    .foregroundColor(AppColor.black)
                    .padding(.top, 6)

                if viewModel.isLoading {
                    ProgressView("Loading appointments...")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .foregroundColor(AppColor.grey)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error = viewModel.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(AppFont.body(size: 13, weight: .medium))
                        .foregroundColor(AppColor.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !viewModel.isLoading && viewModel.appointments.isEmpty {
                    Text("No upcoming appointments found.")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .foregroundColor(AppColor.grey)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(Array(viewModel.appointments.enumerated()), id: \.element.id) { index, appointment in
                    AppointmentCardView(appointment: appointment,
                                        canJoin: viewModel.canJoinCall(for: appointment)) {
                        handleJoinTap(for: appointment)
                    }
                        .opacity(visibleAppointments.contains(appointment.id) ? 1 : 0)
                        .offset(y: visibleAppointments.contains(appointment.id) ? 0 : 22)
                        .onAppear {
                            guard !visibleAppointments.contains(appointment.id) else { return }
                            _ = withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.08)) {
                                visibleAppointments.insert(appointment.id)
                            }
                        }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .id(viewModel.viewResetToken)
        .onAppear {
            viewModel.refresh()
        }
        .onChange(of: viewModel.viewResetToken) { _ in
            visibleAppointments = []
            pendingJoinAppointment = nil
            activeAlert = nil
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .joinError:
                return Alert(
                    title: Text("Unable to Join Meeting"),
                    message: Text(viewModel.joinErrorMessage ?? ""),
                    dismissButton: .cancel(Text("OK")) {
                        viewModel.joinErrorMessage = nil
                    }
                )
            case .permissionPrompt:
                return Alert(
                    title: Text("Camera & Microphone Access"),
                    message: Text("To join the meeting, allow camera and microphone access."),
                    primaryButton: .default(Text("Continue")) {
                        requestPermissionsAndJoin()
                    },
                    secondaryButton: .cancel(Text("Not Now")) {
                        pendingJoinAppointment = nil
                    }
                )
            case .settingsPrompt:
                return Alert(
                    title: Text("Permission Required"),
                    message: Text("Camera or microphone access is disabled. Please enable both in Settings to join the meeting."),
                    primaryButton: .default(Text("Open Settings")) {
                        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                        openURL(settingsURL)
                    },
                    secondaryButton: .cancel(Text("Cancel")) {
                        pendingJoinAppointment = nil
                    }
                )
            }
        }
        .onChange(of: viewModel.joinErrorMessage) { newValue in
            activeAlert = (newValue ?? "").isEmpty ? nil : .joinError
        }
    }

    private func handleJoinTap(for appointment: AppointmentCard) {
        pendingJoinAppointment = appointment

        if hasRequiredPermissions {
            viewModel.joinNativeCall(for: appointment)
            pendingJoinAppointment = nil
            return
        }

        if hasDeniedPermissions {
            activeAlert = .settingsPrompt
            return
        }

        activeAlert = .permissionPrompt
    }

    private var hasRequiredPermissions: Bool {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micPermission = AVAudioSession.sharedInstance().recordPermission
        return cameraStatus == .authorized && micPermission == .granted
    }

    private var hasDeniedPermissions: Bool {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micPermission = AVAudioSession.sharedInstance().recordPermission
        let cameraDenied = cameraStatus == .denied || cameraStatus == .restricted
        let micDenied = micPermission == .denied
        return cameraDenied || micDenied
    }

    private func requestPermissionsAndJoin() {
        guard let appointment = pendingJoinAppointment else { return }

        AVCaptureDevice.requestAccess(for: .video) { _ in
            AVAudioSession.sharedInstance().requestRecordPermission { _ in
                DispatchQueue.main.async {
                    if hasRequiredPermissions {
                        viewModel.joinNativeCall(for: appointment)
                        pendingJoinAppointment = nil
                    } else {
                        activeAlert = .settingsPrompt
                    }
                }
            }
        }
    }
}

private struct AppointmentCardView: View {
    let appointment: AppointmentCard
    let canJoin: Bool
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(appointment.accentColor)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(AppColor.green)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.name)
                        .font(AppFont.display(size: 20, weight: .semibold))
                        .foregroundColor(AppColor.black)
                    Text(appointment.role)
                        .font(AppFont.body(size: 15, weight: .medium))
                        .foregroundColor(AppColor.grey)
                }

                Spacer()
            }

            HStack(spacing: 14) {
                Label(appointment.date, systemImage: "calendar")
                    .font(AppFont.body(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.black.opacity(0.8))

                Spacer()

                Label(appointment.time, systemImage: "clock")
                    .font(AppFont.body(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.black.opacity(0.8))
            }
            .labelStyle(IconLeadingLabelStyle())

            Button(action: onJoin) {
                HStack {
                    Text(canJoin ? "Join Video Call" : "Meeting Not Available")
                        .font(AppFont.body(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "video")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColor.green.opacity(canJoin ? 1 : 0.45))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canJoin)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
        )
    }
}

private struct IconLeadingLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundColor(AppColor.grey)
            configuration.title
        }
    }
}

#if DEBUG
struct AppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentView(horizontalPadding: 20, session: SessionManager())
            .environment(\.horizontalSizeClass, .compact)
            .previewLayout(.sizeThatFits)
    }
}
#endif
