import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct whydateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var isUserLoggedIn: Bool = false
    @State private var isEmailVerified: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(isUserLoggedIn: $isUserLoggedIn, isEmailVerified: $isEmailVerified)
                .onAppear {
                    checkLoginStatus()
                }
        }
    }
    
    private func checkLoginStatus() {
        if let user = Auth.auth().currentUser {
            // User is logged in, now check if the email is verified
            isUserLoggedIn = true
            isEmailVerified = user.isEmailVerified
        } else {
            // User is not logged in
            isUserLoggedIn = false
            isEmailVerified = false
        }
    }
}
