# PenDesk native architecture

PenDesk uses **Rust for state and services** and **Qt 6/QML for the desktop presentation layer**. CXX-Qt generates the QObject bridge, so QML can call Rust invokables and bind to Rust-backed properties without passing mutable application state through QML JavaScript.

| Layer | Technology | Responsibility |
| --- | --- | --- |
| Presentation | Qt 6 / QML | Daily Desk layout, task tiles, visuals, navigation, stylus dock, animations, accessibility labels. |
| UI bridge | CXX-Qt | Generates the Qt QObject that exposes Rust properties and invokable methods to QML. |
| Application core | Rust | Workspace state, active pen tool, palm-rest state, files, worksheet model, clipart library, search, and future persistence. |
| Platform adapters | Rust with focused Qt/X11 calls | Tablet/XInput events, window/session behavior, Debian packaging, D-Bus services, and file-system integration. |

The initial `DesktopState` QObject is intentionally small. Its `workspace`, `selectedTool`, and `palmRest` properties prove the QML-to-Rust route. The next iteration should split persistence, asset indexing, worksheets, and tablet input into normal Rust modules; the QObject should remain a narrow presentation-facing adapter.

The project follows the Cargo-only CXX-Qt approach because the official CXX-Qt documentation describes it as the simpler starting point. The build script packages `qml/Main.qml` as the `org.pendesk.desktop` module and links the Qt Quick Controls library. [1]

## References

[1]: https://kdab.github.io/cxx-qt/book/getting-started/4-cargo-executable.html "CXX-Qt Documentation: Building with Cargo"
