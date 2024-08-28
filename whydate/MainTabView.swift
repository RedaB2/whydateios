import SwiftUI

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        TabView {
            HomeView(isUserLoggedIn: $isUserLoggedIn)
                .tabItem {
                    Image(systemName: "homeicon")
                    Text("Home")
                }

            MessageView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Messages")
                }

            SettingsView()
                .tabItem {
                   Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
    }
}
