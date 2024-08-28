import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @Binding var isUserLoggedIn: Bool
    @Binding var isEmailVerified: Bool
    
    var body: some View {
        NavigationStack {
            if isUserLoggedIn && isEmailVerified {
                HomeView(isUserLoggedIn: $isUserLoggedIn)
            } else {
                WelcomeView(isUserLoggedIn: $isUserLoggedIn)
            }
        }
    }
}
