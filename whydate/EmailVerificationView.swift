import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    @State private var isEmailVerified = false
    @State private var errorMessage: String?
    @State private var navigateToHome = false

    var body: some View {
        NavigationStack {
            VStack {
                if isEmailVerified {
                    Text("Email Verified! 🎉")
                        .font(.largeTitle)
                        .padding()
                    

                    Button(action: {
                        navigateToHome = true // Trigger navigation to HomeView
                    }) {
                        Text("Go to Home")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                } else {
                    Text("Please check your email and verify your account.")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Button(action: {
                        checkEmailVerification()
                    }) {
                        Text("I have verified my email")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .onAppear {
                checkEmailVerification()
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView(isUserLoggedIn: .constant(true)) // Pass true to indicate the user is logged in
            }
        }
    }

    func checkEmailVerification() {
        Auth.auth().currentUser?.reload(completion: { error in
            if let error = error {
                self.errorMessage = "Error checking email verification: \(error.localizedDescription)"
            } else {
                self.isEmailVerified = Auth.auth().currentUser?.isEmailVerified ?? false
            }
        })
    }
}

#Preview {
    EmailVerificationView()
}
