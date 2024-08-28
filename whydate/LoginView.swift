import SwiftUI
import FirebaseAuth

struct LoginView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    @Binding var isUserLoggedIn: Bool
    @State private var errorMessage: String? = nil
    @State private var navigateToHome = false
    
    @StateObject private var viewModel = UserProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // White Background
                Color.white
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    
                    Image("WhyDate")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 300)
                    
                    Text("Welcome Back")
                        .font(.custom("Comfortaa-Regular", size: 25))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    CustomTextField(placeholder: "Email", text: $email, isSecure: false)
                    CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal, 20)
                            .padding(.bottom, -10)
                    }
                    
                    Button(action: {
                        loginUser()
                    }) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 40/255, green: 170/255, blue: 225/255))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                    
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        NavigationLink(destination: AccountCreationView(isUserLoggedIn: $isUserLoggedIn)) {
                            Text("Join Us!")
                                .foregroundColor(Color(red: 232/255, green: 10/255, blue: 137/255))
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView(isUserLoggedIn: $isUserLoggedIn) // Pass the correct state binding to HomeView
            }
        }
    }
   
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.errorMessage = "Login failed: \(error.localizedDescription)"
            } else {
                print("User logged in: \(authResult?.user.uid ?? "")")
                self.isUserLoggedIn = true
                navigateToHome = true
                viewModel.reset()
            }
        }
    }
}
