//
//  AppointmentView.swift
//  Apollo360
//
//  Created by Amit Sinha on 14/01/26.
//

import SwiftUI

struct AppointmentView: View {
    @StateObject private var viewModel: AppointmentViewModel
    @Environment(\.openURL) private var openURL
    let horizontalPadding: CGFloat
    @State private var visibleAppointments: Set<UUID> = []

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
        _viewModel = StateObject(wrappedValue: AppointmentViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 18) {
                Text("Upcoming Appointments")
                    .font(AppFont.display(size: 26, weight: .semibold))
                    .foregroundStyle(AppColor.black)
                    .padding(.top, 6)

                if viewModel.isLoading {
                    ProgressView("Loading appointments...")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .foregroundStyle(AppColor.grey)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error = viewModel.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(AppFont.body(size: 13, weight: .medium))
                        .foregroundStyle(AppColor.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !viewModel.isLoading && viewModel.appointments.isEmpty {
                    Text("No upcoming appointments found.")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .foregroundStyle(AppColor.grey)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(Array(viewModel.appointments.enumerated()), id: \.element.id) { index, appointment in
                    AppointmentCardView(appointment: appointment) {
                        guard let joinURL = viewModel.teamsJoinURL(for: appointment) else { return }
                        openURL(joinURL)
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
        .onAppear {
            viewModel.refresh()
        }
        .alert("Unable to Join Meeting", isPresented: Binding(
            get: { (viewModel.joinErrorMessage ?? "").isEmpty == false },
            set: { newValue in
                if !newValue {
                    viewModel.joinErrorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                viewModel.joinErrorMessage = nil
            }
        } message: {
            Text(viewModel.joinErrorMessage ?? "")
        }
    }
}

private struct AppointmentCardView: View {
    let appointment: AppointmentCard
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
                            .foregroundStyle(AppColor.green)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.name)
                        .font(AppFont.display(size: 20, weight: .semibold))
                        .foregroundStyle(AppColor.black)
                    Text(appointment.role)
                        .font(AppFont.body(size: 15, weight: .medium))
                        .foregroundStyle(AppColor.grey)
                }

                Spacer()
            }

            HStack(spacing: 14) {
                Label(appointment.date, systemImage: "calendar")
                    .font(AppFont.body(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.black.opacity(0.8))

                Spacer()

                Label(appointment.time, systemImage: "clock")
                    .font(AppFont.body(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.black.opacity(0.8))
            }
            .labelStyle(IconLeadingLabelStyle())

            Button(action: onJoin) {
                HStack {
                    Text("Join Video Call")
                        .font(AppFont.body(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "video")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColor.green)
                )
            }
            .buttonStyle(.plain)
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
                .foregroundStyle(AppColor.grey)
            configuration.title
        }
    }
}

#Preview("iPhone", traits: .sizeThatFitsLayout) {
    AppointmentView(horizontalPadding: 20, session: SessionManager())
        .environment(\.horizontalSizeClass, .compact)
}
