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
    @State private var isPaired: Bool? = nil
    @State private var currentMatchFirstName: String? = nil

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
            
            if let uid = uid {
                if viewModel.isPaired {
                    MessagingView(userUID: uid)
                        .tabItem {
                            Image(systemName: "message.fill")
                            Text("Messages")
                        }
                        .tag(1)
                } else {
                    Text("We are working on finding a match for you.")
                        .tabItem {
                            Image(systemName: "message.fill")
                            Text("Messages")
                        }
                        .tag(1)
                }
            }
        
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
                
                // Check isPaired state to determine what to display
                if let isPaired = isPaired {
                    if isPaired {
                        if let currentMatchFirstName = currentMatchFirstName {
                            Text("You were paired with \(currentMatchFirstName)")
                                .font(.headline)
                        } else {
                            Text("Working on finding the match!")
                                .font(.headline)
                        }
                    } else {
                        Text("Working on finding your match!")
                            .font(.headline)
                    }
                } else {
                    Text("Loading...")
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
                    
                    // Call findBestMatchAndPair and handle the completion
                    findBestMatchAndPair(for: uid) { pairedMatch in
                        if let match = pairedMatch {
                            // Update UI or state based on the paired match
                            self.bestMatch = match
                            print("Successfully paired with match: \(match.uid)")
                        } else {
                            print("No available match to pair with.")
                        }
                    }
                    
                    // Fetch the user's pairing status
                    fetchIsPaired(for: uid) { paired in
                        self.isPaired = paired  // Update the state
                        if paired {
                            // If paired, fetch and update the current match's first name
                            fetchCurrentMatchFirstName(for: uid) { firstName in
                                self.currentMatchFirstName = firstName  // Update the state
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
