import SwiftUI

@main
struct NagiApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var storeKit: StoreKitManager

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        _storeKit = StateObject(wrappedValue: StoreKitManager(appState: state))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(storeKit)
                .preferredColorScheme(.dark)
                .task {
                    await storeKit.checkSubscriptionStatus()
                }
        }
    }
}
