//
//  MessageListView.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import SwiftUI

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
                    Text(error).foregroundStyle(.red).padding()
                }
                List {
                    ForEach(filteredProviders) { provider in
                        Button {
                            selectedProvider = provider
                        } label: {
                            ProviderRow(provider: provider)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
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
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.grey.opacity(0.7))
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
