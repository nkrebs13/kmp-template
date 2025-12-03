import SwiftUI
import shared

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, Kotlin Multiplatform!")
                .font(.title)
                .padding()
            
            Text("iOS App")
                .font(.headline)
                .padding()
            
            Text("This iOS app is part of a Kotlin Multiplatform project")
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Built with:")
                    .font(.headline)
                
                Text("✓ Kotlin Multiplatform")
                Text("✓ SwiftUI for iOS")
                Text("✓ Shared business logic")
                Text("✓ Native iOS experience")
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}