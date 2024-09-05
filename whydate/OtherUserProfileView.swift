import FirebaseFirestore
import FirebaseStorage
import SwiftUI

class OtherUserProfileViewModel: ObservableObject {
    @Published var photos: [String] = Array(repeating: "", count: 4)
    @Published var firstName: String = "{username}"
    @Published var height: String = "N/A"
    @Published var hometown: String = "N/A"
    @Published var age: String = "N/A"
    @Published var astrologicalSign: String = "N/A"
    @Published var major: String = "N/A"
    @Published var schoolName: String = "N/A"
    @Published var hasCompletedQuestionnaire: Bool = false
    @Published var questionnaireAnswers: [String: String] = [:]
    
    // Fetch other user's profile data from Firestore
    func fetchOtherUserProfile(uid: String) {
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                
                DispatchQueue.main.async {
                    self.firstName = data["firstName"] as? String ?? "{username}"
                    self.height = data["height"] as? String ?? "N/A"
                    self.hometown = data["hometown"] as? String ?? "N/A"
                    self.age = data["age"] as? String ?? "N/A"
                    self.astrologicalSign = data["astrologicalSign"] as? String ?? "N/A"
                    self.major = data["major"] as? String ?? "N/A"
                    self.schoolName = data["schoolName"] as? String ?? "N/A"
                }
            } else {
                print("Error fetching user data: \(String(describing: error))")
            }
        }
    }

    // Fetch other user's photos from Firestore
    func fetchOtherUserPhotos(uid: String) {
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let photosData = document.data()?["photos"] as? [String] {
                    DispatchQueue.main.async {
                        for (index, url) in photosData.enumerated() where index < self.photos.count {
                            self.photos[index] = url
                        }
                    }
                }
            } else {
                print("Error fetching user photos: \(String(describing: error))")
            }
        }
    }
    
    // Fetch questionnaire answers for another user
    func fetchOtherUserQuestionnaire(uid: String) {
        let docRef = Firestore.firestore().collection("questionnaires").document(uid)
        docRef.getDocument { document, error in
            if let document = document, let data = document.data() as? [String: String] {
                DispatchQueue.main.async {
                    self.questionnaireAnswers = data
                }
            } else {
                print("No questionnaire data found")
            }
        }
    }
}

struct OtherUserProfileView: View {
    @ObservedObject var viewModel: OtherUserProfileViewModel
    let uid: String
    @State private var showQuestionnaire = false
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { index in
                        if let url = URL(string: viewModel.photos[index]) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 300, height: 300)
                                    .clipped()
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 300, height: 300)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 10)
            
            HStack(spacing: 16) {
                ProfileInfoBox(icon: "birthday.cake", text: viewModel.age)
                ProfileInfoBox(icon: "ruler", text: viewModel.height)
                ProfileInfoBox(icon: "sun.max.fill", text: viewModel.astrologicalSign)
            }
            .padding(.top, 20)
            
            LargeInfoBoxViewing(
                university: viewModel.schoolName,
                major: viewModel.major,
                location: viewModel.hometown
            )
            .padding(.horizontal, 20)

            Button(action: {
                showQuestionnaire = true
            }) {
                Text("View Questionnaire")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .onAppear {
            viewModel.fetchOtherUserProfile(uid: uid)
            viewModel.fetchOtherUserPhotos(uid: uid)
            viewModel.fetchOtherUserQuestionnaire(uid: uid) // Fetch the questionnaire answers
        }
        .sheet(isPresented: $showQuestionnaire) {
            ViewAnswersView(answers: viewModel.questionnaireAnswers)
        }
    }
}

struct LargeInfoBoxViewing: View {
    var university: String
    var major: String
    var location: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "building.columns.fill")
                    .foregroundColor(.black)
                Text(university)
                    .foregroundColor(.black)
                    .font(.headline)
            }
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.black)
                Text(major)
                    .foregroundColor(.black)
                    .font(.headline)
            }
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.black)
                Text(location)
                    .foregroundColor(.black)
                    .font(.headline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity) // Ensure the box takes up the full width
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
    }
}
