import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @Binding var isUserLoggedIn: Bool
    @Binding var isEmailVerified: Bool
    @State private var showSplash: Bool = true // Tracks splash screen visibility
    
    var body: some View {
        ZStack {
            // Main Content: Loaded in the background
            NavigationStack {
                if isUserLoggedIn && isEmailVerified {
                    HomeView(isUserLoggedIn: $isUserLoggedIn)
                } else {
                    WelcomeView(isUserLoggedIn: $isUserLoggedIn)
                }
            }
            .opacity(showSplash ? 0 : 1) // Hide main content while splash is visible
            
            // Splash Screen: Overlaid on top
            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Start a 1-second timer to hide the splash screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    self.showSplash = false
                }
            }
        }
    }
}
