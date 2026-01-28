//
//  ConversationViewModel.swift
//  Apollo360
//
//  Created by Codex on 29/01/26.
//

import Foundation
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published private(set) var thread: MessageThreadResponse?
    @Published private(set) var messages: [MessageEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingMessageText: String = ""

    private let session: SessionManager
    private let service: MessageAPIService
    private var providerMemberId: Int?

    init(session: SessionManager,
         service: MessageAPIService = .shared) {
        self.session = session
        self.service = service
    }

    func loadConversation(providerMemberId: Int) {
        self.providerMemberId = providerMemberId

        guard let token = session.accessToken else {
            errorMessage = "Missing auth token."
            return
        }

        // Fallbacks prevent "nan" in URL if session strings are empty/malformed.
        let patientId = parseInt(session.patientId) ?? 36222
        let a360Id = parseInt(session.a360Id) ?? 626

        isLoading = true
        errorMessage = nil

        service.fetchMessages(
            patientId: patientId,
            a360hId: a360Id,
            providerMemberId: providerMemberId,
            token: token
        ) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let thread):
                    self.thread = thread
                    self.messages = thread.messages
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.thread = nil
                    self.messages = []
                }
            }
        }
    }

    func sendMessage() {
        guard !pendingMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let providerMemberId = providerMemberId,
              let token = session.accessToken else {
            errorMessage = "Missing session details."
            return
        }

        let patientId = parseInt(session.patientId) ?? 36222
        let a360Id = parseInt(session.a360Id) ?? 626

        let text = pendingMessageText
        pendingMessageText = ""

        // Optimistic append
        let optimistic = MessageEntry(
            entryId: Int.random(in: 100_000...999_999),
            messageType: 1,
            name: session.username ?? "You",
            timestamp: Date(),
            message: text,
            urgent: "0",
            topicId: nil,
            topicTitle: nil,
            isUnread: false,
            filePath: nil
        )
        messages.append(optimistic)

        service.sendMessage(
            patientId: patientId,
            a360hId: a360Id,
            providerMemberId: providerMemberId,
            messageType: 1,
            message: text,
            urgent: 0,
            fileData: nil,
            fileName: nil,
            mimeType: nil,
            token: token
        ) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // refresh to get canonical list
                    self.loadConversation(providerMemberId: providerMemberId)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Helpers
private extension ConversationViewModel {
    func parseInt(_ value: String?) -> Int? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              let intVal = Int(trimmed) else {
            return nil
        }
        return intVal
    }
}
