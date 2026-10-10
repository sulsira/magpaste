# Contributing to Magpaste

Magpaste is a clipboard app for macOS only. This guide adapts the contribution flow from [sulsira/scratchy](https://github.com/sulsira/scratchy/blob/main/CONTRIBUTING.md) to a Swift and SwiftUI project.

## Table of Contents

- [How can I contribute?](#how-can-i-contribute)
- [Development setup](#development-setup)
- [Making changes](#making-changes)
- [Testing](#testing)
- [Pull request process](#pull-request-process)
- [Reporting bugs](#reporting-bugs)
- [Suggesting enhancements](#suggesting-enhancements)
- [Code style](#code-style)
- [Commit message guidelines](#commit-message-guidelines)
- [Getting help](#getting-help)

## How can I contribute?

1. **Report a bug.** Use the bug template below. Include steps, macOS version, and the app version.
2. **Suggest a feature.** Use the enhancement template below. Say what problem it solves.
3. **Send a pull request.** Fork the repo, branch, change, test, open the PR.

Good first contributions are listed under **Known gaps** and **Roadmap** in `README.md`:
- A unit test target for `ClipboardMonitor` classification and the stores.
- Image and file clips.
- Ignore-list UI and retention settings.
- Handlers for the `⌘1` to `⌘9` card labels.

## Development setup

### Prerequisites

- A Mac running macOS 14.0 or later.
- Xcode with Swift 5 (license accepted).
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen) to regenerate the project from `Magpaste/project.yml`.

### Installation

1. Fork and clone the repo:
   ```bash
   git clone https://github.com/<your-username>/magpaste.git
   cd magpaste
   ```
2. Open `Magpaste/Magpaste.xcodeproj` in Xcode.
3. Pick the **Magpaste** scheme and **My Mac**.
4. In **Signing & Capabilities**, choose your own Team.

### Running the app

1. Press **Run (`⌘R`)**.
2. Look for the clipboard icon in the menu bar. There is no Dock icon.
3. Grant **System Settings → Privacy & Security → Accessibility** to `Magpaste` so paste works.
4. Copy some text, then press the global shortcut (default in `KeyCombo.swift`).

## Making changes

### Project structure

```
magpaste/
├── Magpaste/
│   ├── MagpasteApp.swift        # App entry, menu bar
│   ├── ClipboardMonitor.swift   # Pasteboard polling, history
│   ├── ContentView.swift        # Search, sections, card grid
│   ├── HistoryPanel.swift       # Docked panel window
│   ├── PasteExecutor.swift      # Paste into the previous app
│   ├── project.yml              # XcodeGen config
│   └── Magpaste.xcodeproj
├── README.md
└── CONTRIBUTING.md
```

### Key files to modify

- `ClipboardMonitor.swift`: what gets captured and how it is classified.
- `ContentView.swift` and `ClipboardItemCard.swift`: the UI.
- `project.yml`: build settings. After editing, run `xcodegen` inside `Magpaste/`.
- `README.md`: docs for any user-visible change.

## Testing

### Build check

1. Run from the repo root:
   ```bash
   xcodebuild -project Magpaste/Magpaste.xcodeproj -scheme Magpaste -configuration Debug -derivedDataPath build/dd build CODE_SIGNING_ALLOWED=NO
   ```
2. Expect `** BUILD SUCCEEDED **`.

### Type check without Xcode

1. Run inside `Magpaste/`:
   ```bash
   swiftc -typecheck -target arm64-apple-macos14.0 *.swift
   ```
2. The only expected error is the `#Preview` macro. Any other error is real.

### Manual checklist

The project has no automated test target yet. Before opening a PR, run the manual checklist in the **Test** section of `README.md`.

### Writing tests

1. Add an XCTest target to `project.yml` if none exists.
2. Put tests in `MagpasteTests/`.
3. Test success and failure paths. Test edge cases such as empty strings and duplicates.

## Pull request process

1. **Create a feature branch.** Branch from `main`. Use names like `feature/image-clips` or `fix/duplicate-clip`.
2. **Make your changes.** Follow the code style below. Add tests for new behavior. Update `README.md` if users see the change.
3. **Test your changes.** Run the build check. Run the manual checklist for the area you touched.
4. **Open the PR.** Describe what changed and why. Link related issues. Add a screenshot or short recording for UI changes.
5. **Review.** Address comments. A maintainer merges when approved.

## Reporting bugs

### Before submitting

1. Check existing issues for duplicates.
2. Reproduce on a clean launch.
3. Note your macOS version and Magpaste version.

### Bug report template

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To reproduce**
1. Launch Magpaste
2. Copy '...'
3. Press the shortcut
4. See error

**Expected behavior**
What you expected to happen.

**Environment**
- macOS version: [e.g. 14.5]
- Mac: [e.g. Apple silicon, Intel]
- Magpaste version: [e.g. 1.0]

**Additional context**
Screenshots or logs. Do not paste real clipboard content that is private.
```

## Suggesting enhancements

### Enhancement request template

```markdown
**Is your feature request related to a problem?**
A clear and concise description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Other solutions you thought about.

**Additional context**
Screenshots or mockups.
```

## Code style

### Swift guidelines

1. Follow the style of the surrounding code.
2. Prefer early returns and guard clauses over `else`.
3. Keep functions shallow, under 3 levels of nesting.
4. Prefer small functions and value types over class hierarchies.
5. Use `let` over `var`.
6. Use meaningful names. Assign to a named constant before using a value inline.
7. Add `///` doc comments for non-obvious types and functions.

### macOS app guidelines

1. Keep the app menu-bar only (`LSUIElement` stays `true`).
2. Never capture clips from password managers. Extend `excludedBundleIDs` in `ClipboardMonitor.swift` when adding a source.
3. Do not add network calls. Clipboard data must stay on the device.
4. Handle errors without crashing the menu-bar app.

### File naming

1. One main type per file, named after the type, in PascalCase (`ClipboardMonitor.swift`).
2. PascalCase for types. camelCase for variables and functions.

## Commit message guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- `feat`: a new feature
- `fix`: a bug fix
- `docs`: documentation only
- `style`: formatting, no meaning change
- `refactor`: neither a fix nor a feature
- `perf`: a performance improvement
- `test`: adding or correcting tests
- `chore`: build process or tooling

### Examples

```
feat: add image clip support
fix: skip duplicate clip after re-copy
docs: add build and test section to README
test: add classification tests for hex colors
```

## Getting help

1. Check existing issues and discussions.
2. Open a GitHub Discussion or an issue with the question label.
3. Read the Apple docs for `NSPasteboard` and SwiftUI.

## Recognition

Contributors are credited in:
- Release notes.
- The GitHub contributors page.

Thank you for contributing to Magpaste.
