import SwiftUI
import UserNotifications

struct NotificationPermission: View {
    let onContinue: () -> Void

    var body: some View {
        // This step triggers the system notification permission dialog
        // then auto-advances
        Color.black
            .ignoresSafeArea()
            .onAppear {
                requestPermission()
            }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in
            DispatchQueue.main.async {
                onContinue()
            }
        }
    }
}
