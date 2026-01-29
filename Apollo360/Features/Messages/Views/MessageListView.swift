//
//  MessageListView.swift
//  Apollo360
//
//  Created by Codex on 29/01/26.
//

import SwiftUI

struct MessageListView: View {
    @StateObject private var viewModel: MessagesListViewModel
    @State private var searchText: String = ""
    @State private var selectedProvider: MessageProvider?

    private var filteredProviders: [MessageProvider] {
        guard !searchText.isEmpty else { return viewModel.providers }
        return viewModel.providers.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: MessagesListViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                searchBar
                if viewModel.isLoading {
                    ProgressView().padding()
                }
                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red).padding()
                }
                List {
                    ForEach(filteredProviders) { provider in
                        ProviderRow(provider: provider)
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarHidden(true)
            .onAppear { viewModel.loadProviders() }
        }
    }

    private var header: some View {
        HStack {
            Text("Messages")
                .font(AppFont.display(size: 22, weight: .bold))
            Spacer()
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
            Button {
                searchText = ""
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(AppColor.green)
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
                    .foregroundStyle(AppColor.black)
                Text("Hope you are doing good!")
                    .font(AppFont.body(size: 13))
                    .foregroundStyle(AppColor.grey)
            }
            Spacer()
            Text("5 mins")
                .font(AppFont.body(size: 12, weight: .medium))
                .foregroundStyle(AppColor.grey)
        }
        .padding(.vertical, 6)
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
