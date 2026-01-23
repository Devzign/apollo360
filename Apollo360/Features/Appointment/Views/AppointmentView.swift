//
//  AppointmentView.swift
//  Apollo360
//
//  Created by Amit Sinha on 14/01/26.
//

import SwiftUI

struct AppointmentView: View {
    let horizontalPadding: CGFloat

    private let appointments: [AppointmentCard] = [
        AppointmentCard(
            name: "Dr. Michael Ghalchi",
            role: "Doctor",
            date: "07-03-2025",
            time: "09:30 am",
            accentColor: AppColor.green.opacity(0.18)
        ),
        AppointmentCard(
            name: "Dr. Nancy Gates",
            role: "Super Admin",
            date: "07-03-2025",
            time: "09:30 am",
            accentColor: AppColor.green.opacity(0.14)
        ),
        AppointmentCard(
            name: "Dr. Emily Johnson",
            role: "Therapist",
            date: "07-04-2025",
            time: "10:00 am",
            accentColor: AppColor.green.opacity(0.12)
        )
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Upcoming Appointments")
                    .font(AppFont.display(size: 26, weight: .semibold))
                    .foregroundStyle(AppColor.black)
                    .padding(.top, 6)

                ForEach(appointments) { appointment in
                    AppointmentCardView(appointment: appointment)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
        .background(AppColor.secondary.ignoresSafeArea())
    }
}

private struct AppointmentCard: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let date: String
    let time: String
    let accentColor: Color
}

private struct AppointmentCardView: View {
    let appointment: AppointmentCard

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

            Button(action: {}) {
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

#Preview("iPhone") {
    AppointmentView(horizontalPadding: 20)
        .previewLayout(.sizeThatFits)
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPad") {
    AppointmentView(horizontalPadding: 50)
        .previewLayout(.sizeThatFits)
        .environment(\.horizontalSizeClass, .regular)
}
