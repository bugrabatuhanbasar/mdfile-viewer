import SwiftUI

@main
struct MDFileViewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ContentView(document: file.document)
                .frame(minWidth: 720, minHeight: 480)
        }
        .defaultSize(width: 1180, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .textEditing) {
                Section {
                    Button("Find…") {
                        NotificationCenter.default.post(name: .mdToggleFind, object: nil)
                    }
                    .keyboardShortcut("f", modifiers: .command)

                    Button("Find Next") {
                        NotificationCenter.default.post(name: .mdFindNext, object: nil)
                    }
                    .keyboardShortcut("g", modifiers: .command)

                    Button("Find Previous") {
                        NotificationCenter.default.post(name: .mdFindPrevious, object: nil)
                    }
                    .keyboardShortcut("g", modifiers: [.command, .shift])
                }
            }
        }
    }
}
