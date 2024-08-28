import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var navigateToWelcome = false
    @State private var uid: String? = nil
    @StateObject private var viewModel = UserProfileViewModel()
    
    var body: some View {
        TabView {
            mainHomeView
                .tabItem {
                    Image(systemName: "house.fill")
                }
            
            MessageView()
                .tabItem {
                    Image(systemName: "message.fill")
                }
            
            if let uid = uid {
                ProfileView(uid: uid)
                    .tabItem {
                        Image(systemName: "person.fill")
                    }
            }
            
            SettingsView(isUserLoggedIn: $isUserLoggedIn)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                }
        }
        .onAppear {
            uid = Auth.auth().currentUser?.uid
            if let uid = uid {
                viewModel.reset()
                viewModel.fetchUserProfileData(uid: uid)
            }
        }
    }
    
    private var mainHomeView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    // Using the existing InfoBox component
                    InfoBox(number: viewModel.potentialMatches, label: "Potential Matches", numberColor: .blue)
                    InfoBox(number: viewModel.profileReveals, label: "Profile Reveals", numberColor: .pink)
                }
                .padding(.top, 20)
                
                Spacer() // Use Spacer to push the boxes to the top if needed
            }
            .navigationBarHidden(true)
        }
    }
}

struct InfoBox: View {
    var number: Int
    var label: String
    var numberColor: Color
    
    var body: some View {
        VStack {
            Text("\(number)")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(numberColor)
            Text(label)
                .font(.headline)
                .foregroundColor(.black)
        }
        .padding()
        .frame(width: 150, height: 150)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
    }
}
