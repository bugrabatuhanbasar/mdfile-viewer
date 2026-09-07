# MDFile Viewer

A tiny, native macOS app for previewing Markdown files. Double-click any `.md` in Finder and get a clean, readable render with a table-of-contents sidebar, syntax-highlighted code, and an automatic light/dark theme that follows the system.

No Electron. No background daemons. One small SwiftUI app that opens documents like Preview does for PDFs.

## Features

- **GitHub-flavored Markdown** — tables, task lists, strikethrough, fenced code blocks
- **Syntax highlighting** for code blocks via bundled [highlight.js](https://highlightjs.org/) (offline, no network)
- **Table-of-contents sidebar** built from the document's headings; click to jump
- **Scroll-spy** — the sidebar highlights (and follows) the section you're currently reading
- **Light / Dark / System appearance** with a persistent toggle in the toolbar; both the sidebar and the rendered content update together
- **In-document anchor links** (`[Section](#section)`) scroll instead of prompting to open a file, with fuzzy matching for author-generated slugs (GitHub-style, Pandoc, Hugo, …)
- **External links** (http/https/mailto) open in your default browser
- **Read-only** — never modifies your file
- **Custom app icon** — the purple document icon shows up in Finder, the Dock, and the *Open With* menu
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
- **Jump to a heading:** click any entry in the sidebar table of contents.
- **Toggle the sidebar:** the sidebar icon in the toolbar (top-left).
- **Change appearance:** the sun/moon icon in the toolbar (top-right) — pick System, Light, or Dark. The choice is remembered.
- **Follow a link:** in-document `#anchor` links scroll to the heading; web links open in your default browser.
- **Resize the split:** drag the divider between the sidebar and content.

## Project layout

```
mdfile-viewer/
├── Package.swift               # SwiftPM manifest (depends on apple/swift-markdown)
├── Sources/MDFileViewer/
│   ├── MDFileViewerApp.swift   # @main, DocumentGroup scene, default window size
│   ├── MarkdownDocument.swift  # Read-only FileDocument for .md
│   ├── ContentView.swift       # HSplitView: TOC sidebar + WebView, appearance menu
│   ├── MarkdownRenderer.swift  # swift-markdown AST → HTML + GitHub-compatible slugs
│   ├── MarkdownWebView.swift   # WKWebView wrapper, scroll-spy, anchor + external link handling, theme injection
│   ├── HTMLTemplate.swift      # Loads Resources/template.html
│   └── Resources/
│       ├── template.html       # Wraps rendered HTML, wires theme + highlight.js
│       ├── styles.css          # GitHub-like theme, light + dark variants (data-theme aware)
│       └── highlight/          # highlight.min.js + github / github-dark themes
├── assets/
│   └── AppIcon.png             # 1024×1024 icon source (flattened, opaque)
├── scripts/
│   ├── Info.plist              # Bundle metadata + .md UTI declaration
│   └── build-app.sh            # Compile, generate .icns, assemble .app, ad-hoc codesign, optional install
├── test-fixtures/
│   └── sample.md               # Rich sample covering all supported features
└── README.md
```

## Customization

- **App icon:** replace `assets/AppIcon.png` with any square PNG (1024×1024 recommended). The build script regenerates `.icns` at every build. For best results the PNG should be opaque — transparent corners can cause a white halo in some macOS contexts.
- **App name / bundle id:** edit `scripts/Info.plist` (`CFBundleName`, `CFBundleDisplayName`, `CFBundleIdentifier`). Match the executable name in `scripts/build-app.sh` if you rename it.
- **Theme colors:** `Sources/MDFileViewer/Resources/styles.css` — CSS variables are declared at the top for both light and dark schemes.
- **Highlight theme:** swap the two files under `Resources/highlight/` for any other pair of themes from the [highlight.js CDN](https://cdnjs.com/libraries/highlight.js) and keep the same filenames.
- **Additional file extensions:** add them to `UTImportedTypeDeclarations` → `public.filename-extension` in `scripts/Info.plist`.
- **Default window size / minimum size:** `Sources/MDFileViewer/MDFileViewerApp.swift` — `.defaultSize` and the `.frame(minWidth:minHeight:)` on `ContentView`.

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

- Print / Export to PDF
- Configurable font size / max content width
- Diagrams (Mermaid) and math (KaTeX) rendered inline
- Front-matter (YAML/TOML) rendered as a metadata card
- Search / find-in-document
- Universal binary + notarization workflow, signed release DMG

## License

[PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0) — see [LICENSE](LICENSE).

You are free to use, modify, and share this software for any **non-commercial** purpose: personal use, hobby projects, education, research, and use inside non-profit, charitable, or government organizations. **Selling this software, or any product/service whose value depends on it, is not permitted.** For a commercial license, contact the author (see below).

## Author & Contact

Maintained by Batuhan Başar — [batuhanbsr.60@gmail.com](mailto:batuhanbsr.60@gmail.com).

- **Bugs & feature requests:** open an issue on GitHub.
- **Commercial licensing:** email the address above.
- **General questions / contributions:** either an issue or an email works.
