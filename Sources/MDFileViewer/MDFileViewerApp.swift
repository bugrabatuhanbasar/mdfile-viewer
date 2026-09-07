import SwiftUI

@main
struct MDFileViewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ContentView(document: file.document)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
