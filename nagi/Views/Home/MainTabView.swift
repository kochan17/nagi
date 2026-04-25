import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    #if DEBUG
    @StateObject private var studioRenderBudget = RenderBudget()
    #endif

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Today")
                }
                .tag(0)

            RelaxView()
                .tabItem {
                    Image(systemName: "drop.fill")
                    Text("Relax")
                }
                .tag(1)

            BreathView()
                .tabItem {
                    Image(systemName: "wind")
                    Text("Breath")
                }
                .tag(2)

            SleepView()
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text("Sleep")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)

            #if DEBUG
            StudioTab(renderBudget: studioRenderBudget)
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Studio")
                }
                .tag(99)
            #endif
        }
        .tint(.cyan)
    }
}
