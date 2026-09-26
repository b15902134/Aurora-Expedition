import SwiftUI

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.custom("BoldPixels", size: 16, relativeTo: .body))
                .environment(\.locale, Locale(identifier: "en-US"))
        }
    }
}
