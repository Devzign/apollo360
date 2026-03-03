//
//  ConversationViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import Foundation
import Combine
import UniformTypeIdentifiers

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published private(set) var thread: MessageThreadResponse?
    @Published private(set) var messages: [MessageEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingMessageText: String = ""
    @Published private(set) var selectedAttachmentName: String?
    @Published private(set) var isSending = false
    private let session: SessionManager
    private let service: MessageAPIService
    private var providerMemberId: Int?
    private var selectedAttachmentData: Data?
    private var selectedAttachmentMimeType: String?
    
    init(session: SessionManager,
         service: MessageAPIService) {
        self.session = session
        self.service = service
    }
    
    @MainActor
    static func make(session: SessionManager, service: MessageAPIService? = nil) -> ConversationViewModel {
        let resolvedService = service ?? MessageAPIService.shared
        return ConversationViewModel(session: session, service: resolvedService)
    }
    
    func loadConversation(providerMemberId: Int) {
        self.providerMemberId = providerMemberId
        
        guard let token = session.accessToken else {
            errorMessage = "Missing auth token."
            return
        }
        
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
        guard !isSending else { return }
        let text = pendingMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !text.isEmpty
        let hasAttachment = selectedAttachmentData != nil
        guard hasText || hasAttachment else { return }

        guard let providerMemberId = providerMemberId,
              let token = session.accessToken else {
            errorMessage = "Missing session details."
            return
        }
        
        let patientId = parseInt(session.patientId) ?? 36222
        let a360Id = parseInt(session.a360Id) ?? 626
        
        pendingMessageText = ""
        let attachmentData = selectedAttachmentData
        let attachmentName = selectedAttachmentName
        let attachmentMimeType = selectedAttachmentMimeType
        clearAttachment()
        isSending = true
        
        // Optimistic append
        let optimistic = MessageEntry(
            entryId: Int.random(in: 100_000...999_999),
            messageType: 1,
            name: session.username ?? "You",
            timestamp: Date(),
            message: hasText ? text : (attachmentName ?? "Attachment"),
            urgent: "0",
            topicId: nil,
            topicTitle: nil,
            isUnread: false,
            filePath: hasAttachment ? attachmentName : nil
        )
        messages.append(optimistic)
        
        service.sendMessage(
            patientId: patientId,
            a360hId: a360Id,
            providerMemberId: providerMemberId,
            messageType: 1,
            message: hasText ? text : "",
            urgent: 0,
            fileData: attachmentData,
            fileName: attachmentName,
            mimeType: attachmentMimeType,
            token: token
        ) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isSending = false
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

    func attachFile(from url: URL) {
        do {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            selectedAttachmentData = data
            selectedAttachmentName = url.lastPathComponent

            let ext = url.pathExtension
            if let type = UTType(filenameExtension: ext),
               let mimeType = type.preferredMIMEType {
                selectedAttachmentMimeType = mimeType
            } else {
                selectedAttachmentMimeType = "application/octet-stream"
            }
        } catch {
            errorMessage = "Unable to read selected file."
        }
    }

    func clearAttachment() {
        selectedAttachmentData = nil
        selectedAttachmentName = nil
        selectedAttachmentMimeType = nil
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
