# Low-end ink-preview profile

The existing preview path performs a `Canvas` repaint, a `ShaderEffectSource` texture update, and a five-sample fragment shader for each accepted preview sample. This is visually smooth but can be disproportionate on older integrated GPUs because `ShaderEffectSource` adds a render-to-texture pass and memory overhead.

The reduced-cost profile applies three limits. It renders the Canvas source and ink texture at 0.75 scale, coalesces texture updates to at most one per 33 ms, and swaps the five-sample filter for a single texture sample when low-power mode is selected. The high-quality profile preserves the five-sample filter and full-resolution source. Both profiles keep `live: false`, use explicit `scheduleUpdate()`, and avoid recursive texture feedback.

| Profile | Texture scale | Texture updates | Fragment texture samples | Intended use |
| --- | --- | --- | --- | --- |
| `balanced` | 1.00 | Every accepted sample | 5 | Current desktop hardware |
| `lowPower` | 0.75 | At most every 33 ms | 1 | Older integrated GPUs and software-constrained X11 sessions |

Qt documents that `ShaderEffectSource` can reduce performance and increases video-memory usage; it supports explicit texture sizing and scheduled updates when `live` is false. [1] Qt also notes that blending and extra samples incur cost, while a standard ShaderEffect mesh is only four vertices. [2] Qt’s default scene-graph renderer documentation recommends limiting uploads to necessary changes and using its timing diagnostics to confirm whether rendering is actually the bottleneck. [3]

The `lowPower` path is intentionally deterministic. It is not a frame-rate benchmark or a claim that it will improve every device; it reduces documented work per update and should be selected after device profiling with `QSG_RENDER_TIMING=1` and representative pen input.

## References

[1]: https://doc.qt.io/qt-6/qml-qtquick-shadereffectsource.html "Qt 6 ShaderEffectSource QML Type"
[2]: https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html "Qt 6 ShaderEffect QML Type"
[3]: https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph-renderer.html "Qt Quick Scene Graph Default Renderer"
