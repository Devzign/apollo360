//
//  AppointmentViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 27/01/26.
//

import Foundation
import SwiftUI
import Combine
import AzureCommunicationCalling
import AzureCommunicationCommon
#if canImport(AzureCommunicationUICalling)
import AzureCommunicationUICalling
#endif
import UIKit

@MainActor
final class AppointmentViewModel: ObservableObject {
    @Published private(set) var appointments: [AppointmentCard] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isJoiningCall: Bool = false
    @Published private(set) var viewResetToken = UUID()
    @Published var errorMessage: String?
    @Published var joinErrorMessage: String?

    private let session: SessionManager
    private let service: AppointmentAPIService
    private var callClient: CallClient?
    private var callAgent: CallAgent?
    private var activeCall: Call?
#if canImport(AzureCommunicationUICalling)
    private var callComposite: CallComposite?
    private var callCompositeState: CallCompositeState = .idle
    private var pendingAppointmentToJoin: AppointmentCard?
    private var pendingJoinWorkItem: DispatchWorkItem?
    private var lastCompositeDismissedAt: Date?
#endif

    init(session: SessionManager, service: AppointmentAPIService) {
        self.session = session
        self.service = service
        loadAppointments()
    }

    convenience init(session: SessionManager) {
        self.init(session: session, service: .shared)
    }

    func refresh() {
        loadAppointments()
    }

    private func loadAppointments() {
        guard !isLoading else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            appointments = []
            return
        }

        isLoading = true
        errorMessage = nil

        service.fetchAppointments(bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.appointments = response.appointments.map { Self.card(from: $0, acsId: response.acsId, acsToken: response.acsToken) }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.appointments = []
            }
        }
    }

    func canJoinCall(for appointment: AppointmentCard) -> Bool {
        let room = appointment.acsRoomId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let acsToken = appointment.acsToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !room.isEmpty && !acsToken.isEmpty
    }

    func joinNativeCall(for appointment: AppointmentCard) {
        guard !isJoiningCall else {
#if canImport(AzureCommunicationUICalling)
            pendingAppointmentToJoin = appointment
#endif
            return
        }
#if canImport(AzureCommunicationUICalling)
        if callCompositeState != .idle || callComposite != nil {
            pendingAppointmentToJoin = appointment
            leaveCurrentCall()
            return
        }
#endif
        guard canJoinCall(for: appointment) else {
            joinErrorMessage = "Meeting details are missing for this appointment."
            return
        }
        guard UIApplication.shared.applicationState == .active else {
            joinErrorMessage = "Please open Apollo360 and try joining again."
            return
        }

        startJoin(for: appointment)
    }

    private func startJoin(for appointment: AppointmentCard) {
#if canImport(AzureCommunicationUICalling)
        pendingJoinWorkItem?.cancel()
        pendingJoinWorkItem = nil

        let cooldownInterval: TimeInterval = 2.0
        if let lastCompositeDismissedAt {
            let elapsed = Date().timeIntervalSince(lastCompositeDismissedAt)
            if elapsed < cooldownInterval {
                schedulePendingJoin(for: appointment, after: cooldownInterval - elapsed)
                return
            }
        }

        callCompositeState = .launching
#endif
        let roomId = (appointment.acsRoomId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let token = (appointment.acsToken ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = (session.username ?? "Guest").trimmingCharacters(in: .whitespacesAndNewlines)
        let safeName = displayName.isEmpty ? "Guest" : displayName

        do {
            isJoiningCall = true
            joinErrorMessage = nil

            let credential = try CommunicationTokenCredential(token: token)
#if canImport(AzureCommunicationUICalling)
            let options = CallCompositeOptions(
                theme: ApolloCallThemeOptions(),
                setupScreenOrientation: nil,
                callingScreenOrientation: nil,
                enableMultitasking: false,
                enableSystemPictureInPictureWhenMultitasking: false,
                displayName: safeName,
                disableInternalPushForIncomingCall: true
            )
            let composite = CallComposite(credential: credential, withOptions: options)
            callComposite = composite
            callCompositeState = .active

            composite.events.onDismissed = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.finishCompositeSession()
                }
            }
            composite.events.onError = { [weak self] error in
                DispatchQueue.main.async {
                    self?.finishCompositeSession()
                    self?.joinErrorMessage = Self.mapJoinError("\(error)")
                    self?.refresh()
                }
            }

            let localOptions = LocalOptions(
                cameraOn: true,
                microphoneOn: true,
                skipSetupScreen: true
            )
            composite.launch(locator: .roomCall(roomId: roomId), localOptions: localOptions)
#else
            let client = CallClient()
            callClient = client
            let callAgentOptions = CallAgentOptions()
            callAgentOptions.displayName = safeName
            client.createCallAgent(userCredential: credential, options: callAgentOptions) { [weak self] agent, agentError in
                guard let self else { return }
                DispatchQueue.main.async {
                    if let agentError {
                        self.isJoiningCall = false
                        self.joinErrorMessage = Self.mapJoinError(agentError.localizedDescription)
                        return
                    }
                    guard let agent else {
                        self.callClient = nil
                        self.isJoiningCall = false
                        self.joinErrorMessage = "Unable to create call agent."
                        return
                    }
                    self.callAgent = agent
                    let locator = RoomCallLocator(roomId: roomId)
                    let joinOptions = JoinCallOptions()
                    agent.join(with: locator, joinCallOptions: joinOptions) { [weak self] call, joinError in
                        guard let self else { return }
                        DispatchQueue.main.async {
                            if let joinError {
                                self.activeCall = nil
                                self.callAgent = nil
                                self.callClient = nil
                                self.isJoiningCall = false
                                self.joinErrorMessage = Self.mapJoinError(joinError.localizedDescription)
                                self.refresh()
                                return
                            }
                            self.activeCall = call
                            self.isJoiningCall = false
                        }
                    }
                }
            }
#endif
        } catch {
#if canImport(AzureCommunicationUICalling)
            callCompositeState = .idle
#endif
            isJoiningCall = false
            joinErrorMessage = Self.mapJoinError(error.localizedDescription)
        }
    }

    func leaveCurrentCall() {
#if canImport(AzureCommunicationUICalling)
        pendingJoinWorkItem?.cancel()
        pendingJoinWorkItem = nil
        if callComposite != nil {
            callCompositeState = .dismissing
        }
        callComposite?.dismiss()
#endif
        let hangUpOptions = HangUpOptions()
        activeCall?.hangUp(options: hangUpOptions) { [weak self] _ in
            DispatchQueue.main.async {
                self?.activeCall = nil
                self?.callAgent = nil
                self?.callClient = nil
            }
        }
        if activeCall == nil {
            callAgent = nil
            callClient = nil
        }
        isJoiningCall = false
    }

#if canImport(AzureCommunicationUICalling)
    private func finishCompositeSession() {
        pendingJoinWorkItem?.cancel()
        pendingJoinWorkItem = nil
        isJoiningCall = false
        callCompositeState = .idle
        callComposite = nil
        lastCompositeDismissedAt = Date()
        viewResetToken = UUID()
        refresh()

        guard let pendingAppointment = pendingAppointmentToJoin else { return }
        pendingAppointmentToJoin = nil

        schedulePendingJoin(for: pendingAppointment, after: 2.0)
    }

    private func schedulePendingJoin(for appointment: AppointmentCard, after delay: TimeInterval) {
        pendingAppointmentToJoin = appointment

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.callCompositeState == .idle, self.callComposite == nil else { return }
            guard let pendingAppointment = self.pendingAppointmentToJoin else { return }
            self.pendingAppointmentToJoin = nil
            self.startJoin(for: pendingAppointment)
        }

        pendingJoinWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private enum CallCompositeState {
        case idle
        case launching
        case active
        case dismissing
    }
#endif

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }()

    private static func mapJoinError(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("calljoinfailed")
            || lower.contains("408")
            || lower.contains("timed out")
            || lower.contains("not found")
            || lower.contains("room")
            || lower.contains("calljoin")
            || lower.contains("callcompositeerror")
            || lower.contains("code: \"calljoin\"") {
            return "Doctor has not started this appointment call yet. Please wait and try again in a moment."
        }
        if lower.contains("token") || lower.contains("credential") || lower.contains("unauthorized") {
            return "Session expired. Please sign in again and retry joining the meeting."
        }
        return raw
    }

    private static func card(from apiModel: AppointmentAPIModel, acsId: String?, acsToken: String?) -> AppointmentCard {
        let dateText: String
        if let date = apiModel.date {
            dateText = dateFormatter.string(from: date)
        } else {
            dateText = "Date TBD"
        }

        let timeText: String
        if let display = apiModel.displayTime, !display.isEmpty {
            timeText = display
        } else if let date = apiModel.date {
            timeText = timeFormatter.string(from: date)
        } else {
            timeText = "--"
        }

        let accent: Color
        if apiModel.callType?.lowercased().contains("video") == true {
            accent = AppColor.blue.opacity(0.15)
        } else if apiModel.isTelevisit {
            accent = AppColor.green.opacity(0.15)
        } else {
            accent = AppColor.yellow.opacity(0.15)
        }

        return AppointmentCard(
            id: UUID(),
            name: apiModel.provider,
            role: apiModel.role ?? "Care Team",
            date: dateText,
            time: timeText,
            accentColor: accent,
            callType: apiModel.callType,
            isTelevisit: apiModel.isTelevisit,
            acsId: acsId,
            acsToken: acsToken,
            acsRoomId: apiModel.acsRoomId
        )
    }
}

#if canImport(AzureCommunicationUICalling)
private struct ApolloCallThemeOptions: ThemeOptions {
    private var appGreen: UIColor {
        UIColor(named: "AppGreen") ?? UIColor.systemGreen
    }

    var primaryColor: UIColor {
        appGreen
    }

    var primaryColorTint10: UIColor {
        appGreen.withAlphaComponent(0.90)
    }

    var primaryColorTint20: UIColor {
        appGreen.withAlphaComponent(0.78)
    }

    var primaryColorTint30: UIColor {
        appGreen.withAlphaComponent(0.65)
    }
}
#endif
