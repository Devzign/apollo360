import SwiftUI

struct SyncInstructionSource: Identifiable {
    let value: String
    let metricTitle: String
    var id: String { "\(value)-\(metricTitle)" }
}

struct SyncInstructionSheet: View {
    let source: String
    let metricTitle: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("Source Your Devices")
                    .font(AppFont.body(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 22 / 255, green: 31 / 255, blue: 37 / 255))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 25, weight: .regular))
                        .foregroundColor(Color(red: 35 / 255, green: 172 / 255, blue: 114 / 255))
                }
                .buttonStyle(.plain)
            }

            Text("How to Sync your device with Apollo — Step-by-Step")
                .font(AppFont.body(size: 15, weight: .regular))
                .foregroundColor(textColor)
                .padding(.top, 22)

            Text(instructions)
                .font(AppFont.body(size: 14, weight: .regular))
                .foregroundColor(textColor)
                .lineSpacing(5)
                .padding(.top, 24)

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 22)
        .background(Color(red: 247 / 255, green: 255 / 255, blue: 250 / 255))
    }

    private let textColor = Color(red: 96 / 255, green: 115 / 255, blue: 123 / 255)

    private var instructions: String {
        """
        1. Take a new reading on your device.
        2. Open the device's companion app and confirm the reading appears.
        3. Return to the Apollo app and tap Sync Now.

        If the reading is still missing:
        • Open the side menu (top-left) and go to Account → Synced Device.
        • Tap Resync. Find your device in the list and check its status.
        • If syncing has stopped, tap Manage to reconnect — disconnect, then reconnect with your account credentials.

        Once reconnected, \(metricTitle) should resume syncing automatically.
        """
    }
}

func isOlderThan48Hours(_ raw: String?) -> Bool {
    guard let raw else { return true }
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let date = fractional.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
    guard let date else { return true }
    return Date().timeIntervalSince(date) >= (48 * 60 * 60)
}
