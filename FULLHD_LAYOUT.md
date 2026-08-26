# Full HD 11.5-inch workspace layout

PenDesk now uses **logical display dimensions**, not a physical-inch measurement, to adapt the QML shell. A 1920×1080 display receives an editor-first landscape arrangement: a compact left workspace rail, a wide live ink surface immediately below the worksheet heading, and a persistent bottom tool dock. A 1080×1920 display uses a compact top workspace switcher, a taller portrait ink surface, and the same fixed dock so the canvas remains the first working surface rather than a scrolled destination.

| Orientation | Navigation | First workspace surface | Tool access |
| --- | --- | --- | --- |
| Full HD landscape (1920×1080) | 220–278 px left rail | Wide live ink canvas | 96 px fixed bottom dock |
| Full HD portrait (1080×1920) | 84 px top workspace switcher | Tall live ink canvas | 108 px fixed bottom dock |

The initial window size follows the available primary-screen geometry up to 1920 logical pixels in either dimension and keeps a 900×620 minimum. The design also corrects the prior QML/Rust property casing mismatch and Qt ARGB color literals, so the committed-stroke label and selection states no longer show `undefined` or yellow-tinted outlines.

## Validation observations

The QML workspace was captured under X11 at both 1920×1080 and 1080×1920. In landscape, the left rail, wide canvas, persistent dock, and status controls remain in the first viewport. In portrait, the left rail is replaced with the compact top switcher, while the canvas remains the first substantial work surface and the dock remains fixed at the bottom. Both captures started without QML or shader-loading errors.

An automated X11 pointer stroke on the landscape canvas rendered once and invoked `commitPreviewStroke`, producing `1 strokes handed to Rust`. The `ShaderEffectSource` intermediary is hidden from the visual scene so the final shader output is not duplicated or mirrored alongside it.
