import SwiftUI
import FirebaseFirestore

struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    var senderUID: String
    var recipientUID: String // Add recipient UID
    var messageText: String
    var timestamp: Date
}

// MessageView for displaying individual messages
struct MessageView: View {
    let message: Message
    let isSentByCurrentUser: Bool

    var body: some View {
        HStack {
            if isSentByCurrentUser {
                Spacer()
                Text(message.messageText)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text(message.messageText) 
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(10)
                Spacer()
            }
        }
        .padding(isSentByCurrentUser ? .leading : .trailing, 50)
        .padding(.vertical, 5)
    }
}


// ChatView to handle the chat between two users
struct ChatView: View {
    let userUID: String
    let matchUID: String
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isProfileViewPresented = false
    @StateObject private var matchProfileViewModel = OtherUserProfileViewModel() // Use the new view model for viewing match profile

    var body: some View {
        VStack {
            HStack {
                // Display the name of the user you're chatting with
                Text(matchProfileViewModel.firstName)
                    .font(.title)
                    .bold()

                Spacer()

                // Info button that navigates to the OtherUserProfileView of the match
                Button(action: {
                    isProfileViewPresented = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $isProfileViewPresented) {
                    // Present OtherUserProfileView
                    OtherUserProfileView(viewModel: matchProfileViewModel, uid: matchUID)
                }
            }
            .padding()

            // Chat message list
            ScrollView {
                ForEach(messages, id: \.id) { message in
                    MessageView(message: message, isSentByCurrentUser: message.senderUID == userUID)
                }
            }

            // Message input and send button
            HStack {
                TextField("Enter message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    sendMessage() // Call sendMessage when the "Send" button is pressed
                }) {
                    Text("Send")
                        .padding()
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
        }
        .onAppear {
            matchProfileViewModel.fetchOtherUserProfile(uid: matchUID) // Fetch the matched user's profile data
            matchProfileViewModel.fetchOtherUserPhotos(uid: matchUID) // Fetch the matched user's photos
            fetchMessages() // Fetch previous chat messages
        }
    }

    // Send message function
    func sendMessage() {
        let trimmedMessageText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedMessageText.isEmpty else {
            return // Don't send empty messages
        }

        let db = Firestore.firestore()
        let conversationID = generateConversationID(userUID: userUID, matchUID: matchUID)
        
        // Create the new message with the recipientUID
        let newMessage = Message(
            id: UUID().uuidString,
            senderUID: userUID,
            recipientUID: matchUID,  // Include the recipient UID
            messageText: trimmedMessageText,
            timestamp: Date()
        )

        do {
            try db.collection("conversations")
                .document(conversationID)
                .collection("messages")
                .document(newMessage.id!)
                .setData(from: newMessage)
        } catch {
            print("Error sending message: \(error)")
        }

        messageText = "" // Clear the message input field after sending
    }

    // Function to fetch previous messages from Firestore
    func fetchMessages() {
        let db = Firestore.firestore()
        let conversationID = generateConversationID(userUID: userUID, matchUID: matchUID)

        db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.messages = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
            }
    }

    // Function to generate the conversation ID based on the UIDs of the two users
    func generateConversationID(userUID: String, matchUID: String) -> String {
        return userUID < matchUID ? "\(userUID)_\(matchUID)" : "\(matchUID)_\(userUID)"
    }
}

// MessagingView to handle pairing status and start the chat
struct MessagingView: View {
    @State private var isPaired = false
    @State private var matchUID: String?
    @State private var loading = true
    let userUID: String

    var body: some View {
        VStack {
            if loading {
                ProgressView("Checking pairing status...")
            } else if isPaired, let matchUID = matchUID {
                ChatView(userUID: userUID, matchUID: matchUID)
            } else {
                Text("We are working on finding a match for you. Please check back later.")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .onAppear {
            checkPairedStatus(for: userUID)
        }
    }

    // Function to check pairing status
    func checkPairedStatus(for userUID: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userUID)

        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let isPaired = document.data()?["isPaired"] as? Bool, isPaired {
                    self.isPaired = true
                    self.matchUID = document.data()?["currentMatchUID"] as? String
                } else {
                    self.isPaired = false
                }
            }
            self.loading = false
        }
    }
}
