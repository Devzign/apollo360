import SwiftUI
import HealthKit
import WebKit
import Combine

private struct MarketplaceItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct DeviceSyncView: View {
    @Environment(\.presentationMode) private var presentationMode
    let session: SessionManager

    @StateObject private var store = HealthSyncStore()
    @StateObject private var hkData = HealthKitDataStore()
    @State private var marketplaceItem: MarketplaceItem?
    @State private var didBootstrap = false
    @State private var healthKitAuthorized = false

    private let knownDevices: [(name: String, key: String, icon: String)] = [
        ("Apple Health", "apple_health", "applelogo"),
        ("Fitbit",       "fitbit",       "fitbit"),
        ("Withings",     "withings",     "withings"),
        ("Omron",        "omron",        "omron"),
        ("Garmin",       "garmin",       "garmin")
    ]

    private var connectedDevices: [(name: String, key: String, icon: String)] {
        knownDevices.filter { isConnectedDevice(key: $0.key) }
    }
    private var notConnectedDevices: [(name: String, key: String, icon: String)] {
        knownDevices.filter { !isConnectedDevice(key: $0.key) }
    }

    private func isConnectedDevice(key: String) -> Bool {
        if key == "apple_health" { return healthKitAuthorized }
        return store.sourceTypes.contains { $0.lowercased().contains(key.lowercased()) }
    }

    private var canOpenMarketplace: Bool {
        guard let url = store.marketplaceURL else { return false }
        return !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBanner
                cardsSection
            }
            .padding(.bottom, 40)
        }
        .refreshable {
            guard !store.isSyncing else { return }
            await syncNow()
        }
        .background(Color(hex: "#F0F4F1"))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.configureIfNeeded()
            checkHealthKitAuthorization()
            guard !didBootstrap else { return }
            didBootstrap = true
            Task { await syncNow() }
        }
        .fullScreenCover(item: $marketplaceItem) { item in
            MarketplaceView(url: item.url)
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
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.10))
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            if !notConnectedDevices.isEmpty {
                VStack(spacing: 10) {
                    ForEach(notConnectedDevices, id: \.key) { item in
                        deviceRow(name: item.name, key: item.key, icon: item.icon, isConnected: false)
                    }
                }
            }

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
            Button {
                if healthKitAuthorized {
                    Task { await syncNow() }
                } else {
                    requestHealthKitPermission()
                }
            } label: {
                HStack(spacing: 10) {
                    if store.isSyncing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColor.color414141))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "applelogo")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(AppColor.black)
                    }
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
            .disabled(store.isSyncing)

            // Refresh device status
            Button {
                Task {
                    guard !store.isSyncing && !store.isRefreshing else { return }
                    if let uid = store.validicUID ?? store.validicUID, !uid.isEmpty {
                        await store.refreshSourcesIfAvailable(fallbackUID: uid)
                        await hkData.fetch()
                    } else {
                        await syncNow()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if store.isRefreshing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColor.grey))
                            .scaleEffect(0.75)
                    }
                    Text(store.isRefreshing ? "Refreshing…" : "Refresh device status")
                        .font(AppFont.body(size: 15, weight: .medium))
                        .foregroundColor(AppColor.grey)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColor.grey.opacity(0.35), lineWidth: 1.2)
                )
            }
            .disabled(store.isRefreshing || store.isSyncing)

            Text(lastSyncText)
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundColor(AppColor.grey)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)

            // Health Data Section — always show once HK permission granted
            if healthKitAuthorized {
                healthDataSection
            }
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
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 52, height: 52)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

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
            } else if key == "apple_health" {
                Button(healthKitAuthorized ? "Manage" : "Grant Access") {
                    if healthKitAuthorized {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        requestHealthKitPermission()
                    }
                }
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundColor(AppColor.green)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .overlay(Capsule().stroke(AppColor.green, lineWidth: 1.3))
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

    // MARK: - Health Data Section

    private var healthDataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(AppColor.green)
                    .font(.system(size: 16, weight: .semibold))
                Text("Today's Health Data")
                    .font(AppFont.body(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.color414141)
                Spacer()
                if hkData.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColor.green))
                        .scaleEffect(0.8)
                } else {
                    Button {
                        Task { await hkData.fetch() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColor.grey)
                    }
                }
            }
            .padding(.top, 8)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                hkCard(
                    icon: "figure.walk",
                    iconColor: AppColor.green,
                    bg: Color(hex: "#EAF4EC"),
                    title: "Steps",
                    value: hkData.steps.map { "\(Int($0))" } ?? "–",
                    unit: "steps today"
                )
                hkCard(
                    icon: "heart.fill",
                    iconColor: .red,
                    bg: Color(hex: "#FDECEA"),
                    title: "Heart Rate",
                    value: hkData.heartRate.map { "\(Int($0))" } ?? "–",
                    unit: "bpm"
                )
                hkCard(
                    icon: "flame.fill",
                    iconColor: .orange,
                    bg: Color(hex: "#FFF3E8"),
                    title: "Active Energy",
                    value: hkData.activeEnergy.map { String(format: "%.0f", $0) } ?? "–",
                    unit: "kcal"
                )
                hkCard(
                    icon: "figure.run",
                    iconColor: Color(hex: "#2B7BE5"),
                    bg: Color(hex: "#EAF0FB"),
                    title: "Distance",
                    value: hkData.distance.map { String(format: "%.2f", $0 / 1000) } ?? "–",
                    unit: "km"
                )
                hkCard(
                    icon: "lungs.fill",
                    iconColor: Color(hex: "#5B8DEF"),
                    bg: Color(hex: "#EBF3FF"),
                    title: "Blood O₂",
                    value: hkData.oxygenSaturation.map { String(format: "%.0f", $0 * 100) } ?? "–",
                    unit: "%"
                )
                hkCard(
                    icon: "drop.fill",
                    iconColor: Color(hex: "#E85D75"),
                    bg: Color(hex: "#FDEEF2"),
                    title: "Blood Glucose",
                    value: hkData.bloodGlucose.map { String(format: "%.1f", $0) } ?? "–",
                    unit: "mg/dL"
                )
            }

            // Sleep row — full width
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "#EEE8FF"))
                        .frame(width: 46, height: 46)
                    Image(systemName: "moon.zzz.fill")
                        .foregroundColor(Color(hex: "#7C5CBF"))
                        .font(.system(size: 22, weight: .medium))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sleep")
                        .font(AppFont.body(size: 12, weight: .semibold))
                        .foregroundColor(AppColor.grey)
                    Text(hkData.sleepHours.map { String(format: "%.1f hrs", $0) } ?? "No data today")
                        .font(AppFont.display(size: 20, weight: .bold))
                        .foregroundColor(AppColor.color414141)
                }
                Spacer()
                Text("last night")
                    .font(AppFont.body(size: 12, weight: .regular))
                    .foregroundColor(AppColor.grey)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }

    private func hkCard(icon: String, iconColor: Color, bg: Color, title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(bg)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 16, weight: .medium))
                }
                Spacer()
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(AppFont.display(size: 22, weight: .bold))
                    .foregroundColor(AppColor.color414141)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(title)
                    .font(AppFont.body(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.grey)
                Text(unit)
                    .font(AppFont.body(size: 10, weight: .regular))
                    .foregroundColor(AppColor.grey.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helpers

    private var lastSyncText: String {
        guard let date = store.lastSyncedAt else { return "Not synced yet" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return "Last sync: \(f.string(from: date))"
    }

    private func openMarketplaceIfAvailable() {
        guard let urlString = store.marketplaceURL, !urlString.isEmpty else {
            Task { await syncNow() }
            return
        }
        guard let url = URL(string: urlString) else { return }
        marketplaceItem = MarketplaceItem(url: url)
    }

    private static let hkReadTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]

    /// HealthKit read authorization is opaque (privacy) — track via UserDefaults flag.
    private func checkHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        healthKitAuthorized = UserDefaults.standard.bool(forKey: "Apollo360.hkPermissionRequested")
        if healthKitAuthorized {
            Task { await hkData.fetch() }
        }
    }

    private func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        HKHealthStore().requestAuthorization(toShare: nil, read: Self.hkReadTypes) { _, _ in
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: "Apollo360.hkPermissionRequested")
                healthKitAuthorized = true
                Task { await hkData.fetch() }
            }
        }
    }

    private func syncNow() async {
        guard !store.isSyncing else { return }
        let encodedUsername = resolveEncodedUsername()
        if encodedUsername.isEmpty, store.validicUID != nil {
            await store.syncFromCachedSession()
        } else {
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "ios-device"
            await store.sync(encodedUsername: encodedUsername, deviceId: deviceId)
        }
        if healthKitAuthorized {
            await hkData.fetch()
        }
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

// MARK: - HealthKitDataStore

@MainActor
final class HealthKitDataStore: ObservableObject {
    @Published var steps: Double?
    @Published var heartRate: Double?
    @Published var activeEnergy: Double?
    @Published var distance: Double?
    @Published var oxygenSaturation: Double?
    @Published var bloodGlucose: Double?
    @Published var sleepHours: Double?
    @Published var isLoading = false

    private let hkStore = HKHealthStore()

    func fetch() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        isLoading = true
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        // Sleep: look back 24 h to catch last night
        let sleepStart = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? startOfDay

        async let s  = sum(.stepCount,               unit: .count(),                    from: startOfDay, to: now)
        async let hr = recent(.heartRate,             unit: .count().unitDivided(by: .minute()), from: startOfDay, to: now)
        async let ae = sum(.activeEnergyBurned,       unit: .kilocalorie(),              from: startOfDay, to: now)
        async let d  = sum(.distanceWalkingRunning,   unit: .meter(),                    from: startOfDay, to: now)
        async let o2 = recent(.oxygenSaturation,      unit: .percent(),                  from: startOfDay, to: now)
        async let bg = recent(.bloodGlucose,          unit: HKUnit(from: "mg/dL"),       from: startOfDay, to: now)
        async let sl = sleep(from: sleepStart,        to: now)

        steps            = await s
        heartRate        = await hr
        activeEnergy     = await ae
        distance         = await d
        oxygenSaturation = await o2
        bloodGlucose     = await bg
        sleepHours       = await sl
        isLoading = false
    }

    private func sum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, from start: Date, to end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { cont in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            hkStore.execute(q)
        }
    }

    private func recent(_ id: HKQuantityTypeIdentifier, unit: HKUnit, from start: Date, to end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { cont in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let val = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                cont.resume(returning: val)
            }
            hkStore.execute(q)
        }
    }

    private func sleep(from start: Date, to end: Date) async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        return await withCheckedContinuation { cont in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let total = samples?
                    .compactMap { $0 as? HKCategorySample }
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0
                cont.resume(returning: total > 0 ? total / 3600 : nil)
            }
            hkStore.execute(q)
        }
    }
}

// MARK: - HealthSyncStore

@MainActor
final class HealthSyncStore: ObservableObject {
    @Published var isSyncing = false
    @Published var isRefreshing = false
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
        if case .failure(let msg) = viewModel.state { errorMessage = msg }
    }

    func refreshSourcesIfAvailable(fallbackUID: String? = nil) async {
        guard let viewModel else { return }
        isRefreshing = true
        // Use fallbackUID (store's cached uid) if viewModel uid is nil
        let uid = viewModel.validicUID ?? fallbackUID
        await viewModel.refreshSources(uidToken: uid)
        isRefreshing = false
        apply(from: viewModel)
        if case .failure(let msg) = viewModel.state { errorMessage = msg }
    }

    func syncFromCachedSession() async {
        guard let viewModel else { return }
        isSyncing = true
        await viewModel.syncFromCachedSession()
        isSyncing = false
        apply(from: viewModel)
        if case .failure(let msg) = viewModel.state { errorMessage = msg }
    }

    private func apply(from vm: HealthSyncViewModel) {
        marketplaceURL = vm.marketplaceURL
        sourceTypes    = vm.sourceTypes
        lastSyncedAt   = vm.lastSyncedAt
        validicUserID  = vm.validicUserID
        validicUID     = vm.validicUID
        timezone       = vm.timezone
        userStatus     = vm.userStatus
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
                    Button { presentationMode.wrappedValue.dismiss() } label: {
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
    }
}

private struct MarketplaceWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        let webView = WKWebView(frame: .zero, configuration: config)
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
            parent.isLoading = true; parent.loadError = nil
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false; parent.loadError = error.localizedDescription
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false; parent.loadError = error.localizedDescription
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
