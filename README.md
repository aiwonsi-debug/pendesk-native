# PenDesk Native

A native Debian/X11 prototype for the PenDesk stylus-first desktop. The project uses Rust, Qt 6/QML, and CXX-Qt. It currently demonstrates the target Daily Desk composition and a Rust-backed QObject that QML uses for workspace, pen-tool, and palm-rest state.

## Prerequisites

On Debian or Ubuntu, install Rust, a C++ compiler, `pkg-config`, and Qt 6 development packages including `qt6-base-dev` and `qt6-declarative-dev`. CXX-Qt resolves Qt through `qmake`; set `QMAKE` explicitly if `qmake6` is not the default executable.

## Run

```bash
QMAKE=/usr/bin/qmake6 cargo run
```

## Project structure

| Path | Purpose |
| --- | --- |
| `src/desktop_state.rs` | Rust-owned QObject state exposed to QML through CXX-Qt. |
| `src/main.rs` | Native Qt application launcher. |
| `qml/Main.qml` | Reference-driven Daily Desk visual shell. |
| `qml/InkSurface.qml` | Interactive preview surface with QML-side sample coalescing and a custom shader-backed ink layer. |
| `qml/shaders/ink_smooth.frag.qsb` | Build-time compiled Qt 6 shader package, embedded through `resources.qrc`. |
| `build.rs` | Packages the QML module and invokes CXX-Qt code generation. |
| `ARCHITECTURE.md` | Module boundaries and the migration plan. |

## Next implementation milestones

Connect tablet events to the Rust drawing model; add filesystem-backed recent work; and replace the static recent-work records with Rust models. The intended production packaging target is a Debian package with an X11 session entry, not a browser application.
