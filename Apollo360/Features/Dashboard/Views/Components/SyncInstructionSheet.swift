import SwiftUI

struct SyncInstructionSource: Identifiable {
    let value: String
    var id: String { value }
}

struct SyncInstructionSheet: View {
    let source: String

    private var normalized: String { source.lowercased() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sync Instructions")
                .font(AppFont.display(size: 28, weight: .semibold))
            Text("Source: \(source)")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.grey)

            Text(message)
                .font(AppFont.body(size: 14, weight: .regular))
                .foregroundColor(AppColor.color414141)

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    private var message: String {
        if normalized.contains("apple") {
            return "Open Device Sync and connect Apple Health. Then tap Sync to refresh this metric."
        }
        if normalized.contains("fitbit") {
            return "Open Device Sync and connect Fitbit account. After successful connection, run Sync again."
        }
        if normalized.contains("withings") {
            return "Open Device Sync and connect Withings account, then sync once to pull the latest readings."
        }
        return "Connect this source from Device Sync and run a manual sync to update your dashboard values."
    }
}

func isOlderThan48Hours(_ raw: String?) -> Bool {
    guard let raw, let date = ISO8601DateFormatter().date(from: raw) else { return true }
    return Date().timeIntervalSince(date) >= (48 * 60 * 60)
}
