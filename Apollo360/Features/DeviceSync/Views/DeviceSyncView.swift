import SwiftUI
import SafariServices
import Combine

struct DeviceSyncView: View {
    @Environment(\.presentationMode) private var presentationMode
    let session: SessionManager

    @StateObject private var store = HealthSyncStore()
    @State private var marketplaceURL: URL?
    @State private var showMarketplace = false
    @State private var didBootstrap = false

    private let knownDevices: [(name: String, key: String)] = [
        ("Apple Health", "healthkit"),
        ("Fitbit", "fitbit"),
        ("Withings", "withings"),
        ("Omron", "omron"),
        ("Garmin", "garmin")
    ]

    private var canOpenMarketplace: Bool {
        guard let marketplaceURL = store.marketplaceURL else { return false }
        return !marketplaceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBanner
                cardsSection
            }
            .padding(.bottom, 30)
        }
        .background(AppColor.secondary)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.configureIfNeeded()
            guard !didBootstrap else { return }
            didBootstrap = true
            Task { await store.refreshSourcesIfAvailable() }
        }
        .sheet(isPresented: $showMarketplace) {
            if let url = marketplaceURL {
                SafariView(url: url)
            }
        }
        .alert(isPresented: Binding(get: {
            store.errorMessage != nil
        }, set: { newValue in
            if !newValue { store.errorMessage = nil }
        })) {
            Alert(
                title: Text("Sync Devices"),
                message: Text(store.errorMessage ?? ""),
                dismissButton: .cancel(Text("OK")) { store.errorMessage = nil }
            )
        }
    }

    private var topBanner: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Color(hex: "#DCE6DF"), Color(hex: "#BFD5C2")], startPoint: .top, endPoint: .bottom)
                .frame(height: 310)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(spacing: 18) {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColor.color414141)
                    }

                    Text("Sync Devices")
                        .font(AppFont.display(size: 24, weight: .semibold))
                        .foregroundColor(AppColor.color414141)
                    Spacer()
                    Button {
                        openMarketplaceIfAvailable()
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 34, weight: .regular))
                            .foregroundColor(AppColor.color414141)
                    }
                    .disabled(!canOpenMarketplace)
                }

                Text("Swipe Down to Refresh")
                    .font(AppFont.display(size: 20, weight: .bold))
                    .foregroundColor(AppColor.black)
                    .multilineTextAlignment(.center)

                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 62, height: 62)
                    .overlay(
                        Image(systemName: "arrow.down")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(AppColor.color414141)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .padding(.horizontal, 0)
    }

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.28))
                .frame(height: 16)
                .padding(.horizontal, 2)

            VStack(spacing: 14) {
                summaryCard

                ForEach(knownDevices, id: \.key) { item in
                    deviceRow(name: item.name, isConnected: isConnected(sourceKey: item.key), actionTitle: isConnected(sourceKey: item.key) ? "Connected" : "Manage") {
                        openMarketplaceIfAvailable()
                    }
                }
            }

            Button {
                openMarketplaceIfAvailable()
            } label: {
                Text("Manage your devices")
                    .font(AppFont.body(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AppColor.green)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(!canOpenMarketplace)

            Button {
                Task { await syncNow() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(AppColor.black)
                    Text(buttonTitle)
                        .font(AppFont.body(size: 22, weight: .semibold))
                        .foregroundColor(AppColor.color414141)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColor.color414141, lineWidth: 1.5)
                )
            }
            .disabled(store.isSyncing || !store.isReadyForInitialSync)

            Button {
                Task { await store.refreshSourcesIfAvailable() }
            } label: {
                Text(store.isRefreshing ? "Refreshing..." : "Refresh device status")
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundColor(AppColor.color414141)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppColor.color414141.opacity(0.35), lineWidth: 1.2)
                    )
            }
            .disabled(store.isRefreshing || store.validicUID == nil)

            Text(lastSyncText)
                .font(AppFont.body(size: 14, weight: .medium))
                .foregroundColor(AppColor.grey)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(hex: "#F4F4F4"))
        )
        .padding(.horizontal, 0)
        .offset(y: -26)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            summaryRow(label: "Validic user id", value: store.validicUserID ?? "Not provisioned")
            summaryRow(label: "Validic uid", value: store.validicUID ?? "Not provisioned")
            summaryRow(label: "Timezone", value: store.timezone ?? "Unavailable")
            summaryRow(label: "Status", value: store.userStatus ?? "Unavailable")
            summaryRow(label: "Connected sources", value: "\(store.sourceTypes.count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFont.body(size: 14, weight: .medium))
                .foregroundColor(AppColor.grey)
            Spacer()
            Text(value)
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.color414141)
                .multilineTextAlignment(.trailing)
        }
    }

    private func deviceRow(name: String, isConnected: Bool, actionTitle: String, onAction: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.white)
                .frame(width: 56, height: 56)
                .overlay(
                    ZStack {
                        Text(initials(from: name))
                            .font(AppFont.body(size: 16, weight: .semibold))
                            .foregroundColor(AppColor.grey)

                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(isConnected ? Color.green : Color.red)
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }
                    }
                )

            Text(name)
                .font(AppFont.display(size: 18, weight: .medium))
                .foregroundColor(AppColor.color414141)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Button(actionTitle) { onAction() }
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundColor(isConnected ? AppColor.green : AppColor.green)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(minWidth: 84)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppColor.green, lineWidth: 1.4)
                )
                .disabled(isConnected || !canOpenMarketplace)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var buttonTitle: String {
        if store.isSyncing { return "Syncing..." }
        return "Sync with Apple Health"
    }

    private var lastSyncText: String {
        guard let date = store.lastSyncedAt else { return "Last Sync: Not synced yet" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Last Sync: \(formatter.string(from: date))"
    }

    private func isConnected(sourceKey: String) -> Bool {
        store.sourceTypes.contains { $0.contains(sourceKey) }
    }

    private func openMarketplaceIfAvailable() {
        guard let urlString = store.marketplaceURL, let url = URL(string: urlString) else {
            store.errorMessage = "Marketplace URL is not available yet. Please sync first."
            return
        }
        marketplaceURL = url
        showMarketplace = true
    }

    private func syncNow() async {
        let encodedUsername = resolveEncodedUsername()
        if encodedUsername.isEmpty, store.validicUID != nil {
            await store.syncFromCachedSession()
            return
        }

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "ios-device"
        await store.sync(encodedUsername: encodedUsername, deviceId: deviceId)
    }

    private func resolveEncodedUsername() -> String {
        let username = (session.username ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { return "" }

        if let data = Data(base64Encoded: username),
           let decoded = String(data: data, encoding: .utf8),
           !decoded.isEmpty {
            return username
        }

        return Data(username.utf8).base64EncodedString()
    }

    private func initials(from text: String) -> String {
        text.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}

@MainActor
final class HealthSyncStore: ObservableObject {
    @Published var isSyncing = false
    @Published var isRefreshing = false
    @Published var isReadyForInitialSync = false
    @Published var marketplaceURL: String?
    @Published var sourceTypes: [String] = []
    @Published var lastSyncedAt: Date?
    @Published var errorMessage: String?
    @Published var validicUserID: String?
    @Published var validicUID: String?
    @Published var timezone: String?
    @Published var userStatus: String?

    private var viewModel: HealthSyncViewModel?

    func configureIfNeeded() {
        guard viewModel == nil else { return }
        do {
            let config = try ApolloSyncConfig.fromInfoPlist()
            let service = ApolloSyncService(config: config)
            let vm = HealthSyncViewModel(service: service)
            viewModel = vm
            apply(from: vm)
            refreshReadiness()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sync(encodedUsername: String, deviceId: String) async {
        guard let viewModel else {
            errorMessage = "Device sync is not configured."
            return
        }

        isSyncing = true
        await viewModel.sync(encodedUsername: encodedUsername, deviceId: deviceId)
        isSyncing = false

        apply(from: viewModel)
        refreshReadiness()

        if case .failure(let message) = viewModel.state {
            errorMessage = message
        }
    }

    func refreshSourcesIfAvailable() async {
        guard let viewModel else {
            errorMessage = "Device sync is not configured."
            return
        }

        isRefreshing = true
        await viewModel.refreshSources()
        isRefreshing = false

        apply(from: viewModel)
        refreshReadiness()

        if case .failure(let message) = viewModel.state {
            errorMessage = message
        }
    }

    func syncFromCachedSession() async {
        guard let viewModel else {
            errorMessage = "Device sync is not configured."
            return
        }

        isSyncing = true
        await viewModel.syncFromCachedSession()
        isSyncing = false

        apply(from: viewModel)
        refreshReadiness()

        if case .failure(let message) = viewModel.state {
            errorMessage = message
        }
    }

    private func apply(from viewModel: HealthSyncViewModel) {
        marketplaceURL = viewModel.marketplaceURL
        sourceTypes = viewModel.sourceTypes
        lastSyncedAt = viewModel.lastSyncedAt
        validicUserID = viewModel.validicUserID
        validicUID = viewModel.validicUID
        timezone = viewModel.timezone
        userStatus = viewModel.userStatus
    }

    private func refreshReadiness() {
        let token = UserDefaults.standard.string(forKey: "Apollo360.accessToken")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let username = UserDefaults.standard.string(forKey: "Apollo360.username")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        isReadyForInitialSync = !token.isEmpty && (!username.isEmpty || validicUID != nil)
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(AppColor.green)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DeviceSyncView(session: SessionManager())
}
