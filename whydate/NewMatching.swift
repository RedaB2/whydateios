import Foundation
import FirebaseFirestore

// Define astrological compatibility dictionary with weighted values
let compatibilityMap: [String: [String: Double]] = [
    "Aries": ["Leo": 100, "Sagittarius": 100, "Gemini": 75, "Libra": 75, "Aquarius": 70, "Aries": 70, "Pisces": 50, "Taurus": 50, "Virgo": 45, "Capricorn": 45, "Scorpio": 40, "Cancer": 30],
    "Taurus": ["Virgo": 100, "Capricorn": 100, "Cancer": 75, "Pisces": 75, "Taurus": 70, "Scorpio": 70, "Libra": 55, "Leo": 50, "Aquarius": 45, "Sagittarius": 40, "Aries": 30, "Gemini": 30],
    "Gemini": ["Libra": 100, "Aquarius": 100, "Aries": 75, "Leo": 75, "Sagittarius": 70, "Gemini": 70, "Pisces": 50, "Virgo": 50, "Taurus": 40, "Capricorn": 40, "Cancer": 30, "Scorpio": 30],
    "Cancer": ["Scorpio": 100, "Pisces": 100, "Taurus": 75, "Virgo": 75, "Cancer": 70, "Capricorn": 70, "Libra": 50, "Leo": 50, "Gemini": 45, "Aquarius": 45, "Aries": 30, "Sagittarius": 30],
    "Leo": ["Aries": 100, "Sagittarius": 100, "Gemini": 75, "Libra": 75, "Leo": 70, "Aquarius": 70, "Pisces": 50, "Taurus": 50, "Cancer": 45, "Capricorn": 45, "Scorpio": 40, "Virgo": 30],
    "Virgo": ["Taurus": 100, "Capricorn": 100, "Cancer": 75, "Scorpio": 75, "Virgo": 70, "Pisces": 70, "Libra": 50, "Leo": 50, "Gemini": 45, "Aquarius": 45, "Aries": 30, "Sagittarius": 30],
    "Libra": ["Gemini": 100, "Aquarius": 100, "Leo": 75, "Sagittarius": 75, "Libra": 70, "Aries": 70, "Pisces": 50, "Virgo": 50, "Taurus": 45, "Capricorn": 45, "Scorpio": 40, "Cancer": 30],
    "Scorpio": ["Cancer": 100, "Pisces": 100, "Virgo": 75, "Capricorn": 75, "Scorpio": 70, "Taurus": 70, "Libra": 50, "Leo": 50, "Gemini": 45, "Aquarius": 45, "Aries": 30, "Sagittarius": 30],
    "Sagittarius": ["Aries": 100, "Leo": 100, "Gemini": 75, "Aquarius": 75, "Sagittarius": 70, "Libra": 70, "Pisces": 50, "Virgo": 50, "Taurus": 45, "Capricorn": 45, "Cancer": 40, "Scorpio": 40],
    "Capricorn": ["Taurus": 100, "Virgo": 100, "Scorpio": 75, "Pisces": 75, "Capricorn": 70, "Cancer": 70, "Libra": 50, "Leo": 50, "Gemini": 45, "Aquarius": 45, "Aries": 30, "Sagittarius": 30],
    "Aquarius": ["Gemini": 100, "Libra": 100, "Aries": 75, "Sagittarius": 75, "Aquarius": 70, "Leo": 70, "Pisces": 50, "Virgo": 50, "Taurus": 45, "Capricorn": 45, "Cancer": 40, "Scorpio": 40],
    "Pisces": ["Cancer": 100, "Scorpio": 100, "Taurus": 75, "Capricorn": 75, "Pisces": 70, "Virgo": 70, "Libra": 50, "Leo": 50, "Gemini": 45, "Aquarius": 45, "Aries": 30, "Sagittarius": 30]
]

// Function to calculate matching score with weighted astrological compatibility
func calculateMatchScore(userData: [String: Any], matchData: [String: Any], userQuestionnaire: [String: String], matchQuestionnaire: [String: String]) -> Int {
    var score = 0
    
    // Age matching: +/- 3 years
    if let userAge = Int(userData["age"] as? String ?? ""),
       let matchAge = Int(matchData["age"] as? String ?? ""),
       abs(userAge - matchAge) <= 3 {
        score += 10
    }
    
    // Astrological sign compatibility using weighted map
    if let userSign = userData["astrologicalSign"] as? String,
       let matchSign = matchData["astrologicalSign"] as? String,
       let compatibilityScore = compatibilityMap[userSign]?[matchSign] {
        score += Int(compatibilityScore / 10) // Adjusting to scale compatibility score to match other scoring factors
    }
    
    // Matching major
    if let userMajor = userData["major"] as? String,
       let matchMajor = matchData["major"] as? String,
       userMajor == matchMajor {
        score += 10
    }
    
    // Matching schoolName
    if let userSchool = userData["schoolName"] as? String,
       let matchSchool = matchData["schoolName"] as? String,
       userSchool == matchSchool {
        score += 10
    }
    
    // Matching questionnaire answers
    for (question, userAnswer) in userQuestionnaire {
        if let matchAnswer = matchQuestionnaire[question], userAnswer == matchAnswer {
            score += 5
        }
    }

    return score
}


func findMatches(for userUID: String, completion: @escaping ([Match]) -> Void) {
    let db = Firestore.firestore()

    let userRef = db.collection("users").document(userUID)
    userRef.getDocument { (document, error) in
        guard let userData = document?.data(), error == nil else {
            print("Error fetching user data: \(String(describing: error))")
            return
        }

        // Fetch current user's questionnaire
        let userQuestionnaireRef = db.collection("questionnaires").document(userUID)
        userQuestionnaireRef.getDocument { (doc, err) in
            guard let userQuestionnaire = doc?.data() as? [String: String], err == nil else {
                print("Error fetching user questionnaire: \(String(describing: err))")
                return
            }

            // Fetch all other users
            db.collection("users").getDocuments { (snapshot, error) in
                guard let documents = snapshot?.documents, error == nil else {
                    print("Error fetching users: \(String(describing: error))")
                    return
                }

                var matches: [Match] = []
                var matchedData: [String: Int] = [:]  // Dictionary to store UID and match score
                let group = DispatchGroup()  // A dispatch group to handle async operations

                for document in documents {
                    let matchUID = document.documentID
                    if matchUID == userUID {
                        continue  // Skip matching with self
                    }

                    let matchData = document.data()

                    // Debug: Print all users being considered for a match
                    print("Considering user: \(matchUID), Name: \(matchData["firstName"] ?? "Unknown")")

                    // Enter the group before starting the async task
                    group.enter()

                    // Fetch questionnaire for each potential match
                    db.collection("questionnaires").document(matchUID).getDocument { (matchDoc, matchErr) in
                        defer { group.leave() }  // Ensure we leave the group after the task completes
                        
                        guard let matchQuestionnaire = matchDoc?.data() as? [String: String], matchErr == nil else {
                            print("Error fetching match questionnaire: \(String(describing: matchErr))")
                            return
                        }

                        let score = calculateMatchScore(userData: userData, matchData: matchData, userQuestionnaire: userQuestionnaire, matchQuestionnaire: matchQuestionnaire)

                        print("Considering user: \(matchUID), Name: \(matchData["firstName"] ?? "Unknown"), Score: \(score)")

                        if score > 50 {  // Threshold for match, adjust as necessary
                            let match = Match(uid: matchUID, score: score, matchData: matchData)
                            matches.append(match)

                            // Store the UID and score in the dictionary
                            matchedData[matchUID] = score

                            // Debug: Print match info to the console
                            print("Found match: \(matchUID), Score: \(score), Name: \(matchData["firstName"] ?? "Unknown")")
                        }
                    }
                }

                // Wait until all async operations are done
                group.notify(queue: .main) {
                    let numberOfMatches = matches.count
                    
                    // Update the user document with the number of matches and matched data (UID + score)
                    userRef.updateData([
                        "potentialMatches": numberOfMatches,
                        "matchedData": matchedData  // Store the UIDs and associated scores
                    ]) { err in
                        if let err = err {
                            print("Error updating potentialMatches: \(err)")
                        } else {
                            print("Successfully updated potentialMatches to \(numberOfMatches)")
                            // Debug: Print all matches for the current user
                            print("Matches for user \(userUID): \(matchedData)")
                            completion(matches)
                        }
                    }
                }
            }
        }
    }
}

func findBestMatch(for userUID: String, completion: @escaping (Match?) -> Void) {
    let db = Firestore.firestore()

    // Fetch the user's matched data (UIDs + scores) from Firestore
    let userRef = db.collection("users").document(userUID)
    userRef.getDocument { document, error in
        if let document = document, document.exists {
            if let matchedData = document.data()?["matchedData"] as? [String: Int], !matchedData.isEmpty {
                
                // Find the UID with the highest score
                if let bestMatchUID = matchedData.max(by: { a, b in a.value < b.value })?.key {
                    
                    // Fetch the best match's user data
                    let bestMatchRef = db.collection("users").document(bestMatchUID)
                    bestMatchRef.getDocument { matchDoc, matchError in
                        if let matchDoc = matchDoc, matchDoc.exists {
                            let matchData = matchDoc.data() ?? [:]
                            let score = matchedData[bestMatchUID] ?? 0
                            let bestMatch = Match(uid: bestMatchUID, score: score, matchData: matchData)
                            
                            // Return the best match
                            completion(bestMatch)
                        } else {
                            print("Error fetching best match data: \(String(describing: matchError))")
                            completion(nil)
                        }
                    }
                } else {
                    print("No matches found.")
                    completion(nil)
                }
            } else {
                print("No matched data found.")
                completion(nil)
            }
        } else {
            print("User document does not exist")
            completion(nil)
        }
    }
}

func findBestMatchAndPair(for userUID: String, completion: @escaping (Match?) -> Void) {
    let db = Firestore.firestore()

    // Fetch the user's matched data (UIDs + scores) from Firestore
    let userRef = db.collection("users").document(userUID)
    userRef.getDocument { document, error in
        if let document = document, document.exists {
            // Check if the user is already paired
            if let isPaired = document.data()?["isPaired"] as? Bool, isPaired {
                print("User is already paired.")
                completion(nil)
                return
            }
            
            if let matchedData = document.data()?["matchedData"] as? [String: Int], !matchedData.isEmpty {
                
                // Find the best match who is not already paired
                let bestMatchUID = matchedData
                    .filter { uid, _ in
                        // Filter out users who are already paired
                        let matchRef = db.collection("users").document(uid)
                        var isPaired = false
                        let group = DispatchGroup()
                        group.enter()
                        matchRef.getDocument { (matchDoc, matchError) in
                            if let matchDoc = matchDoc, matchDoc.exists {
                                isPaired = matchDoc.data()?["isPaired"] as? Bool ?? false
                            }
                            group.leave()
                        }
                        group.wait()
                        return !isPaired
                    }
                    .max(by: { a, b in a.value < b.value })?.key

                if let bestMatchUID = bestMatchUID {
                    // Fetch the best match's user data
                    let bestMatchRef = db.collection("users").document(bestMatchUID)
                    bestMatchRef.getDocument { matchDoc, matchError in
                        if let matchDoc = matchDoc, matchDoc.exists {
                            let matchData = matchDoc.data() ?? [:]
                            let score = matchedData[bestMatchUID] ?? 0
                            let bestMatch = Match(uid: bestMatchUID, score: score, matchData: matchData)

                            // Pair the two users
                            pairUsers(userUID: userUID, matchUID: bestMatchUID) { success in
                                if success {
                                    completion(bestMatch)
                                } else {
                                    completion(nil)
                                }
                            }
                        } else {
                            print("Error fetching best match data: \(String(describing: matchError))")
                            completion(nil)
                        }
                    }
                } else {
                    print("No matches found.")
                    completion(nil)
                }
            } else {
                print("No matched data found.")
                completion(nil)
            }
        } else {
            print("User document does not exist")
            completion(nil)
        }
    }
}

func pairUsers(userUID: String, matchUID: String, completion: @escaping (Bool) -> Void) {
    let db = Firestore.firestore()

    // Mark both users as paired and store each other's UID
    let userRef = db.collection("users").document(userUID)
    let matchRef = db.collection("users").document(matchUID)

    let batch = db.batch()
    
    batch.updateData([
        "isPaired": true,
        "currentMatchUID": matchUID
    ], forDocument: userRef)

    batch.updateData([
        "isPaired": true,
        "currentMatchUID": userUID
    ], forDocument: matchRef)

    batch.commit { error in
        if let error = error {
            print("Error pairing users: \(error)")
            completion(false)
        } else {
            print("Users \(userUID) and \(matchUID) successfully paired.")
            completion(true)
        }
    }
}

// Structure to hold match data
struct Match {
    let uid: String
    let score: Int
    let matchData: [String: Any]
}
