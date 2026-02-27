import SwiftUI

@main
struct PluckApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
