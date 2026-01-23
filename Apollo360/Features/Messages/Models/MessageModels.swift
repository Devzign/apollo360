//
//  MessageModels.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import Foundation

struct MessageThread: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let timeAgo: String
    let unreadCount: Int?
    let avatarURL: URL?

    var hasUnread: Bool {
        (unreadCount ?? 0) > 0
    }
}

extension MessageThread {
    static let sampleThreads: [MessageThread] = [
        MessageThread(
            id: "1",
            name: "John Marks",
            detail: "Hope you are doing good!",
            timeAgo: "5 min",
            unreadCount: 2,
            avatarURL: URL(string: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1")
        ),
        MessageThread(
            id: "2",
            name: "Emma Williams",
            detail: "On track with your meds. Keep it up.",
            timeAgo: "12 min",
            unreadCount: 1,
            avatarURL: URL(string: "https://images.unsplash.com/photo-1544723795-3fb6469f5b39")
        ),
        MessageThread(
            id: "3",
            name: "Olivia Carter",
            detail: "Can we reschedule tomorrow's check-in?",
            timeAgo: "16 min",
            unreadCount: nil,
            avatarURL: URL(string: "https://images.unsplash.com/photo-1504593811423-6dd665756598")
        ),
        MessageThread(
            id: "4",
            name: "James Wilson",
            detail: "Thanks for the update. Chat soon!",
            timeAgo: "32 min",
            unreadCount: 3,
            avatarURL: URL(string: "https://images.unsplash.com/photo-1504593811423-6dd665756598")
        )
    ]
}
