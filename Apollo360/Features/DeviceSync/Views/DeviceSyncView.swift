import SwiftUI
import HealthKit
import WebKit
import Combine

struct DeviceSyncView: View {
    @Environment(\.presentationMode) private var presentationMode
    let session: SessionManager

    @StateObject private var store = HealthSyncStore()
    @State private var marketplaceURL: URL?
    @State private var showMarketplace = false
    @State private var didBootstrap = false

    // All supported devices — (display name, Validic source key, icon asset name)
    private let knownDevices: [(name: String, key: String, icon: String)] = [
        ("Apple Health", "apple_health",  "applelogo"),
        ("Fitbit",       "fitbit",        "fitbit"),
        ("Withings",     "withings",      "withings"),
        ("Omron",        "omron",         "omron"),
        ("Garmin",       "garmin",        "garmin")
    ]

    private var connectedDevices: [(name: String, key: String, icon: String)] {
        knownDevices.filter { isConnected(sourceKey: $0.key) }
    }
    private var notConnectedDevices: [(name: String, key: String, icon: String)] {
        knownDevices.filter { !isConnected(sourceKey: $0.key) }
    }
    private var canOpenMarketplace: Bool {
        guard let url = store.marketplaceURL else { return false }
        return !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBanner
                cardsSection
            }
            .padding(.bottom, 40)
        }
        .background(Color(hex: "#F0F4F1"))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.configureIfNeeded()
            guard !didBootstrap else { return }
            didBootstrap = true
            Task {
                // If we have a uid, refresh sources to show latest connection status
                if store.validicUID != nil {
                    await store.refreshSourcesIfAvailable()
                }
            }
        }
        .fullScreenCover(isPresented: $showMarketplace) {
            if let url = marketplaceURL {
                MarketplaceView(url: url)
            } else {
                // Safety fallback — should never happen
                VStack(spacing: 16) {
                    Text("Marketplace URL not available.")
                        .foregroundColor(AppColor.grey)
                    Button("Close") { showMarketplace = false }
                        .foregroundColor(AppColor.green)
                }
            }
        }
        .alert(isPresented: Binding(
            get:  { store.errorMessage != nil },
            set:  { if !$0 { store.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Sync Devices"),
                message: Text(store.errorMessage ?? ""),
                dismissButton: .cancel(Text("OK")) { store.errorMessage = nil }
            )
        }
    }

    // MARK: - Top Banner

    private var topBanner: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(hex: "#DCE6DF"), Color(hex: "#BFD5C2")],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 270)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(spacing: 16) {
                // Nav row
                HStack {
                    Button { presentationMode.wrappedValue.dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColor.color414141)
                    }
                    Text("Sync Devices")
                        .font(AppFont.display(size: 22, weight: .semibold))
                        .foregroundColor(AppColor.color414141)
                    Spacer()
                    Button { openMarketplaceIfAvailable() } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 30, weight: .regular))
                            .foregroundColor(AppColor.color414141)
                    }
                    .disabled(!canOpenMarketplace)
                }

                // Pull-to-refresh hint
                VStack(spacing: 10) {
                    Text("Swipe Down to Refresh")
                        .font(AppFont.display(size: 18, weight: .bold))
                        .foregroundColor(AppColor.black)

                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Image(systemName: "arrow.down")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppColor.color414141)
                        )
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Cards Section

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Pull-tab handle
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.10))
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            // ACTION REQUIRED banner — shown when no sources connected yet
            if connectedDevices.isEmpty && canOpenMarketplace {
                connectHintCard
            }

            // Not-connected devices
            if !notConnectedDevices.isEmpty {
                VStack(spacing: 10) {
                    ForEach(notConnectedDevices, id: \.key) { item in
                        deviceRow(name: item.name, key: item.key, icon: item.icon, isConnected: false)
                    }
                }
            }

            // Connected devices — shown in their own section
            if !connectedDevices.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Connected Device")
                        .font(AppFont.body(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.grey)
                        .padding(.leading, 4)
                        .padding(.top, 4)

                    ForEach(connectedDevices, id: \.key) { item in
                        deviceRow(name: item.name, key: item.key, icon: item.icon, isConnected: true)
                    }
                }
            }

            // Manage your devices
            Button { openMarketplaceIfAvailable() } label: {
                Text("Manage your devices")
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(canOpenMarketplace ? AppColor.green : AppColor.green.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!canOpenMarketplace)

            // Sync with Apple Health
            Button { Task { await syncNow() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(AppColor.black)
                    Text(store.isSyncing ? "Syncing…" : "Sync with Apple Health")
                        .font(AppFont.body(size: 18, weight: .semibold))
                        .foregroundColor(AppColor.color414141)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColor.color414141, lineWidth: 1.5)
                )
            }
            .disabled(store.isSyncing || !store.isReadyForInitialSync)

            // Refresh status
            Button { Task { await store.refreshSourcesIfAvailable() } } label: {
                Text(store.isRefreshing ? "Refreshing…" : "Refresh device status")
                    .font(AppFont.body(size: 15, weight: .medium))
                    .foregroundColor(AppColor.grey)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppColor.grey.opacity(0.35), lineWidth: 1.2)
                    )
            }
            .disabled(store.isRefreshing || store.validicUID == nil)

            // Last sync label
            Text(lastSyncText)
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundColor(AppColor.grey)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(hex: "#F4F4F4"))
        )
        .offset(y: -22)
    }

    // MARK: - Device Row

    private func deviceRow(name: String, key: String, icon: String, isConnected: Bool) -> some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 52, height: 52)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                // Use system image for Apple, otherwise show initials
                if key == "apple_health" {
                    Image(systemName: "applelogo")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                } else if UIImage(named: icon) != nil {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                } else {
                    Text(initials(from: name))
                        .font(AppFont.body(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.grey)
                }

                // Connection dot
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(isConnected ? Color.green : Color.red)
                            .frame(width: 13, height: 13)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
                .frame(width: 52, height: 52)
            }

            Text(name)
                .font(AppFont.display(size: 16, weight: .medium))
                .foregroundColor(AppColor.color414141)
                .lineLimit(1)

            Spacer()

            if isConnected {
                Text("Connected")
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppColor.green.opacity(0.10))
                    .clipShape(Capsule())
            } else {
                Button("Manage") { openMarketplaceIfAvailable() }
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.green)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .overlay(Capsule().stroke(AppColor.green, lineWidth: 1.3))
                    .disabled(!canOpenMarketplace)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Connect Hint

    private var connectHintCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppColor.green)
                Text("Action Required")
                    .font(AppFont.body(size: 15, weight: .bold))
                    .foregroundColor(AppColor.color414141)
            }

            Text("Apple Health is not connected yet. You need to connect it once through the Validic marketplace so your health data can sync.")
                .font(AppFont.body(size: 13, weight: .regular))
                .foregroundColor(AppColor.grey)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                connectAppleHealthAndOpenMarketplace()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 16))
                    Text("Connect Apple Health Now")
                        .font(AppFont.body(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColor.green)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.green.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColor.green.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Helpers

    private var lastSyncText: String {
        guard let date = store.lastSyncedAt else { return "Not synced yet" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return "Last sync: \(f.string(from: date))"
    }

    private func isConnected(sourceKey: String) -> Bool {
        store.sourceTypes.contains { $0.lowercased().contains(sourceKey.lowercased()) }
    }

    /// Opens the marketplace URL as a full-screen in-app view.
    private func openMarketplaceIfAvailable() {
        guard let urlString = store.marketplaceURL else {
            print("⚠️ [Marketplace] marketplaceURL is nil — triggering sync first")
            Task { await syncNow() }
            return
        }
        guard let url = URL(string: urlString) else {
            print("❌ [Marketplace] Invalid URL string: \(urlString)")
            return
        }
        print("🌐 [Marketplace] Opening URL: \(url.absoluteString)")
        print("🔑 [Marketplace] Token present: \(url.absoluteString.contains("token="))")
        marketplaceURL = url
        showMarketplace = true
    }

    /// Requests HealthKit read permissions first, then opens the marketplace URL full-screen in-app.
    private func connectAppleHealthAndOpenMarketplace() {
        guard let urlString = store.marketplaceURL, let url = URL(string: urlString) else {
            Task { await syncNow() }
            return
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            marketplaceURL = url
            showMarketplace = true
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]

        HKHealthStore().requestAuthorization(toShare: nil, read: readTypes) { _, _ in
            DispatchQueue.main.async {
                marketplaceURL = url
                showMarketplace = true
            }
        }
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
           !decoded.isEmpty { return username }
        return Data(username.utf8).base64EncodedString()
    }

    private func initials(from text: String) -> String {
        text.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
    }
}

// MARK: - HealthSyncStore

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
        guard let viewModel else { errorMessage = "Device sync is not configured."; return }
        isSyncing = true
        await viewModel.sync(encodedUsername: encodedUsername, deviceId: deviceId)
        isSyncing = false
        apply(from: viewModel)
        refreshReadiness()
        if case .failure(let message) = viewModel.state { errorMessage = message }
    }

    func refreshSourcesIfAvailable() async {
        guard let viewModel else { errorMessage = "Device sync is not configured."; return }
        isRefreshing = true
        await viewModel.refreshSources()
        isRefreshing = false
        apply(from: viewModel)
        refreshReadiness()
        if case .failure(let message) = viewModel.state { errorMessage = message }
    }

    func syncFromCachedSession() async {
        guard let viewModel else { errorMessage = "Device sync is not configured."; return }
        isSyncing = true
        await viewModel.syncFromCachedSession()
        isSyncing = false
        apply(from: viewModel)
        refreshReadiness()
        if case .failure(let message) = viewModel.state { errorMessage = message }
    }

    private func apply(from viewModel: HealthSyncViewModel) {
        marketplaceURL = viewModel.marketplaceURL
        sourceTypes    = viewModel.sourceTypes
        lastSyncedAt   = viewModel.lastSyncedAt
        validicUserID  = viewModel.validicUserID
        validicUID     = viewModel.validicUID
        timezone       = viewModel.timezone
        userStatus     = viewModel.userStatus
    }

    private func refreshReadiness() {
        let token    = UserDefaults.standard.string(forKey: "Apollo360.accessToken")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let username = UserDefaults.standard.string(forKey: "Apollo360.username")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        isReadyForInitialSync = !token.isEmpty && (!username.isEmpty || validicUID != nil)
    }
}

// MARK: - Marketplace Full-Screen View

private struct MarketplaceView: View {
    let url: URL
    @Environment(\.presentationMode) private var presentationMode
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        NavigationView {
            ZStack {
                MarketplaceWebView(url: url, isLoading: $isLoading, loadError: $loadError)
                    .ignoresSafeArea(edges: .bottom)

                if isLoading {
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.3)
                        Text("Loading marketplace…")
                            .font(AppFont.body(size: 14))
                            .foregroundColor(AppColor.grey)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                }

                if let error = loadError {
                    VStack(spacing: 14) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(AppColor.grey)
                        Text(error)
                            .font(AppFont.body(size: 14))
                            .foregroundColor(AppColor.grey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Manage Devices")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Close")
                                .font(AppFont.body(size: 15, weight: .semibold))
                        }
                        .foregroundColor(AppColor.green)
                    }
                }
            }
        }
        .onAppear {
            print("🌐 [MarketplaceView] Loading: \(url.absoluteString)")
            print("🔑 [MarketplaceView] Has token: \(url.absoluteString.contains("token="))")
        }
    }
}

private struct MarketplaceWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MarketplaceWebView

        init(_ parent: MarketplaceWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.loadError = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            print("✅ [MarketplaceWebView] Page loaded: \(webView.url?.absoluteString ?? "unknown")")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
            print("❌ [MarketplaceWebView] Load failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
            print("❌ [MarketplaceWebView] Provisional load failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Color helper

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

#Preview {
    DeviceSyncView(session: SessionManager())
}
