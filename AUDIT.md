# PenDesk native prototype audit

**Scope.** This audit covers the release build rendered under X11 at 1440×900, the worksheet/ink-preview QML path, the Rust `DesktopState` bridge, and the Debian desktop integration metadata. It distinguishes verified defects from device-specific behavior that still needs an on-tablet test.

## Executive assessment

The prototype is a credible native Qt/QML shell: the release executable starts in X11, both precompiled QSB assets resolve, the worksheet view renders, and the Debian package contains the executable, launcher, icon, and documentation. The low-power profile reduces clear, documented units of rendering work: texture size, update cadence, and fragment samples.

However, the audited build is **not yet ready to represent real stylus capture or persisted ink**. The visible worksheet contains a functional preview scaffold, rather than a production ink system. Two confirmed wiring defects are visible in the release capture: Qt bridge property names are referenced with the wrong casing, and several eight-digit QML color strings use CSS alpha ordering rather than Qt's ARGB ordering. Both should be corrected before further UX or performance tuning.

## Evidence collected

| Check | Result | Evidence |
| --- | --- | --- |
| Release worksheet startup | Passed | The release build ran offscreen and in X11 without a QML or shader loading error. |
| QSB resource lookup | Passed | Both `ink_smooth.frag.qsb` and `ink_passthrough.frag.qsb` are embedded and the rendered worksheet starts. |
| Top-level visual layout | Passed with UX observations | Captures show the native rail, worksheet state, action tiles, recent-work cards, persistent tool dock, and the ink surface after scrolling. |
| Rust/QML state binding | Failed | The release capture renders `undefined strokes handed to Rust`; the compiled binary exposes `committed_strokes`, while QML reads `committedStrokes`. |
| X11 launcher identity | Failed | Desktop metadata declares `StartupWMClass=PenDesk`; the running Qt window reports `WM_CLASS = "pendesk-native", "pendesk-native"`. |
| Low-power rendering mode | Structurally implemented, not benchmarked | The mode selects 0.75 texture scale, a 33 ms texture-update cap, and a one-sample QSB shader. No device latency/frame-time measurement was taken. |

## Prioritized findings

| Priority | Finding | Evidence and impact | Recommended remediation |
| --- | --- | --- | --- |
| **P0** | QML uses camelCase properties that the Rust QObject does not expose. | `DesktopState` declares `committed_strokes`, `selected_tool`, and `palm_rest`. `Main.qml` reads `committedStrokes`, `selectedTool`, and `palmRest`; the X11 capture visibly shows `undefined strokes handed to Rust`. Tool-selection and Palm Rest highlighting are also therefore unreliable. | Align the bridge API and QML to one convention. Prefer declaring QML-facing property names explicitly in the CXX-Qt bridge as `committedStrokes`, `selectedTool`, and `palmRest`, then add a smoke assertion that the status label starts at `0 strokes handed to Rust`. |
| **P0** | Three visual borders use CSS `#RRGGBBAA` notation in a QML color property that expects ARGB ordering. | `#ffffff66`, `#ffffff0b`, `#ffffff99`, and `#ffffff40` are parsed as opaque yellow-tinted colors, producing the yellow outlines seen in the native capture. Qt documents QML color values as ARGB. [1] | Change to `#66ffffff`, `#0bffffff`, `#99ffffff`, and `#40ffffff`, respectively. Add a source check that rejects 8-digit values ending in a likely alpha byte after `ffffff`. |
| **P1** | The documented X11 startup class does not match the real window class. | The desktop file has `StartupWMClass=PenDesk`; the release window reports `pendesk-native`. Window managers may not associate startup feedback, taskbar grouping, or icon behavior correctly. | Set the desktop-entry value to `pendesk-native`, or set the Qt application/window class deliberately to `PenDesk` and retain the desktop entry. Validate with `xprop WM_CLASS` in CI. |
| **P1** | The actual drawing area is below the fold when the user enters Worksheets. | At 1440×900, the initial worksheet view shows the headline, three launch tiles, and Recent Work. The Live ink preview is reached only after scrolling. This makes a stylus-first task secondary to navigation tiles. | Place the live worksheet/ink surface immediately below the heading for the Worksheets route; move tiles and Recent Work to a start/home route or below the editor. |
| **P1** | The declared 1024×680 minimum viewport does not present the whole workspace. | After resizing the real X11 client window to 1024×680, the third launch tile and persistent tool dock are outside the visible client area. The fixed 292 px rail and the one-row tile arrangement leave insufficient room, and the visual hierarchy is clipped rather than reflowed. | Define a compact breakpoint: reduce the rail, make action tiles wrap or collapse to an icon/list pattern, and reserve the tool dock before allocating the scrollable content height. Add an X11 screenshot assertion at 1024×680. |
| **P1** | The current input surface is mouse-only and ignores pressure. | `MouseArea` accepts `Qt.LeftButton`; each sample passes `1.0` pressure. The preview does not receive tablet device data, tilt, eraser tool identity, or Palm Rest input. Qt describes `MouseArea` as simple mouse handling; it is not a complete tablet-input abstraction. [2] | Replace or supplement `MouseArea` with Qt Pointer Handlers/tablet-aware input, pass pressure/tool data across a bounded Rust stroke buffer, and explicitly test with a physical stylus under X11. |
| **P1** | The preview data path redraws and copies the entire unbounded stroke for each sample. | `addPreviewSample()` copies `samples` using `slice()` and appends on every input event; `Canvas.onPaint` then loops over every sample and redraws every segment. A long stroke therefore has quadratic aggregate JS/Canvas work before the shader cost is considered. | Cap live preview samples, reject near-duplicate points based on distance/time, and draw only the newly accepted segment. Move the canonical, bounded point buffer to Rust before implementing long-stroke or document workflows. |
| **P2** | A vertical pen gesture inside the `Flickable` can be stolen without completing the preview stroke. | `MouseArea.preventStealing` defaults to `false` and the component defines `onReleased` but no `onCanceled`. Qt documents that a parent `Flickable` may steal such a gesture and that cancellation must be handled. [2] | Decide whether canvas strokes or scroll gestures win. For drawing, set `preventStealing: true` and implement `onCanceled` to reset/commit safely; reserve a separate explicit scroll affordance or tool mode. |
| **P1** | Preview strokes are not persisted in Rust. | `commit_preview_stroke(sample_count)` increments a counter only. The Canvas is the sole stroke geometry store; Clear deletes all transient samples. Reopening, undo/redo, export, or lossless re-rendering are not implemented. | Send bounded point batches and stroke metadata to Rust. Make Rust own a document/stroke model, implement undo/redo against it, and redraw QML from the model rather than treating Canvas samples as canonical data. |
| **P2** | The low-power profile switch has no explicit re-render request. | With `ShaderEffectSource.live: false`, Qt requires `scheduleUpdate()` to refresh the texture. The profile toggle changes `textureScale` and `fragmentShader`, but it does not call `rawInk.requestPaint()` or `requestTextureUpdate()`. [3] | Add an `onQualityProfileChanged` handler that repaints Canvas and requests an immediate texture update. Verify switching mode while an existing stroke is visible. |
| **P2** | The smoothing kernel size is bound to display size, not the reduced texture size. | `pixelStepX/Y` use `ShaderEffect.width/height`, while the low-power source texture is 75% of that size. In low-power mode, the five-sample shader is not active, but the formula will be incorrect if profiles later combine scaling and smoothing. | Compute sampling steps from `rawInk.width` and `rawInk.height`, or remove unused step uniforms from the passthrough profile. |
| **P2** | Interaction labels describe the action instead of clearly exposing the current quality mode. | The status pill says `balanced` and the button says `Low power`; the relationship is inferable but not immediately explicit. | Use an accessible two-option segmented control with a selected state, for example `Quality: Balanced | Low power`, and retain a concise explanation of the cost trade-off. |

## Visual and workflow observations

The visual design has a distinct illustrated-workspace character and is legible at 1440×900. The navy rail, warm paper surface, coral worksheet state, and large tool dock create a coherent stylus-first identity. The persistent dock is especially useful because it preserves the active tool at the bottom of the workspace.

The first viewport, however, communicates a launchpad more than an editor. The large action tiles compete with the purpose of the Worksheets route, and the real ink canvas appears only after interacting with the scroll view. The row of small controls within the ink surface also sits near the lower-right edge and is visually delicate against the wide blank canvas. The color-order defect makes rail/action-tile outlines unexpectedly yellow, diluting the intended navy/coral/mint palette.

## Validation limits

The X11 release build was rendered on a virtual display and the window, shaders, and QML scene loaded successfully. The attempted automated mouse-stroke injection did **not** produce a committed-stroke log entry, but the resulting capture returned to the top of the scroll view. This does not prove a draw-event failure; it is insufficient evidence because the synthetic input did not preserve the expected scrolled target. A physical stylus test remains required.

No claim is made about real-device latency, FPS, pressure fidelity, tablet-event delivery, or memory use. Qt explicitly cautions that `ShaderEffectSource` can reduce performance and increases video-memory use; the low-power path should be profiled using representative pen input rather than judged only from its structural reduction in work. [3]

## Recommended next implementation order

First repair the QML/Rust property names and the Qt ARGB literals; these are low-effort correctness repairs with immediate visible benefit. Next align `StartupWMClass` and move the live ink surface into the first worksheet viewport. Then replace the preview-only counter with a Rust-owned stroke model and tablet-aware input. Finally, add a profile-toggle refresh test and collect `QSG_RENDER_TIMING=1` data on the actual target tablet/GPU before changing default quality behavior.

## References

[1]: https://doc.qt.io/qt-6/qml-color.html "Qt QML color value type"
[2]: https://doc.qt.io/qt-6/qml-qtquick-mousearea.html "Qt Quick MouseArea"
[3]: https://doc.qt.io/qt-6/qml-qtquick-shadereffectsource.html "Qt Quick ShaderEffectSource"
