import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var navigateToWelcome = false
    @State private var uid: String? = nil
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            if viewModel.hasCompletedQuestionnaire {
                regularHomeView
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
            } else {
                incompleteQuestionnaireView
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
            }
            
            MessageView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Messages")
                }
                .tag(1)
            
            if let uid = uid {
                ProfileView(viewModel: viewModel, uid: uid)
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(2)
            }
            
            SettingsView(isUserLoggedIn: $isUserLoggedIn)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .onAppear {
            uid = Auth.auth().currentUser?.uid
            if let uid = uid {
                viewModel.reset()
                viewModel.fetchUserProfileData(uid: uid)
                viewModel.checkQuestionnaireStatus(uid: uid) // Check questionnaire status
            }
        }
    }

    private var regularHomeView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Text("Hi \(viewModel.firstName)")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                    Spacer()
                }
                HStack(spacing: 20) {
                    InfoBox(number: viewModel.potentialMatches, label: "Potential Matches", numberColor: .blue)
                    InfoBox(number: viewModel.profileReveals, label: "Profile Reveals", numberColor: .pink)
                }
                .padding(.top, 20)
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }

    private var incompleteQuestionnaireView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Text("Hi \(viewModel.firstName)")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                    Spacer()
                }
                HStack(spacing: 20){
                    WelcomeBox()
                }
                HStack(spacing: 20){
                    ButtonBox(selectedTab: $selectedTab) // Pass the binding to the ButtonBox
                }
                HStack(spacing: 20) {
                    InfoBox(number: viewModel.potentialMatches, label: "Potential Matches", numberColor: .blue)
                    InfoBox(number: viewModel.profileReveals, label: "Profile Reveals", numberColor: .pink)
                }
                .padding(.top, 20)
                Spacer()
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


struct WelcomeBox: View {
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Welcome To")
                .foregroundColor(.black)
                .font(.largeTitle)
                .bold()
            
            Image("WhyDate")
                .resizable()
                .scaledToFit()
                .frame(height: 100) // Adjust the height as needed
        }
        .padding()
        .frame(width: 325)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
    }
}

struct ButtonBox: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("To Get Started")
                .foregroundColor(.black)
                .font(.largeTitle)
                .bold()
            
            Button(action: {
                selectedTab = 2 // Navigate to the Profile tab
            }) {
                Text("Complete your profile")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(red: 232/255, green: 10/255, blue: 137/255)
                            .opacity(0.6) // Apply opacity to the background only
                    )
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: {
                selectedTab = 2 // Navigate to the Profile tab
            }) {
                Text("Take Questionnaire")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(red: 232/255, green: 10/255, blue: 137/255)
                            .opacity(0.6) // Apply opacity to the background only
                    )
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 325)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
    }
}
