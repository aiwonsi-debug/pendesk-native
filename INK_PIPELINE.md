# Low-latency ink preview pipeline

The QML ink surface keeps the **presentation path** short: pointer samples are coalesced in `InkSurface.qml`, rendered immediately into an offscreen `Canvas`, and sampled by `ShaderEffect`. The fragment shader performs a small spatial blend around the current ink texture; it does not use a recursive texture, temporal feedback buffer, or network/persistence operation. This makes the effect a visual preview enhancement rather than a second stroke model.

| Boundary | Responsibility | Latency rule |
| --- | --- | --- |
| QML input adapter | Collect the latest pointer positions and draw a transient preview. | Coalesce samples; do not block on disk, IPC, or model serialization. |
| ShaderEffect | Smooth the current preview texture using a five-sample spatial filter. | No temporal feedback: no extra frame of prediction or history is introduced. |
| Rust ink service | Own canonical points, pressure, undo history, file persistence, and export. | Accept batched samples asynchronously; publish committed geometry back to QML. |
| Future scene-graph item | Replace Canvas when profile data shows it is necessary. | Keep graphics work inside the Qt scene-graph render path. |

Qt 6 `ShaderEffect` consumes precompiled `.qsb` assets rather than inline GLSL strings, so both the five-sample `ink_smooth.frag` and one-sample `ink_passthrough.frag` are compiled with Qt Shader Baker and embedded as Qt resources. The shaders include the required Vulkan-style uniform block and preserve premultiplied-alpha output. [1]

The pipeline intentionally avoids a recursive `ShaderEffectSource`. Qt documents that recursive live sources allocate an additional texture and render continuously; that is inappropriate for a minimal-latency preview. Qt also warns that `ShaderEffectSource` increases video-memory use, so the effect is constrained to the worksheet canvas only. [2]

The current scaffold exposes a `committedStrokes` Rust property and `commitPreviewStroke(sampleCount)` invokable. This proves the preview-to-Rust handoff at stroke completion without issuing a cross-language call for every preview point. A production implementation should replace the counter with a bounded Rust-side stroke buffer and a single batched commit that includes timestamped, pressure-aware points.

Qt Quick’s scene graph can render independently of the GUI thread in its threaded render loop. The final production renderer should therefore move dense stroke tessellation into a custom scene-graph item once real-device profiling shows the QML Canvas is the limiting stage. [3]

## Build the shader

```bash
/usr/lib/qt6/bin/qsb -O --glsl "100 es,120,150" \
  -o qml/shaders/ink_smooth.frag.qsb qml/shaders/ink_smooth.frag
QMAKE=/usr/bin/qmake6 cargo build
```

## References

[1]: https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html "Qt 6 ShaderEffect QML Type"
[2]: https://doc.qt.io/qt-6/qml-qtquick-shadereffectsource.html "Qt 6 ShaderEffectSource QML Type"
[3]: https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html "Qt Quick Scene Graph"
