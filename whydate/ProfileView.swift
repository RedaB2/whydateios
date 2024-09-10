import SwiftUI
import FirebaseStorage
import FirebaseFirestore

class UserProfileViewModel: ObservableObject {
    @Published var photos: [String] = Array(repeating: "", count: 4) // Initialize with 4 empty slots
    @Published var firstName: String = "{username}"
    @Published var height: String = "N/A"
    @Published var hometown: String = "N/A"
    @Published var age: String = "N/A"
    @Published var astrologicalSign: String = "N/A"
    @Published var major: String = "N/A"
    @Published var year: String = "N/A"
    @Published var school: String = "N/A"
    @Published var schoolName: String = "N/A"
    @Published var profileReveals: Int = 0
    @Published var hasCompletedQuestionnaire: Bool = false // New property
    @Published var isPaired: Bool = false
    @Published var currentMatchUID = ""
    
    func reset() {
        photos = Array(repeating: "", count: 4)
        height = "N/A"
        hometown = "N/A"
        age = "N/A"
        astrologicalSign = "N/A"
        major = "N/A"
        schoolName = "N/A"
        hasCompletedQuestionnaire = false
    }
    
    func checkQuestionnaireStatus(uid: String) {
        let docRef = Firestore.firestore().collection("questionnaires").document(uid)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                DispatchQueue.main.async {
                    self.hasCompletedQuestionnaire = true
                }
            } else {
                DispatchQueue.main.async {
                    self.hasCompletedQuestionnaire = false
                }
            }
        }
    }
    
    
    func saveHeight(uid: String, newHeight: String) {
        Firestore.firestore().collection("users").document(uid).updateData(["height": newHeight]) { error in
            if let error = error {
                print("Failed to save height: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.height = newHeight
                }
                print("Successfully saved height")
            }
        }
    }

    func saveMajor(uid: String, newMajor: String) {
        Firestore.firestore().collection("users").document(uid).updateData(["major": newMajor]) { error in
            if let error = error {
                print("Failed to save major: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.major = newMajor
                }
                print("Successfully saved major")
            }
        }
    }
    
    func saveYear(uid: String, newYear: String) {
        Firestore.firestore().collection("users").document(uid).updateData(["year": newYear]) { error in
            if let error = error {
                print("Failed to save year: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.year = newYear
                }
                print("Successfully saved year")
            }
        }
    }

    func saveHometown(uid: String, newHometown: String) {
        Firestore.firestore().collection("users").document(uid).updateData(["hometown": newHometown]) { error in
            if let error = error {
                print("Failed to save hometown: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.hometown = newHometown
                }
                print("Successfully saved hometown")
            }
        }
    }
    
    func fetchUserPhotos(uid: String) {
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                if let photosData = document.data()?["photos"] as? [String] {
                    DispatchQueue.main.async {
                        for (index, url) in photosData.enumerated() where index < self.photos.count {
                            self.photos[index] = url // Populate photos array
                        }
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func uploadPhoto(_ image: UIImage, uid: String, index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let filename = "\(uid)_\(index).jpg"
        let storageRef = Storage.storage().reference(withPath: filename)
        
        if let imageData = image.jpegData(compressionQuality: 0.75) {
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if let urlString = url?.absoluteString {
                        DispatchQueue.main.async {
                            self.photos[index] = urlString
                            self.savePhotosToFirestore(uid: uid)
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }
    
    private func savePhotosToFirestore(uid: String) {
        let data: [String: Any] = [
            "photos": photos
        ]
        
        Firestore.firestore().collection("users").document(uid).updateData(data) { error in
            if let error = error {
                print("Failed to save photos: \(error.localizedDescription)")
            } else {
                print("Successfully saved photos")
            }
        }
    }
    
    // Fetch current user data and update with calculated values
    func fetchUserProfileData(uid: String) {
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data() // Store the document data in a mutable variable

                // Fetch and set user data
                if let firstName = data?["firstName"] as? String {
                    self.firstName = firstName
                }
                if let height = data?["height"] as? String {
                    self.height = height
                }
                if let hometown = data?["hometown"] as? String {
                    self.hometown = hometown
                }
                if let major = data?["major"] as? String {
                    self.major = major
                }
                if let schoolName = data?["schoolName"] as? String {
                    self.schoolName = schoolName
                }
                
                if let isPaired = data?["isPaired"] as? Bool {
                    self.isPaired = isPaired
                }
                
                if let timestamp = data?["dateOfBirth"] as? Timestamp {
                    let dateOfBirth = timestamp.dateValue()
                    self.age = self.calculateAge(from: dateOfBirth)
                    self.astrologicalSign = self.calculateAstrologicalSign(from: dateOfBirth)

                    // Save the calculated age back to Firestore
                    docRef.updateData([
                        "age": self.age
                    ]) { error in
                        if let error = error {
                            print("Error updating age: \(error)")
                        } else {
                            print("Age successfully updated")
                        }
                    }
                    
                    // Save the calculated age back to Firestore
                    docRef.updateData([
                        "astrologicalSign": self.astrologicalSign
                    ]) { error in
                        if let error = error {
                            print("Error updating AstrologicalSign: \(error)")
                        } else {
                            print("Age successfully updated")
                        }
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }

        private func calculateAge(from dateOfBirth: Date) -> String {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
            if let age = ageComponents.year {
                return "\(age)"
            } else {
                return "N/A"
            }
        }

        private func calculateAstrologicalSign(from dateOfBirth: Date) -> String {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month], from: dateOfBirth)

            guard let day = components.day, let month = components.month else {
                return "N/A"
            }

            switch (month, day) {
            case (3, 21...31), (4, 1...19): return "Aries"
            case (4, 20...30), (5, 1...20): return "Taurus"
            case (5, 21...31), (6, 1...20): return "Gemini"
            case (6, 21...30), (7, 1...22): return "Cancer"
            case (7, 23...31), (8, 1...22): return "Leo"
            case (8, 23...31), (9, 1...22): return "Virgo"
            case (9, 23...30), (10, 1...22): return "Libra"
            case (10, 23...31), (11, 1...21): return "Scorpio"
            case (11, 22...30), (12, 1...21): return "Sagittarius"
            case (12, 22...31), (1, 1...19): return "Capricorn"
            case (1, 20...31), (2, 1...18): return "Aquarius"
            case (2, 19...29), (3, 1...20): return "Pisces"
            default: return "N/A"
            }
        }
}

struct ProfileView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    let uid: String
    
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var currentIndex = 0
    
    @State private var isEditingHeight = false
    @State private var isEditingMajor = false
    @State private var isEditingHometown = false
    @State private var isEditingYear = false
    @State private var showQuestionnaire = false
    
    
    let majors = ["Undeclared", "Computer Science", "Mechanical Engineering", "Electrical Engineering", "Mathematics", "Physics", "Chemistry", "Biology", "Economics", "Business Administration", "Civil Engineering", "Architecture"]
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { index in
                        if viewModel.photos[index].isEmpty {
                            Button(action: {
                                currentIndex = index
                                selectPhoto(index: index)
                            }) {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 300, height: 300) // Increased size
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                        .font(.system(size: 50)) // Increase the size of the plus icon
                                }
                            }
                        } else {
                            if let url = URL(string: viewModel.photos[index]) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 300, height: 300) // Increased size
                                        .clipped()
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20) // Add horizontal padding for better appearance
            }
            .padding(.top, 10) // Slight padding from the top
            
            HStack(spacing: 16) {
                ProfileInfoBox(icon: "birthday.cake", text: viewModel.age)
                ProfileInfoBox(icon: "ruler", text: viewModel.height)
                    .onTapGesture {
                        isEditingHeight = true
                    }
                ProfileInfoBox(icon: "sun.max.fill", text: viewModel.astrologicalSign)
            }
            .padding(.top, 20) // Padding between the photos and the boxes
            
            LargeInfoBox(
                university: viewModel.schoolName,
                major: viewModel.major,
                location: viewModel.hometown,
                year: viewModel.year,
                onEditMajor: {
                    isEditingMajor = true
                },
                onEditHometown: {
                    isEditingHometown = true
                },
                onEditYear: {
                    isEditingYear = true
                }
            )
            .padding(.horizontal, 20) // Optional padding for better alignment
            
            Button(action: {
                            showQuestionnaire = true
                        }) {
                            Text("Questionnaire")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
            
            Spacer() // This pushes the content to the top of the screen
        }
        .onAppear {
            viewModel.fetchUserPhotos(uid: uid)
            viewModel.fetchUserProfileData(uid: uid) // Fetch additional profile data
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
                .onDisappear {
                    if let selectedImage = selectedImage {
                        viewModel.uploadPhoto(selectedImage, uid: uid, index: currentIndex) { result in
                            switch result {
                            case .success:
                                print("Photo uploaded successfully")
                            case .failure(let error):
                                print("Failed to upload photo: \(error.localizedDescription)")
                            }
                        }
                    }
                    selectedImage = nil
                }
        }
        .sheet(isPresented: $isEditingHeight) {
            EditHeightView(height: $viewModel.height, viewModel: viewModel, uid: uid)
        }
        .sheet(isPresented: $isEditingMajor) {
            EditMajorView(major: $viewModel.major, viewModel: viewModel, uid: uid, majors: majors)
        }
        .sheet(isPresented: $isEditingHometown) {
            EditHometownView(hometown: $viewModel.hometown, viewModel: viewModel, uid: uid)
        }
        .sheet(isPresented: $isEditingYear) {
            EditYearView(year: $viewModel.year, viewModel: viewModel, uid: uid)
        }
        .sheet(isPresented: $showQuestionnaire) {
            QuestionnaireView(uid: uid, hasCompletedQuestionnaire: $viewModel.hasCompletedQuestionnaire)
        }
    }
    
    private func selectPhoto(index: Int) {
        isImagePickerPresented = true
    }
}

struct ProfileInfoBox: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
            Text(text)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
    }
}

struct LargeInfoBox: View {
    var university: String
    var major: String
    var location: String
    var year: String
    

    var onEditMajor: () -> Void
    var onEditHometown: () -> Void
    var onEditYear: () -> Void
    
    
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
                    .onTapGesture {
                        onEditMajor()
                    }
            }
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.black)
                Text(year)
                    .foregroundColor(.black)
                    .font(.headline)
                    .onTapGesture {
                        onEditYear()
                    }
            }
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.black)
                Text(location)
                    .foregroundColor(.black)
                    .font(.headline)
                    .onTapGesture {
                        onEditHometown()
                    }
            }
        }
        .padding()
        .frame(maxWidth: .infinity) // Ensure the box takes up the full width
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
    }
}

// Edit views for height, major, and hometown

struct EditHeightView: View {
    @Binding var height: String
    @Environment(\.presentationMode) var presentationMode
    let viewModel: UserProfileViewModel
    let uid: String
    
    let heights: [String] = {
        var heights = [String]()
        for feet in 4...7 {
            for inches in 0...11 {
                heights.append("\(feet)'\(inches)\"")
            }
        }
        return heights
    }()
    
    var body: some View {
        VStack {
            Text("Edit Height")
                .font(.headline)
            
            Picker("Select Height", selection: $height) {
                ForEach(heights, id: \.self) { height in
                    Text(height).tag(height)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 150)
            
            Button("Save") {
                viewModel.saveHeight(uid: uid, newHeight: height)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .padding()
    }
}

struct EditYearView: View {
    @Binding var year: String
    @Environment(\.presentationMode) var presentationMode
    let viewModel: UserProfileViewModel
    let uid: String
    
    let years = ["Freshmen","Sophomore", "Junior", "Senior"]
    
    var body: some View {
        VStack {
            Text("Edit Year")
                .font(.headline)
            
            Picker("Select Year", selection: $year) {
                ForEach(years, id: \.self) { year in
                    Text(year).tag(year)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 150)
            
            Button("Save") {
                viewModel.saveYear(uid: uid, newYear: year)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .padding()
    }
}

struct EditMajorView: View {
    @Binding var major: String
    @Environment(\.presentationMode) var presentationMode
    let viewModel: UserProfileViewModel
    let uid: String
    
    let majors: [String]
    
    var body: some View {
        VStack {
            Text("Edit Major")
                .font(.headline)
            
            Picker("Select Major", selection: $major) {
                ForEach(majors, id: \.self) { major in
                    Text(major).tag(major)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            Button("Save") {
                viewModel.saveMajor(uid: uid, newMajor: major)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .padding()
    }
}

struct EditHometownView: View {
    @Binding var hometown: String
    @Environment(\.presentationMode) var presentationMode
    let viewModel: UserProfileViewModel
    let uid: String
    
    var body: some View {
        VStack {
            Text("Edit Hometown")
                .font(.headline)
            
            TextField("Enter hometown", text: $hometown)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Save") {
                viewModel.saveHometown(uid: uid, newHometown: hometown)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .padding()
    }
}

