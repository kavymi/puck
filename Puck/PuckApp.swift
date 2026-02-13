import SwiftUI

@main
struct PuckApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 780, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
