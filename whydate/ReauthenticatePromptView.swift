import SwiftUI
import FirebaseAuth

struct ReauthenticatePromptView: View {
    @Binding var isPresented: Bool
    @Binding var password: String
    var onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Secure Verification")
                .font(.headline)
            
            SecureField("Enter your password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .padding()
                
                Spacer()
                
                Button("Confirm") {
                    onConfirm()
                    isPresented = false
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 300, height: 150)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}
