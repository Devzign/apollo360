//
//  Apollo360App.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

@main
struct Apollo360App: App {
    @StateObject private var session = SessionManager()

    init() {
        FontRegistrar.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isAuthenticated {
                    DashboardView(session: session)
                } else {
                    LoginView()
                }
            }
            .environmentObject(session)
            .preferredColorScheme(.light)
        }
    }
}
