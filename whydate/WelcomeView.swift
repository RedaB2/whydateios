// last edited test commit

import SwiftUI

struct WelcomeView: View {
    @Binding var isUserLoggedIn: Bool
    
    var body: some View {
        NavigationStack{
            VStack {
                Spacer()
                Image("WhyDate")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                
                Text("Rethink Dating")
                    .font(.custom("Comfortaa", size: 25))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
                
                Spacer()
                
                // GO TO ACCOUNT CREATION
                NavigationLink(destination: AccountCreationView(isUserLoggedIn: $isUserLoggedIn)) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 232/255, green: 10/255, blue: 137/255))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                
                // GO TO LOGIN
                NavigationLink(destination: LoginView(isUserLoggedIn: $isUserLoggedIn)) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 40/255, green: 170/255, blue: 225/255))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    WelcomeView(isUserLoggedIn: .constant(false))
}
