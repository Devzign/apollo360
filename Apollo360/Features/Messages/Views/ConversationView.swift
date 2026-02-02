//
//  ConversationView.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import SwiftUI

struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel
    let provider: MessageProvider
    @Environment(\.dismiss) private var dismiss

    init(session: SessionManager, service: MessageAPIService, provider: MessageProvider) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(session: session, service: service))
        self.provider = provider
    }
    
    init(session: SessionManager, provider: MessageProvider) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(session: session, service: .shared))
        self.provider = provider
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.02).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if viewModel.isLoading {
                    ProgressView().padding()
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red).padding()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message, isMine: isMine(message))
                                        .id(message.id)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                        }
                        .onChange(of: viewModel.messages.count) { oldValue, newValue in
                            guard newValue != oldValue else { return }
                            if let lastId = viewModel.messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                inputBar
                    .padding()
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadConversation(providerMemberId: provider.memberId)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.black)
            }

            AvatarView(urlString: provider.avatarURL, placeholderText: provider.name)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name)
                    .font(AppFont.body(size: 16, weight: .semibold))
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColor.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(AppFont.body(size: 12))
                        .foregroundStyle(AppColor.grey)
                }
            }
            Spacer()
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func isMine(_ message: MessageEntry) -> Bool {
        message.name == (viewModel.thread?.patientName ?? "You") || message.name == (viewModel.thread?.patientName ?? "")
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Type your message...", text: $viewModel.pendingMessageText, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button(action: viewModel.sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(AppColor.green)
                    .clipShape(Circle())
            }
        }
    }
}

private struct MessageBubble: View {
    let message: MessageEntry
    let isMine: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(message.message)
                    .font(AppFont.body(size: 15))
                    .foregroundStyle(isMine ? .white : AppColor.black)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(formattedTime)
                        .font(AppFont.body(size: 11))
                }
                .foregroundStyle(isMine ? Color.white.opacity(0.8) : AppColor.grey)
            }
            .padding(12)
            .background(isMine ? AppColor.green : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(isMine ? 0.08 : 0.04), radius: 6, y: 2)

            if !isMine {
                AvatarView(urlString: nil, placeholderText: message.name)
                    .frame(width: 32, height: 32)
            }
        }
    }

    private var formattedTime: String {
        guard let date = message.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct AvatarView: View {
    let urlString: String?
    let placeholderText: String

    var body: some View {
        let bg = AppColor.green.opacity(0.15)
        ZStack {
            Circle().fill(bg)
            if let urlString,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Text(initials)
                            .font(AppFont.body(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.green)
                    }
                }
            } else {
                Text(initials)
                    .font(AppFont.body(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.green)
            }
        }
        .clipShape(Circle())
    }

    private var initials: String {
        let comps = placeholderText.split(separator: " ")
        let letters = comps.prefix(2).compactMap { $0.first }
        return letters.map(String.init).joined().uppercased()
    }
}
