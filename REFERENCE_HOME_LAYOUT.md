# Supplied-reference home workspace

The supplied stylus desktop image is the ground-truth visual specification for PenDesk’s native home workspace. The QML implementation follows its navy left rail, roomy warm-white content canvas, right-aligned connection and system status, oversized three-task launch tiles, recent-work strip, and fixed pastel pen-tool dock.

The home screen is intentionally a **return point**, not the primary writing surface. Choosing **New Worksheet** opens the existing US Letter portrait pen-display workspace; choosing Browse or Create Clipart opens its respective native route. This keeps the supplied reference’s daily-desk clarity while retaining the user’s Letter-first worksheet priority.

| Reference element | Native QML interpretation |
| --- | --- |
| Navy rail with three large navigation tiles | Fixed landscape rail and compact portrait workspace switcher |
| Good-morning daily desk | Daily route greeting and action hierarchy |
| Three illustrated entry tiles | Browse, New Worksheet, and Create Clipart actions with native vector-like glyphs |
| Recent-work strip | Three locally rendered recent-work previews, without fabricated reviews or user claims |
| Pastel full-width pen dock | Persistent Pen, Eraser, Undo, Redo, and Palm Rest controls |

## Visual validation

The native daily route was rendered at the supplied reference size of 2560×1440. The final capture fills the display geometry, keeps the reference-derived three-task row and three-item recent-work strip in a single landscape row, preserves the navy navigation rail, and keeps the five-tool pastel dock fixed at the bottom. The session started without QML or shader-loading errors.

The New Worksheet tile was exercised with an X11 click at the 2560×1440 native scale. It changed the Rust-owned workspace to `worksheets` and opened the US Letter portrait editor without a QML or shader-loading error.
