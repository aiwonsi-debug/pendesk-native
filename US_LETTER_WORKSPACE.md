# US Letter portrait pen-display workspace

PenDesk now treats the **US Letter portrait worksheet** as the primary work surface. The paper canvas uses an 8.5:11 width-to-height ratio (approximately 0.7727) and is presented as an actual page on a quiet desk surface instead of as a broad, generic preview area.

| Display orientation | Worksheet behavior | Pen-display priority |
| --- | --- | --- |
| Full HD portrait, 1080×1920 | A tall US Letter page fills the initial editable region below the compact workspace switcher. | Maximum on-page space; the fixed dock remains reachable at the bottom. |
| Full HD landscape, 1920×1080 | The US Letter page is centered in a paper-stage area with a small Page Setup panel. | The page retains a true portrait shape while page status and quality information stay outside the writing area. |

The pen target is confined to the paper surface. Its transient QML preview continues to use the balanced or low-power shader profile, while the Rust bridge receives the stroke-completion signal. The fixed dock preserves Pen, Eraser, Palm Rest, and future history controls without requiring the user to leave the worksheet.

## Visual validation

The native QML scene was rendered under X11 at 1920×1080 and 1080×1920. The landscape capture keeps a centered, proportionally correct portrait page alongside Page Setup. The portrait capture puts the page in the first working viewport after navigation and keeps the fixed pen dock exposed at the bottom. Both configurations started without a QML or shader-loading error.

An automated X11 pointer stroke on the portrait paper surface rendered visibly on the page and invoked `commitPreviewStroke`, which reported one committed preview stroke through the Rust bridge.
