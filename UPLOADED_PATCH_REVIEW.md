# Uploaded UX/UI Patch Review

## Scope reviewed

The uploaded archive contains a patch and full replacement copies of `qml/Main.qml` and `qml/InkSurface.qml`. The patch targets only those two QML files and applies cleanly to the current PenDesk source tree with `git apply --check`.

| Proposed change | Review result |
| --- | --- |
| Compact layout below 1100 logical px | Compatible. The 900×620 isolated capture showed an icon-only rail, hidden Page Setup panel, visible Letter page, and a usable fixed dock. |
| Three active dock controls | Compatible. Undo and Redo are hidden until a real Rust stroke-history model exists, increasing the pen, eraser, and Palm Rest target widths. |
| Pressed feedback and dynamic daily grids | Compatible. These additions preserve the reference-driven home layout while avoiding a fixed three-column assumption at narrow landscape sizes. |
| Accessibility labels | Compatible. The patch adds names and roles to workspace, dock, and ink-control buttons. |
| `preventStealing` on ink input | Already present in the current source. The uploaded patch only adds an explanatory comment at that line. |

## Isolated validation

The patch was applied only to an isolated copy of the current committed source. That copy built successfully with the existing Rust/CXX-Qt and Qt 6 toolchain. The resulting QML application started without QML or shader-loading errors at both 900×620 (`worksheets`) and 2560×1440 (`daily`). The tracked PenDesk repository has not been modified by this review.

## Remaining non-UI work

The patch does not add native tablet pressure, tilt, barrel-button, or eraser-identity input. It also does not replace the preview sample-array copy on every sample or persist the actual completed stroke data in Rust. Those are separate ink-pipeline tasks.

## Recommended integration

Apply only the reviewed QML patch, then rebuild the Debian package, revalidate the compact and Full HD layouts, commit the result, and push a follow-up revision to GitHub. Explicit approval is required before modifying the tracked source and the remote repository.

## Approved tracked-source validation

The approved patch has now been applied to the tracked QML source. The native application built successfully and rendered without QML or shader-loading errors at 900×620 and 2560×1440. The compact capture shows the icon-only rail, Letter page, and three wider pen controls; the Full HD capture retains the supplied-reference daily desk composition with three launch tiles and three recent-work entries.

## Refreshed archive review

The refreshed archive contains the same `InkSurface.qml` as the current tracked source and a `Main.qml` replacement with three additional refinements: a flexible `RowLayout` status row, compact-rail hover tooltips, and a visible selected-workspace accent bar in compact mode. Its combined patch was generated against an older source revision and does not apply directly, but a direct comparison shows only 17 added and 3 removed lines relative to the current `Main.qml`.

The replacement QML was validated in an isolated copy of the current source. It built successfully and started without QML or shader-loading errors at 900×620, 2560×1440, and 1080×1920. The 900×620 capture visibly confirmed the compact **Browse** tooltip; the active worksheet rail tile retained its coral selection accent. The tracked source has not yet been modified with these three additional refinements.

## Applied refinement validation

The three refinements have now been applied to tracked `Main.qml` as a focused change rather than applying the stale combined patch. The debug build and rendered native sessions passed at 900×620, 2560×1440, and 1080×1920 without QML or shader-loading errors. The rebuilt release binary also passed compact and Full HD X11 smoke checks; the Debian package contains the executable, launcher, icon, and review documentation.
