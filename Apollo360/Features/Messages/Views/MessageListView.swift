//
//  MessageListView.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import SwiftUI
import Combine
import UIKit

struct MessageListView: View {
    @StateObject private var viewModel: MessagesListViewModel
    @State private var searchText: String = ""
    @State private var selectedProvider: MessageProvider?
    private let session: SessionManager

    private var filteredProviders: [MessageProvider] {
        guard !searchText.isEmpty else { return viewModel.providers }
        return viewModel.providers.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    init(session: SessionManager) {
        self.session = session
        _viewModel = StateObject(wrappedValue: MessagesListViewModel(session: session))
    }

    var body: some View {
            VStack(spacing: 0) {
                searchBar
                if viewModel.isLoading {
                    ProgressView().padding()
                }
                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red).padding()
                }
                List {
                    ForEach(filteredProviders) { provider in
                        Button {
                            selectedProvider = provider
                        } label: {
                            ProviderRow(provider: provider)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
 
            .navigationBarHidden(true)
            .onAppear { viewModel.loadProviders() }
            .fullScreenCover(item: $selectedProvider) { provider in
                ConversationView(session: session, provider: provider)
            }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
            Button {
                searchText = ""
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(AppColor.green)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

private struct ProviderRow: View {
    let provider: MessageProvider

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(urlString: provider.avatarURL, placeholderText: provider.name)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.black)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColor.grey.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        )
    }
}

// Reusable avatar
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
