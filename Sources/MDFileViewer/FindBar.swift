import SwiftUI

struct FindBar: View {
    @ObservedObject var controller: FindController
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 12, weight: .semibold))

            TextField("Find in document", text: $controller.query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($focused)
                .onSubmit { controller.findNext() }
                .onChange(of: controller.query) { _, newValue in
                    guard !newValue.isEmpty else {
                        controller.lastResultFound = nil
                        return
                    }
                    controller.findNext()
                }
                .frame(minWidth: 200)

            if let found = controller.lastResultFound, !controller.query.isEmpty {
                Text(found ? "" : "Not found")
                    .font(.system(size: 11))
                    .foregroundStyle(found ? .secondary : Color.red.opacity(0.85))
                    .lineLimit(1)
            }

            Divider().frame(height: 16)

            Button {
                controller.findPrevious()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Previous match (⇧⏎)")
            .keyboardShortcut(.return, modifiers: .shift)

            Button {
                controller.findNext()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Next match (⏎)")

            Button {
                controller.close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Close (⎋)")
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .frame(maxWidth: 420)
        .onAppear { focused = true }
        .onChange(of: controller.isVisible) { _, visible in
            focused = visible
        }
    }
}
