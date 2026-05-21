//
//  ConversationView.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
import WebKit

struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel
    let provider: MessageProvider
    let session: SessionManager
    @Environment(\.presentationMode) private var presentationMode
    @State private var isFileImporterPresented = false
    @State private var previewURL: URL?

    init(session: SessionManager, service: MessageAPIService, provider: MessageProvider) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(session: session, service: service))
        self.provider = provider
        self.session = session
    }

    init(session: SessionManager, provider: MessageProvider) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(session: session, service: .shared))
        self.provider = provider
        self.session = session
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.02).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView().padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error).foregroundColor(.red).padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        isMine: isMine(message),
                                        senderName: isMine(message) ? nil : provider.name,
                                        onOpenFile: { url in
                                            previewURL = url
                                        }
                                    )
                                        .id(message.id)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            if let lastId = viewModel.messages.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let lastId = viewModel.messages.last?.id {
                                    withAnimation {
                                        proxy.scrollTo(lastId, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                inputBar
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .sheet(
            isPresented: Binding(
                get: { previewURL != nil },
                set: { isPresented in
                    if !isPresented {
                        previewURL = nil
                    }
                }
            )
        ) {
            if let url = previewURL {
                NavigationView {
                    AttachmentPreviewView(url: url)
                }
            }
        }
        .onAppear {
            viewModel.loadConversation(providerMemberId: provider.memberId)
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let first = urls.first {
                    viewModel.attachFile(from: first)
                }
            case .failure:
                viewModel.errorMessage = "Unable to select file."
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColor.black)
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
                        .foregroundColor(AppColor.grey)
                }
            }
            Spacer()
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColor.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func isMine(_ message: MessageEntry) -> Bool {
        message.messageType == 0
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            if let selectedAttachment = viewModel.selectedAttachmentName {
                HStack(spacing: 8) {
                    Image(systemName: "doc.fill")
                        .foregroundColor(AppColor.green)
                    Text(selectedAttachment)
                        .font(AppFont.body(size: 12, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    Button {
                        viewModel.clearAttachment()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColor.grey)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 10) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColor.green)
                }

                TextField("Type your message...", text: $viewModel.pendingMessageText)
                    .padding(12)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button(action: viewModel.sendMessage) {
                    Image(systemName: viewModel.isSending ? "hourglass" : "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(AppColor.green)
                        .clipShape(Circle())
                }
                .disabled(viewModel.isSending)
            }
        }
    }
}

private struct MessageBubble: View {
    let message: MessageEntry
    let isMine: Bool
    let senderName: String?
    let onOpenFile: (URL) -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine {
                // My message: spacer on left pushes bubble to right
                Spacer(minLength: 48)
            } else {
                // Provider message: avatar on LEFT (WhatsApp style)
                AvatarView(urlString: nil, placeholderText: senderName ?? message.name)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 6) {
                if !isMine {
                    Text(senderName ?? message.name)
                        .font(AppFont.body(size: 11, weight: .semibold))
                        .foregroundColor(AppColor.green)
                }

                Text(message.message)
                    .font(AppFont.body(size: 15))
                    .foregroundColor(isMine ? .white : AppColor.black)

                if let filePath = message.filePath,
                   !filePath.isEmpty {
                    fileView(filePath: filePath)
                }

                HStack(spacing: 4) {
                    Text(formattedTime)
                        .font(AppFont.body(size: 11))
                    if isMine {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                    }
                }
                .foregroundColor(isMine ? Color.white.opacity(0.75) : AppColor.grey)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isMine
                    ? AppColor.green
                    : Color.white
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isMine ? Color.clear : Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isMine ? 0.12 : 0.05), radius: 4, y: 2)

            if !isMine {
                // Provider message: spacer on right keeps bubble left-aligned
                Spacer(minLength: 48)
            }
        }
    }

    @ViewBuilder
    private func fileView(filePath: String) -> some View {
        if let url = URL(string: filePath), url.scheme != nil {
            Button {
                onOpenFile(url)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "paperclip")
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                }
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundColor(isMine ? .white : AppColor.green)
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "paperclip")
                Text(filePath)
                    .lineLimit(1)
            }
            .font(AppFont.body(size: 12, weight: .medium))
            .foregroundColor(isMine ? .white : AppColor.green)
        }
    }

    private var formattedTime: String {
        guard let date = message.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct AttachmentPreviewView: View {
    let url: URL

    var body: some View {
        VStack(spacing: 0) {
            WebContentView(url: url)
                .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle("File Preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WebContentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.alwaysBounceVertical = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
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
                RemoteCircleAvatar(url: url) {
                    Text(initials)
                        .font(AppFont.body(size: 14, weight: .bold))
                        .foregroundColor(AppColor.green)
                }
            } else {
                Text(initials)
                    .font(AppFont.body(size: 14, weight: .bold))
                    .foregroundColor(AppColor.green)
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

private struct RemoteCircleAvatar<Placeholder: View>: View {
    @StateObject private var loader: RemoteImageLoader
    let placeholder: Placeholder

    init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
        _loader = StateObject(wrappedValue: RemoteImageLoader(url: url))
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .onAppear {
            loader.load()
        }
    }
}

private final class RemoteImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let url: URL
    private var hasLoaded = false

    init(url: URL) {
        self.url = url
    }

    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.image = image
            }
        }.resume()
    }
}
