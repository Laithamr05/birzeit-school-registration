import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            Group {
                switch session.current {
                case .none:
                    WelcomeView()
                case .parent:
                    ParentRootView()
                case .administrator:
                    AdminRootView()
                case .finance:
                    FinanceRootView()
                }
            }
            .animation(.easeInOut, value: session.role)
        }
        .environment(\.layoutDirection, loc.layoutDirection)
    }
}
