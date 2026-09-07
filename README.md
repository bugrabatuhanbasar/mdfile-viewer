# MDFile Viewer

A tiny, native macOS app for previewing Markdown files. Double-click any `.md` in Finder and get a clean, readable render with a table-of-contents sidebar, syntax-highlighted code, and an automatic light/dark theme that follows the system.

No Electron. No background daemons. One small SwiftUI app that opens documents like Preview does for PDFs.

## Features

- **GitHub-flavored Markdown** — tables, task lists, strikethrough, fenced code blocks
- **Syntax highlighting** for code blocks via bundled [highlight.js](https://highlightjs.org/) (offline, no network)
- **Auto light/dark theme** that follows the system appearance
- **Table-of-contents sidebar** built from the document's headings; click to jump
- **In-document anchor links** (`[Section](#section)`) scroll instead of prompting to open a file
- **External links** (http/https/mailto) open in your default browser
- **Read-only** — never modifies your file
- **Native `.app` bundle** — appears in Finder's *Open With* menu, can be set as the default handler for `.md`

## Requirements

- macOS 14 (Sonoma) or newer
- Xcode 15+ with the Swift 5.9+ toolchain (`swift --version`)

Only needed to build. Once you have the `.app`, no dev tools are required to run it.

## Install (from source)

```bash
git clone https://github.com/<your-username>/mdfile-viewer.git
cd mdfile-viewer
./scripts/build-app.sh --install
```

The `--install` flag builds the app **and** copies it to `/Applications`, then re-registers it with Launch Services so Finder picks it up right away.

To build without installing:

```bash
./scripts/build-app.sh
# → build/MDFileViewer.app
```

You can then drag `build/MDFileViewer.app` anywhere you like (e.g. `/Applications` or `~/Applications`).

### First launch (Gatekeeper)

The app is ad-hoc signed, not notarized. On first launch macOS may say *"MDFileViewer can't be opened because Apple cannot check it for malicious software."* Two ways to allow it:

- **System Settings → Privacy & Security** → scroll down → **Open Anyway**, or
- In Terminal: `xattr -dr com.apple.quarantine /Applications/MDFileViewer.app`

## Set as the default `.md` viewer

1. In Finder, right-click any `.md` file → **Get Info** (or press <kbd>⌘</kbd><kbd>I</kbd>).
2. Under **Open with**, choose **MDFileViewer**.
3. Click **Change All…** to apply to every `.md` file.

From then on, double-clicking any `.md` file opens it in MDFile Viewer.

## Usage

- **Open a file:** double-click in Finder, or `File → Open…` in the app.
- **Jump to a heading:** click an entry in the sidebar.
- **Toggle the sidebar:** the sidebar icon in the toolbar.
- **Follow a link:** in-document (`#anchor`) links scroll; web links open in your default browser.

## Project layout

```
mdfile-viewer/
├── Package.swift               # SwiftPM manifest (depends on apple/swift-markdown)
├── Sources/MDFileViewer/
│   ├── MDFileViewerApp.swift   # @main, DocumentGroup scene
│   ├── MarkdownDocument.swift  # Read-only FileDocument for .md
│   ├── ContentView.swift       # NavigationSplitView with TOC + WebView
│   ├── MarkdownRenderer.swift  # swift-markdown AST → HTML + TOC extraction
│   ├── MarkdownWebView.swift   # WKWebView wrapper, anchor + external link handling
│   ├── HTMLTemplate.swift      # Loads Resources/template.html
│   └── Resources/
│       ├── template.html
│       ├── styles.css          # GitHub-like theme, light/dark variants
│       └── highlight/          # highlight.min.js + github(-dark) themes
├── scripts/
│   ├── Info.plist              # Bundle metadata + .md UTI declaration
│   └── build-app.sh            # Compile, assemble .app, ad-hoc codesign, optional install
├── test-fixtures/
│   └── sample.md               # Rich sample covering all supported features
└── README.md
```

## Customization

- **App name / bundle id:** edit `scripts/Info.plist` (`CFBundleName`, `CFBundleDisplayName`, `CFBundleIdentifier`). Match the executable name in `scripts/build-app.sh` if you rename it.
- **Theme colors:** `Sources/MDFileViewer/Resources/styles.css` — CSS variables are declared at the top for both light and dark schemes.
- **Highlight theme:** swap the two files under `Resources/highlight/` for any other pair of themes from the [highlight.js CDN](https://cdnjs.com/libraries/highlight.js) and keep the same filenames.
- **Additional file extensions:** add them to `UTImportedTypeDeclarations` → `public.filename-extension` in `scripts/Info.plist`.

## Development

Run in-place without bundling:

```bash
swift run MDFileViewer
```

Note: `swift run` produces a bare executable that doesn't behave like a proper document app (no `.md` association, resources are loaded from the runtime bundle differently). For anything beyond a smoke test, use `./scripts/build-app.sh` and launch the `.app`.

## Dependencies

- [apple/swift-markdown](https://github.com/apple/swift-markdown) — Markdown parser (CommonMark + GFM), Apache 2.0
- [highlight.js](https://github.com/highlightjs/highlight.js) — code syntax highlighting, BSD-3-Clause (bundled files under `Resources/highlight/`)

## Contributing

Issues and pull requests are welcome. Some ideas that would make good first contributions:

- Custom app icon (`.icns`) shipped in `Resources/`
- Print / Export to PDF
- Configurable font size / max content width
- Diagrams (Mermaid, KaTeX) rendered inline
- Universal binary + notarization workflow

## License

[PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0) — see [LICENSE](LICENSE).

You are free to use, modify, and share this software for any **non-commercial** purpose: personal use, hobby projects, education, research, and use inside non-profit, charitable, or government organizations. **Selling this software, or any product/service whose value depends on it, is not permitted.** For a commercial license, contact the author.
