import SwiftUI
import FirebaseFirestore

struct QuestionnaireView: View {
    let uid: String
    @Binding var hasCompletedQuestionnaire: Bool // Binding to notify HomeView
    @State private var isFirstTime = false
    @State private var answers: [String: String] = [:] // To store answers
    @State private var loading = true
    
    var body: some View {
        NavigationStack {
            if loading {
                ProgressView("Loading...")
                    .onAppear {
                        checkIfFirstTime()
                    }
            } else {
                if isFirstTime {
                    BinaryQuestionnaireForm(uid: uid, onComplete: saveAnswers)
                } else {
                    ViewAnswersView(answers: answers)
                }
            }
        }
        .navigationTitle("Questionnaire")
    }
    
    private func checkIfFirstTime() {
        let docRef = Firestore.firestore().collection("questionnaires").document(uid)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                if let data = document.data() as? [String: String] {
                    self.answers = data
                    self.isFirstTime = false
                } else {
                    self.isFirstTime = true
                }
            } else {
                self.isFirstTime = true
            }
            self.loading = false
        }
    }
    
    private func saveAnswers(answers: [String: String]) {
        let docRef = Firestore.firestore().collection("questionnaires").document(uid)
        docRef.setData(answers) { error in
            if let error = error {
                print("Error saving questionnaire: \(error.localizedDescription)")
            } else {
                print("Questionnaire saved successfully.")
                self.answers = answers
                self.isFirstTime = false
                self.hasCompletedQuestionnaire = true // Notify HomeView that the questionnaire is completed
            }
        }
    }
}

struct BinaryQuestionnaireForm: View {
    let uid: String
    let onComplete: ([String: String]) -> Void
    @State private var answers: [String: String] = [
        "exploring": "No",
        "humor": "No",
        "loveAtFirstSight": "No",
        "morningPerson": "No",
        "deepConversations": "No",
        "careerGoals": "No",
        "movieNight": "No",
        "politicalViews": "No",
        "dogPerson": "No",
        "cookingTogether": "No",
        "oppositesAttract": "No",
        "quietNight": "No",
        "kids": "No",
        "physicalFitness": "No",
        "friendship": "No",
        "travelWorld": "No",
        "religiousBeliefs": "No",
        "trust": "No",
        "spontaneity": "No",
        "sports": "No",
        "friends": "No",
        "longDistance": "No",
        "smallGesture": "No",
        "musicTaste": "No",
        "newFoods": "No",
        "laughter": "No",
        "independence": "No",
        "introverted": "No",
        "hobbies": "No",
        "loveBeforeCareer": "No"
    ] // Initialize with "No" as default
    
    var body: some View {
        Form {
            Section(header: Text("Questionnaire")) {
                Toggle("Do you prefer spending your weekends exploring new places rather than staying in?", isOn: Binding(
                    get: { answers["exploring"] == "Yes" },
                    set: { answers["exploring"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Is humor a key factor for you in a relationship?", isOn: Binding(
                    get: { answers["humor"] == "Yes" },
                    set: { answers["humor"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you believe in love at first sight?", isOn: Binding(
                    get: { answers["loveAtFirstSight"] == "Yes" },
                    set: { answers["loveAtFirstSight"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Are you more of a morning person than a night owl?", isOn: Binding(
                    get: { answers["morningPerson"] == "Yes" },
                    set: { answers["morningPerson"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you value deep conversations over small talk?", isOn: Binding(
                    get: { answers["deepConversations"] == "Yes" },
                    set: { answers["deepConversations"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Is it important for you to share similar career goals with your partner?", isOn: Binding(
                    get: { answers["careerGoals"] == "Yes" },
                    set: { answers["careerGoals"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Would you rather have a movie night than go to a party?", isOn: Binding(
                    get: { answers["movieNight"] == "Yes" },
                    set: { answers["movieNight"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you think it’s important to share similar political views with your partner?", isOn: Binding(
                    get: { answers["politicalViews"] == "Yes" },
                    set: { answers["politicalViews"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Are you a dog person more than a cat person?", isOn: Binding(
                    get: { answers["dogPerson"] == "Yes" },
                    set: { answers["dogPerson"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Is cooking together something you would enjoy in a relationship?", isOn: Binding(
                    get: { answers["cookingTogether"] == "Yes" },
                    set: { answers["cookingTogether"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you believe that opposites attract?", isOn: Binding(
                    get: { answers["oppositesAttract"] == "Yes" },
                    set: { answers["oppositesAttract"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Would you prefer a quiet night in with a good book over going out?", isOn: Binding(
                    get: { answers["quietNight"] == "Yes" },
                    set: { answers["quietNight"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you see yourself wanting kids in the future?", isOn: Binding(
                    get: { answers["kids"] == "Yes" },
                    set: { answers["kids"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Is physical fitness important to you in a partner?", isOn: Binding(
                    get: { answers["physicalFitness"] == "Yes" },
                    set: { answers["physicalFitness"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you believe that a strong friendship is essential in a romantic relationship?", isOn: Binding(
                    get: { answers["friendship"] == "Yes" },
                    set: { answers["friendship"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Would you rather travel the world than settle in one place?", isOn: Binding(
                    get: { answers["travelWorld"] == "Yes" },
                    set: { answers["travelWorld"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Is it important for you to share the same religious beliefs as your partner?", isOn: Binding(
                    get: { answers["religiousBeliefs"] == "Yes" },
                    set: { answers["religiousBeliefs"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you think that trust is more important than love in a relationship?", isOn: Binding(
                    get: { answers["trust"] == "Yes" },
                    set: { answers["trust"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Are you someone who prefers spontaneity over planning?", isOn: Binding(
                    get: { answers["spontaneity"] == "Yes" },
                    set: { answers["spontaneity"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you enjoy watching sports with someone else?", isOn: Binding(
                    get: { answers["sports"] == "Yes" },
                    set: { answers["sports"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Is it important for you that your partner gets along with your friends?", isOn: Binding(
                    get: { answers["friends"] == "Yes" },
                    set: { answers["friends"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you believe that long-distance relationships can work?", isOn: Binding(
                    get: { answers["longDistance"] == "Yes" },
                    set: { answers["longDistance"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Would you rather be surprised with a small gesture of affection than receive a big, planned gift?", isOn: Binding(
                    get: { answers["smallGesture"] == "Yes" },
                    set: { answers["smallGesture"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Is it important for you that your partner shares your taste in music?", isOn: Binding(
                    get: { answers["musicTaste"] == "Yes" },
                    set: { answers["musicTaste"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you enjoy trying new foods and cuisines with your partner?", isOn: Binding(
                    get: { answers["newFoods"] == "Yes" },
                    set: { answers["newFoods"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you believe that laughter is the best way to resolve conflicts?", isOn: Binding(
                    get: { answers["laughter"] == "Yes" },
                    set: { answers["laughter"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Are you someone who values independence in a relationship?", isOn: Binding(
                    get: { answers["independence"] == "Yes" },
                    set: { answers["independence"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you prefer a partner who is more introverted than extroverted?", isOn: Binding(
                    get: { answers["introverted"] == "Yes" },
                    set: { answers["introverted"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Is it important to you that your partner is involved in your hobbies?", isOn: Binding(
                    get: { answers["hobbies"] == "Yes" },
                    set: { answers["hobbies"] = $0 ? "Yes" : "No" }
                ))
                Toggle("Do you believe that love should always come before career?", isOn: Binding(
                    get: { answers["loveBeforeCareer"] == "Yes" },
                    set: { answers["loveBeforeCareer"] = $0 ? "Yes" : "No" }
                ))
            }
            
            Button(action: {
                onComplete(answers)
            }) {
                Text("Submit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

struct ViewAnswersView: View {
    let answers: [String: String]
    let questions = [
        "exploring": "Do you prefer spending your weekends exploring new places rather than staying in?",
        "humor": "Is humor a key factor for you in a relationship?",
        "loveAtFirstSight": "Do you believe in love at first sight?",
        "morningPerson": "Are you more of a morning person than a night owl?",
        "deepConversations": "Do you value deep conversations over small talk?",
        "careerGoals": "Is it important for you to share similar career goals with your partner?",
        "movieNight": "Would you rather have a movie night than go to a party?",
        "politicalViews": "Do you think it’s important to share similar political views with your partner?",
        "dogPerson": "Are you a dog person more than a cat person?",
        "cookingTogether": "Is cooking together something you would enjoy in a relationship?",
        "oppositesAttract": "Do you believe that opposites attract?",
        "quietNight": "Would you prefer a quiet night in with a good book over going out?",
        "kids": "Do you see yourself wanting kids in the future?",
        "physicalFitness": "Is physical fitness important to you in a partner?",
        "friendship": "Do you believe that a strong friendship is essential in a romantic relationship?",
        "travelWorld": "Would you rather travel the world than settle in one place?",
        "religiousBeliefs": "Is it important for you to share the same religious beliefs as your partner?",
        "trust": "Do you think that trust is more important than love in a relationship?",
        "spontaneity": "Are you someone who prefers spontaneity over planning?",
        "sports": "Do you enjoy watching sports with someone else?",
        "friends": "Is it important for you that your partner gets along with your friends?",
        "longDistance": "Do you believe that long-distance relationships can work?",
        "smallGesture": "Would you rather be surprised with a small gesture of affection than receive a big, planned gift?",
        "musicTaste": "Is it important for you that your partner shares your taste in music?",
        "newFoods": "Do you enjoy trying new foods and cuisines with your partner?",
        "laughter": "Do you believe that laughter is the best way to resolve conflicts?",
        "independence": "Are you someone who values independence in a relationship?",
        "introverted": "Do you prefer a partner who is more introverted than extroverted?",
        "hobbies": "Is it important to you that your partner is involved in your hobbies?",
        "loveBeforeCareer": "Do you believe that love should always come before career?"
    ]
    
    
    
    var body: some View {
        List(answers.keys.sorted(), id: \.self) { key in
            if let question = questions[key], let answer = answers[key] {
                Text("\(question): \(answer)")
            }
        }
    }
}
