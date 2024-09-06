import SwiftUI
import FirebaseAuth
import PhotosUI
import FirebaseStorage
import FirebaseFirestore

struct AccountCreationView: View {
    @State private var firstName: String = ""
    @State private var email: String = ""
    @State private var schoolName: String = ""
    @State private var potentialMatches: Int = 0
    @State private var profileReveals: Int = 0
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var selectedMajor: String = "Undeclared"
    @State private var selectedGender: String = "Male"
    @State private var dateOfBirth: Date = Date()
    @State private var showImagePicker: Bool = false
    @State private var showVerificationScreen = false
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    @State private var firstNameError: String? = nil
    @State private var profileImageError: String? = nil
    @State private var dateOfBirthError: String? = nil
    @Binding var isUserLoggedIn: Bool
    
    let majors = ["Undeclared","Computer Science", "Mechanical Engineering", "Electrical Engineering", "Mathematics", "Physics", "Chemistry", "Biology", "Economics", "Business Administration", "Civil Engineering", "Architecture"]
    
    let genders = ["Male","Female", "Other"]
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                Spacer(minLength: 20)
                
                
                Image("WhyDate")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 100)
                
                
                if let profileImageError = profileImageError {
                    Text(profileImageError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 20)
                        .padding(.bottom, -10)
                }
                
                Button(action: {
                    showImagePicker = true
                }) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    } else {
                        Image("profileicon")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 20)
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $profileImage)
                }

                CustomTextField(placeholder: "First Name (required)", text: $firstName, isSecure: false)
                if let firstNameError = firstNameError {
                    Text(firstNameError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 20)
                        .padding(.bottom, -10)
                }
                
                
                CustomTextField(placeholder: "Email", text: $email, isSecure: false)
                if let emailError = emailError {
                    Text(emailError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 20)
                        .padding(.bottom, -10)
                }

                CustomTextField(placeholder: "Password", text: $password, isSecure: false)
                if let passwordError = passwordError {
                    Text(passwordError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 20)
                        .padding(.bottom, -10)
                }
                
                CustomTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: false)
                if let confirmPasswordError = confirmPasswordError {
                    Text(confirmPasswordError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 20)
                        .padding(.bottom, -10)
                }

                HStack{
                    Text("Major")
                        
                    Picker("Major", selection: $selectedMajor) {
                        ForEach(majors, id: \.self) { major in
                            Text(major).tag(major)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    
                    Text("Gender")
                    
                    Picker("Gender", selection: $selectedGender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                }
                
                DatePicker("What's your birthday?", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal, 20)
                
                if let dateOfBirthError = dateOfBirthError {
                    Text(dateOfBirthError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 20)
                        .padding(.bottom, -10)
                }

                
                Button(action: {
                    clearErrors()
                    
                    if let emptyImageError = checkForEmptyImage() {
                        setErrorMessage(for: emptyImageError)
                    } else if let emptyFieldError = checkForEmptyFields() {
                        setErrorMessage(for: emptyFieldError)
                    } else if !isSchoolEmail(email) {
                        emailError = "You need to use your school email!"
                    } else if !isValidEmail(email) {
                        emailError = "We haven't come to your school yet! Contact us and we will come!"
                    } else if password != confirmPassword {
                        confirmPasswordError = "The passwords do not match."
                    } else if let dobError = checkForDOB() {
                        setErrorMessage(for: dobError)
                    } else {
                        createAccount()
                    }
                }) {
                    Text("Create Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 232/255, green: 10/255, blue: 137/255))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }

                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    NavigationLink(destination: LoginView(isUserLoggedIn: $isUserLoggedIn)) {
                        Text("Log In")
                            .foregroundColor(Color(red: 40/255, green: 170/255, blue: 225/255))
                            .fontWeight(.bold)
                    }
                }
                .padding(.bottom, 20)
                
            }
            .navigationDestination(isPresented: $showVerificationScreen) {
                EmailVerificationView()
            }
        }
    }
    
    private func createAccount() {
        // Ensure the profile image is not nil before proceeding
        guard let profileImage = profileImage else {
            profileImageError = "Please add a profile picture."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let uid = authResult?.user.uid else {
                print("Failed to retrieve user UID")
                return
            }
            
            print("User created: \(uid)")
            
            
            // Proceed with uploading the profile image
            uploadProfileImage(profileImage, uid: "\(uid)") { result in
                switch result {
                case .success(let urlString):
                    print("Profile image uploaded: \(urlString)")
                    // Save user data with the photo URL stored in the photos array
                    saveUserData(photoUrl: urlString, uid: uid)
                case .failure(let error):
                    print("Failed to upload profile image: \(error.localizedDescription)")
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        return true
        //return email.lowercased().hasSuffix("@wpi.edu") || email.lowercased().hasSuffix("@icloud.com") || email.lowercased().hasSuffix("@whydate.app")
    }
    
    private func isSchoolEmail(_ email: String) -> Bool {
        return true
        //return email.lowercased().hasSuffix(".edu") || email.lowercased().hasSuffix(".app") || email.lowercased().hasSuffix(".com")
    }
    
    private func checkForEmptyFields() -> String? {
        if email.isEmpty {
            return "Email"
        } else if password.isEmpty {
            return "Password"
        } else if confirmPassword.isEmpty {
            return "Confirm Password"
        } else if firstName.isEmpty {
            return "First Name"
        }
        return nil
    }
    
    private func checkForEmptyImage() -> String? {
        if profileImage == nil {
            return "Profile Image"
        }
        return nil
    }
    
    private func checkForDOB() -> String? {
        let calendar = Calendar.current
        let currentDate = Date()
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: currentDate)
        
        if let age = ageComponents.year, age < 18{
            return "Date Of Birth"
        }
        return nil
    }
    
    private func setErrorMessage(for field: String) {
        switch field {
        case "Email":
            emailError = "You need to enter your school email!"
        case "Password":
            passwordError = "Please enter a password!"
        case "Confirm Password":
            confirmPasswordError = "You need to confirm the password!"
        case "First Name":
            firstNameError = "Please enter your first name."
        case "Profile Image":
            profileImageError = "Please add a profile picture."
        case "Date Of Birth":
            dateOfBirthError = "18 years old minimum."
        default:
            break
        }
    }
    
    private func clearErrors() {
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        firstNameError = nil
        profileImageError = nil
        dateOfBirthError = nil
    }
    
    func uploadProfileImage(_ image: UIImage, uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        let filename = "\(uid)_0.jpg" // Storing the first image as index 0 in the photos array
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
                        completion(.success(urlString))
                    }
                }
            }
        }
    }
    

    func saveUserData(photoUrl: String, uid: String) {
        
        if email.lowercased().hasSuffix("@wpi.edu"){
            schoolName = "WPI"
        }
        if email.lowercased().hasSuffix("@icloud.com"){
            schoolName = "Test University"
        }
        
        let data: [String: Any] = [
            "firstName": firstName,
            "email": email,
            "schoolName": schoolName,
            "potentialMatches": potentialMatches,
            "profileReveals": profileReveals,
            "isPaired": false,
            "major": selectedMajor,
            "gender": selectedGender,
            "dateOfBirth": dateOfBirth,
            "photos": [photoUrl] // Store the first photo URL in the photos array
        ]
        
        Firestore.firestore().collection("users").document(uid).setData(data) { error in
            if let error = error {
                print("Failed to save user data: \(error.localizedDescription)")
                return
            }
            print("Successfully saved user data")
            
            Auth.auth().currentUser?.sendEmailVerification { error in
                if let error = error {
                    print("Failed to send verification email: \(error.localizedDescription)")
                } else {
                    print("Verification email sent.")
                    self.showVerificationScreen = true
                }
            }
            
            self.isUserLoggedIn = true
        }
    }
}




struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .autocorrectionDisabled(true)
                    .textContentType(.none)  // This disables the strong password suggestion
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .textContentType(.emailAddress)  // or .none to disable content type
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
