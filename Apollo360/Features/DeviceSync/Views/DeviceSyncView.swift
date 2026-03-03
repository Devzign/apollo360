import SwiftUI

struct DeviceSyncView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DeviceSyncViewModel

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: DeviceSyncViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                actionButtons

                Text(viewModel.lastSyncText)
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundStyle(AppColor.grey)

                if viewModel.isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Loading device status...")
                            .font(AppFont.body(size: 14))
                            .foregroundStyle(AppColor.grey)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.devices) { row in
                        DeviceStatusRowView(row: row)
                    }
                }
            }
            .padding(20)
        }
        .background(AppColor.secondary)
        .navigationTitle("Sync Devices")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .font(AppFont.body(size: 14, weight: .medium))
            }
        }
        .task {
            viewModel.onAppear()
        }
        .alert("Sync Devices", isPresented: alertPresented) {
            Button("OK", role: .cancel) {
                viewModel.alertMessage = nil
            }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            buttonRow(title: "+ Device", systemImage: "plus.circle.fill", color: AppColor.primary) {
                viewModel.openMarketplace()
            }

            buttonRow(title: "Refresh", systemImage: "arrow.clockwise", color: AppColor.blue) {
                Task {
                    await viewModel.refreshDevices()
                }
            }

            buttonRow(title: "Manage your devices", systemImage: "slider.horizontal.3", color: AppColor.black) {
                viewModel.openMarketplace()
            }

            Button {
                Task {
                    await viewModel.syncWithAppleHealth()
                }
            } label: {
                HStack {
                    if viewModel.isSyncing {
                        ProgressView()
                            .tint(AppColor.white)
                    } else {
                        Image(systemName: "heart.text.square.fill")
                    }
                    Text("Sync with Apple Health")
                        .font(AppFont.body(size: 15, weight: .semibold))
                }
                .foregroundStyle(AppColor.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.isSyncing ? AppColor.grey : AppColor.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isSyncing)
        }
    }

    private func buttonRow(title: String,
                           systemImage: String,
                           color: Color,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                    .font(AppFont.body(size: 15, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(AppColor.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var alertPresented: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.alertMessage = nil
                }
            }
        )
    }
}

private struct DeviceStatusRowView: View {
    let row: SyncDeviceRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.type.iconName)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 28)
                .foregroundStyle(row.isConnected ? AppColor.green : AppColor.grey)

            VStack(alignment: .leading, spacing: 6) {
                Text(row.title)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.black)

                Text(row.subtitle)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundStyle(row.isConnected ? AppColor.green : AppColor.red)

                if let connectedAt = row.connectedAt {
                    Text("Connected: \(Self.rowDateFormatter.string(from: connectedAt))")
                        .font(AppFont.body(size: 12))
                        .foregroundStyle(AppColor.grey)
                }

                if let processedAt = row.lastProcessedAt {
                    Text("Last Processed: \(Self.rowDateFormatter.string(from: processedAt))")
                        .font(AppFont.body(size: 12))
                        .foregroundStyle(AppColor.grey)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private static let rowDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationStack {
        DeviceSyncView(session: SessionManager())
    }
}
