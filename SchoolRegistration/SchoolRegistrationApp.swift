import SwiftUI

@main
struct SchoolRegistrationApp: App {
    @StateObject private var session = SessionStore()
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var repo = DataRepository.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(localization)
                .environmentObject(repo)
                .environment(\.layoutDirection, localization.layoutDirection)
                .preferredColorScheme(.light)
        }
    }
}
