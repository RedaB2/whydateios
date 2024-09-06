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

        // Get the gender of the current user
        guard let userGender = userData["gender"] as? String else {
            print("User gender not found")
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

                    // Get the gender of the potential match
                    guard let matchGender = matchData["gender"] as? String else {
                        print("Match gender not found")
                        continue
                    }

                    // Ensure gender compatibility: Male with Female, Other with Other
                    if (userGender == "Male" && matchGender != "Female") ||
                       (userGender == "Female" && matchGender != "Male") ||
                       (userGender == "Other" && matchGender != "Other") {
                        continue  // Skip this match if gender compatibility fails
                    }

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
        guard let document = document, document.exists else {
            print("User document does not exist")
            completion(nil)
            return
        }

        // Get the gender of the current user
        guard let userGender = document.data()?["gender"] as? String else {
            print("User gender not found")
            completion(nil)
            return
        }

        // Check if the user is already paired
        if let isPaired = document.data()?["isPaired"] as? Bool, isPaired {
            print("User is already paired.")
            completion(nil)
            return
        }

        // Fetch matched data (UIDs + scores)
        if let matchedData = document.data()?["matchedData"] as? [String: Int], !matchedData.isEmpty {
            var availableMatches: [(uid: String, score: Int)] = []
            let dispatchGroup = DispatchGroup()

            for (matchUID, score) in matchedData {
                dispatchGroup.enter()

                // Fetch match user data
                let matchRef = db.collection("users").document(matchUID)
                matchRef.getDocument { matchDoc, error in
                    if let matchDoc = matchDoc, matchDoc.exists {
                        let isPaired = matchDoc.data()?["isPaired"] as? Bool ?? false
                        let matchGender = matchDoc.data()?["gender"] as? String ?? ""
                        
                        // Ensure gender compatibility
                        if !isPaired && (
                            (userGender == "Male" && matchGender == "Female") ||
                            (userGender == "Female" && matchGender == "Male") ||
                            (userGender == "Other" && matchGender == "Other")
                        ) {
                            availableMatches.append((uid: matchUID, score: score))
                        }
                    }
                    dispatchGroup.leave()
                }
            }

            // After all async operations are completed
            dispatchGroup.notify(queue: .main) {
                if let bestMatch = availableMatches.max(by: { $0.score < $1.score }) {
                    // Fetch the best match's user data
                    let bestMatchRef = db.collection("users").document(bestMatch.uid)
                    bestMatchRef.getDocument { matchDoc, error in
                        if let matchDoc = matchDoc, matchDoc.exists {
                            let matchData = matchDoc.data() ?? [:]
                            let bestMatch = Match(uid: bestMatch.uid, score: bestMatch.score, matchData: matchData)

                            // Pair the two users
                            pairUsers(userUID: userUID, matchUID: bestMatch.uid) { success in
                                if success {
                                    completion(bestMatch)
                                } else {
                                    completion(nil)
                                }
                            }
                        } else {
                            print("Error fetching best match data: \(String(describing: error))")
                            completion(nil)
                        }
                    }
                } else {
                    print("No available matches found.")
                    completion(nil)
                }
            }
        } else {
            print("No matched data found.")
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
        "currentMatchUID": matchUID,
        "isProfileRevealed": false
    ], forDocument: userRef)

    batch.updateData([
        "isPaired": true,
        "currentMatchUID": userUID,
        "isProfileRevealed": false
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

func fetchCurrentMatchFirstName(for userUID: String, completion: @escaping (String?) -> Void) {
    let db = Firestore.firestore()
    let userRef = db.collection("users").document(userUID)

    // Fetch the user's document to get the currentMatchUID
    userRef.getDocument { (document, error) in
        if let document = document, document.exists {
            // Retrieve the currentMatchUID
            if let currentMatchUID = document.data()?["currentMatchUID"] as? String {
                // Now fetch the matched user's first name using the currentMatchUID
                let matchRef = db.collection("users").document(currentMatchUID)
                matchRef.getDocument { (matchDoc, matchError) in
                    if let matchDoc = matchDoc, matchDoc.exists {
                        let firstName = matchDoc.data()?["firstName"] as? String ?? "Unknown"
                        completion(firstName)  // Return the first name of the match
                    } else {
                        print("Error fetching match's first name: \(String(describing: matchError))")
                        completion(nil)  // Return nil if there was an error fetching the match data
                    }
                }
            } else {
                print("No current match found for user \(userUID)")
                completion(nil)  // Return nil if no currentMatchUID exists
            }
        } else {
            print("Error fetching user data: \(String(describing: error))")
            completion(nil)  // Return nil if the user document doesn't exist
        }
    }
}

func fetchIsPaired(for userUID: String, completion: @escaping (Bool) -> Void) {
    let db = Firestore.firestore()
    let userRef = db.collection("users").document(userUID)

    userRef.getDocument { (document, error) in
        if let document = document, document.exists {
            let isPaired = document.data()?["isPaired"] as? Bool ?? false
            completion(isPaired)
        } else {
            print("Error fetching isPaired status: \(String(describing: error))")
            completion(false)  // Default to false if there's an error or the document doesn't exist
        }
    }
}

// Structure to hold match data
struct Match {
    let uid: String
    let score: Int
    let matchData: [String: Any]
}
