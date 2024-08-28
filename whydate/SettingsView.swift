import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct SettingsView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var navigateToWelcome = false
    @State private var showingAlert = false
    @State private var deleteInProgress = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .padding(.top, 20)
            
            Spacer()
            
            Button(action: {
                showingAlert = true
            }) {
                Text("Delete Account & Data")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Confirm Deletion"),
                    message: Text("Are you sure you want to delete your account and all associated data? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteAccount()
                    },
                    secondaryButton: .cancel()
                )
            }
            
            Button(action: {
                signOutUser()
            }) {
                Text("Logout")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            if deleteInProgress {
                ProgressView("Deleting account...")
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $navigateToWelcome) {
            WelcomeView(isUserLoggedIn: $isUserLoggedIn)
        }
    }
    
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        deleteInProgress = true
        
        let uid = user.uid
        let storage = Storage.storage()
        
        // Deleting all photos associated with the UID
        for index in 0..<4 {
            let photoRef = storage.reference(withPath: "\(uid)_\(index).jpg")
            photoRef.delete { error in
                if let error = error {
                    print("Error deleting photo: \(error.localizedDescription)")
                } else {
                    print("Photo \(uid)_\(index).jpg deleted successfully.")
                }
            }
        }
        
        // Delete user data from Firestore
        Firestore.firestore().collection("users").document(uid).delete { error in
            if let error = error {
                print("Error deleting user data: \(error.localizedDescription)")
                deleteInProgress = false
                return
            }
            
            // Delete the user from Firebase Authentication
            user.delete { error in
                deleteInProgress = false
                if let error = error {
                    print("Error deleting user: \(error.localizedDescription)")
                } else {
                    print("User account deleted successfully.")
                    isUserLoggedIn = false
                    navigateToWelcome = true
                }
            }
        }
    }
    
    private func signOutUser() {
        do {
            try Auth.auth().signOut()
            isUserLoggedIn = false
            navigateToWelcome = true
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}
