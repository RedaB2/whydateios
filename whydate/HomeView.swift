import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var navigateToWelcome = false
    @State private var uid: String? = nil
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var selectedTab = 0
    @State private var numberOfMatches: Int = 0
    @State private var bestMatch: Match? = nil
    @State private var isProfileRevealed: Bool = false  // Track profile reveal status

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
                    InfoBox(number: numberOfMatches, label: "Potential Matches", numberColor: .blue)
                    InfoBox(number: viewModel.profileReveals, label: "Profile Reveals", numberColor: .pink)
                }
                .onAppear{
                    if let uid = uid {
                        // Call findMatches to calculate matches and update Firestore
                        findMatches(for: uid) { matches in
                            // Update the number of matches based on the Firestore field
                            calculatePotentialMatches(for: uid) { matchesCount in
                                self.numberOfMatches = matchesCount
                            }
                        }
                    }
                }
                .padding(.top, 20)
                
                if let match = bestMatch {
                    // Show "Anonymous" or First Name based on profile reveal status
                    let displayName = isProfileRevealed ? (match.matchData["firstName"] as? String ?? "Unknown") : "Anonymous"
                    
                    Text("Best Match: \(displayName)")
                        .font(.headline)
                    Text("Score: \(match.score)")
                        .font(.subheadline)
                } else {
                    Text("No match found.")
                        .font(.headline)
                }
                
                
                Spacer()
            }
            .onAppear{
                if let uid = uid {
                    // Call findMatches to calculate matches and update Firestore
                    findBestMatch(for: uid) { match in
                        self.bestMatch = match
                        if let matchUID = match?.uid {
                            // Fetch profile reveal status from Firestore
                            fetchProfileRevealStatus(for: matchUID) { revealed in
                                self.isProfileRevealed = revealed
                            }
                        }
                    }
                }
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
                    InfoBox(number: numberOfMatches, label: "Potential Matches", numberColor: .blue)
                    InfoBox(number: viewModel.profileReveals, label: "Profile Reveals", numberColor: .pink)
                }
                .padding(.top, 20)
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }

    // Function to fetch profile reveal status
    func fetchProfileRevealStatus(for matchUID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let matchRef = db.collection("users").document(matchUID)
        
        matchRef.getDocument { document, error in
            if let document = document, document.exists {
                let isRevealed = document.data()?["isProfileRevealed"] as? Bool ?? false
                completion(isRevealed)
            } else {
                print("Match document does not exist")
                completion(false)
            }
        }
    }
    
    // Function to fetch the number of matches
    func calculatePotentialMatches(for userUID: String, completion: @escaping (Int) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userUID)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                if let potentialMatches = document.data()?["potentialMatches"] as? Int {
                    completion(potentialMatches)  // Send the count to the UI
                } else {
                    completion(0)  // Default to 0 if no matches
                }
            } else {
                print("User document does not exist")
                completion(0)
            }
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
