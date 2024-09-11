import SwiftUI
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permission
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        // Set Messaging delegate
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // This method is called when the app successfully registers for notifications
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Set APNs token for FCM
        Messaging.messaging().apnsToken = deviceToken
    }

    // Handle failure to register for notifications
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            // For iOS 14 and above, use .banner or .list
            completionHandler([.banner, .badge, .sound])
        } else {
            // Fallback for earlier iOS versions
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    // Handle background notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Add logic to navigate to specific screen in your app
        completionHandler()
    }
    
    // Messaging delegate method to handle FCM token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            print("FCM Token: \(fcmToken)")
            // Store the FCM token in Firestore for future use
            storeFCMTokenInFirestore(fcmToken: fcmToken)
        }
    }
    
    // Function to store the FCM token in Firestore
    private func storeFCMTokenInFirestore(fcmToken: String) {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userUID).setData(["fcmToken": fcmToken], merge: true) { error in
            if let error = error {
                print("Error storing FCM token in Firestore: \(error.localizedDescription)")
            } else {
                print("FCM token stored successfully!")
            }
        }
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
