//
//  MessagesView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct MessagesView: View {
    private let threads: [MessageThread] = MessageThread.sampleThreads
    @State private var searchText = ""

    private var filteredThreads: [MessageThread] {
        guard !searchText.isEmpty else { return threads }
        return threads.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            AppColor.colorECF0F3
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    searchBar
                    messageList
                }
                .padding(.horizontal, 18)
                .padding(.top, 28)
                .padding(.bottom, 100)
            }
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "line.horizontal.3.decrease")
                .foregroundStyle(AppColor.green)
                .font(.system(size: 20, weight: .semibold))

            Spacer()

            Text("Messages")
                .font(AppFont.display(size: 22, weight: .semibold))
                .foregroundStyle(AppColor.black)

            Spacer()

            Image(systemName: "square.grid.2x2")
                .foregroundStyle(.secondary)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal, 6)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search conversations", text: $searchText)
                .font(AppFont.body(size: 14))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(AppColor.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColor.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
        .padding(.vertical, 18)
    }

    private var messageList: some View {
        VStack(spacing: 16) {
            if filteredThreads.isEmpty {
                Text("No conversations yet.")
                    .font(AppFont.body(size: 14))
                    .foregroundStyle(AppColor.grey)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(filteredThreads) { thread in
                    MessageRow(thread: thread)
                }
            }
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColor.white.opacity(0.8))
                    .frame(height: 82)
                    .overlay(
                        HStack {
                            Circle()
                                .fill(AppColor.secondary.opacity(0.5))
                                .frame(width: 58, height: 58)
                            VStack(alignment: .leading, spacing: 12) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColor.secondary.opacity(0.4))
                                    .frame(width: 140, height: 14)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColor.secondary.opacity(0.3))
                                    .frame(width: 200, height: 12)
                            }
                            Spacer()
                        }
                        .padding()
                    )
            }
        }
        .padding(.vertical, 12)
    }

    private func errorState(_ message: String) -> some View {
        Text(message)
            .font(AppFont.body(size: 14))
            .foregroundStyle(AppColor.red)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 40)
    }
}

private struct MessageRow: View {
    let thread: MessageThread

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            AvatarView(url: thread.avatarURL)
            VStack(alignment: .leading, spacing: 6) {
                Text(thread.name)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.black)
                Text(thread.detail)
                    .font(AppFont.body(size: 13))
                    .foregroundStyle(AppColor.grey)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(thread.timeAgo)
                    .font(AppFont.body(size: 12))
                    .foregroundStyle(.secondary)

                if let count = thread.unreadCount {
                    Text("\(count)")
                        .font(AppFont.body(size: 12, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(AppColor.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColor.white)
                .shadow(color: Color.black.opacity(0.02), radius: 12, x: 0, y: 6)
        )
    }
}

private struct AvatarView: View {
    let url: URL?

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [AppColor.secondary, AppColor.green],
                    startPoint: .top,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 64, height: 64)

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 58, height: 58)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(AppColor.white.opacity(0.3))
                            .frame(width: 58, height: 58)
                    }
                }
            } else {
                Circle()
                    .fill(AppColor.white.opacity(0.2))
                    .frame(width: 58, height: 58)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MessagesView()
    }
}
