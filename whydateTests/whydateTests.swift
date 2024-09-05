import XCTest
@testable import whydate

final class whydateTests: XCTestCase {
    
    var matchingAlgorithm: MatchingAlgorithm!

    override func setUpWithError() throws {
        super.setUp()
        // Initialize the matching algorithm before each test
        matchingAlgorithm = MatchingAlgorithm()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        matchingAlgorithm = nil
        super.tearDown()
    }

    func testMatchingAlgorithm() throws {
        // Create mock users
        let user1 = MockUser(uid: "user1", questionnaireAnswers: ["q1": "Yes", "q2": "No"], astrologicalSign: "Aries", age: "25")
        let user2 = MockUser(uid: "user2", questionnaireAnswers: ["q1": "Yes", "q2": "Yes"], astrologicalSign: "Leo", age: "23")
        let user3 = MockUser(uid: "user3", questionnaireAnswers: ["q1": "No", "q2": "Yes"], astrologicalSign: "Taurus", age: "29")

        // Calculate match scores for the users
        let matchResult1 = matchingAlgorithm.calculateMatchScoreLocally(user1: user1, user2: user2)
        let matchResult2 = matchingAlgorithm.calculateMatchScoreLocally(user1: user1, user2: user3)
        
        // Assertions to verify the results
        XCTAssertGreaterThan(matchResult1.score, 0, "User1 and User2 should have a positive match score")
        XCTAssertGreaterThan(matchResult2.score, 0, "User1 and User3 should have a positive match score")
        XCTAssertNotEqual(matchResult1.score, matchResult2.score, "The match scores should be different")
        
        // Test if the match results are sorted correctly
        XCTAssertTrue(matchResult1.score > matchResult2.score, "User1 and User2 should have a higher match score than User1 and User3")
    }

    // Example of a performance test for the matching algorithm
    func testPerformanceExample() throws {
        self.measure {
            // Measure time taken for the algorithm to calculate scores
            let user1 = MockUser(uid: "user1", questionnaireAnswers: ["q1": "Yes", "q2": "No"], astrologicalSign: "Aries", age: "25")
            let user2 = MockUser(uid: "user2", questionnaireAnswers: ["q1": "Yes", "q2": "Yes"], astrologicalSign: "Leo", age: "23")
            _ = matchingAlgorithm.calculateMatchScoreLocally(user1: user1, user2: user2)
        }
    }
}

// MockUser struct for testing purposes
struct MockUser {
    let uid: String
    let questionnaireAnswers: [String: String]
    let astrologicalSign: String
    let age: String
}

// Add a local version of calculateMatchScore
extension MatchingAlgorithm {
    func calculateMatchScoreLocally(user1: MockUser, user2: MockUser) -> MatchResult {
        let questionnaireScore = calculateQuestionnaireSimilarity(userAnswers: user1.questionnaireAnswers, otherAnswers: user2.questionnaireAnswers)
        let astrologicalScore = calculateAstrologicalCompatibility(sign1: user1.astrologicalSign, sign2: user2.astrologicalSign)
        let ageScore = calculateAgeScore(age1: user1.age, age2: user2.age)
        
        let finalScore = (0.5 * questionnaireScore) + (0.3 * astrologicalScore) + (0.2 * ageScore)
        return MatchResult(uid: user2.uid, score: finalScore)
    }
}
