import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack {
            Image("WhyDate")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
            Text("Rethink Dating")
                .font(.custom("Comfortaa", size: 25))
                .multilineTextAlignment(.center)
                .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // Customize background color as needed
        .edgesIgnoringSafeArea(.all)
    }
}
