#!/bin/sh
# Build an installable Debian package from the native Rust/CXX-Qt project.
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$PROJECT_ROOT/Cargo.toml" | head -n 1)
ARCHITECTURE=$(dpkg --print-architecture)
PACKAGE_NAME=pendesk
PACKAGE_VERSION="${VERSION}-1"
STAGE="$PROJECT_ROOT/build/debian-root"
OUTPUT="$PROJECT_ROOT/dist/${PACKAGE_NAME}_${PACKAGE_VERSION}_${ARCHITECTURE}.deb"

if [ -z "$VERSION" ]; then
    echo "Unable to determine package version from Cargo.toml." >&2
    exit 1
fi

cd "$PROJECT_ROOT"
QMAKE="${QMAKE:-/usr/bin/qmake6}" cargo build --release

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" "$PROJECT_ROOT/dist"

install -Dm755 "$PROJECT_ROOT/target/release/pendesk-native" "$STAGE/usr/bin/pendesk"
install -Dm644 "$PROJECT_ROOT/packaging/org.pendesk.PenDesk.desktop" "$STAGE/usr/share/applications/org.pendesk.PenDesk.desktop"
install -Dm644 "$PROJECT_ROOT/packaging/org.pendesk.PenDesk.svg" "$STAGE/usr/share/icons/hicolor/scalable/apps/org.pendesk.PenDesk.svg"
install -Dm644 "$PROJECT_ROOT/packaging/copyright" "$STAGE/usr/share/doc/pendesk/copyright"
install -Dm644 "$PROJECT_ROOT/README.md" "$STAGE/usr/share/doc/pendesk/README.md"
install -Dm644 "$PROJECT_ROOT/ARCHITECTURE.md" "$STAGE/usr/share/doc/pendesk/ARCHITECTURE.md"
install -Dm644 "$PROJECT_ROOT/INK_PIPELINE.md" "$STAGE/usr/share/doc/pendesk/INK_PIPELINE.md"
install -Dm644 "$PROJECT_ROOT/LOW_END_PERFORMANCE.md" "$STAGE/usr/share/doc/pendesk/LOW_END_PERFORMANCE.md"
install -Dm644 "$PROJECT_ROOT/FULLHD_LAYOUT.md" "$STAGE/usr/share/doc/pendesk/FULLHD_LAYOUT.md"
install -Dm644 "$PROJECT_ROOT/US_LETTER_WORKSPACE.md" "$STAGE/usr/share/doc/pendesk/US_LETTER_WORKSPACE.md"
install -Dm644 "$PROJECT_ROOT/REFERENCE_HOME_LAYOUT.md" "$STAGE/usr/share/doc/pendesk/REFERENCE_HOME_LAYOUT.md"
install -Dm644 "$PROJECT_ROOT/UPLOADED_PATCH_REVIEW.md" "$STAGE/usr/share/doc/pendesk/UPLOADED_PATCH_REVIEW.md"
install -Dm644 "$PROJECT_ROOT/LIVE_DEBIAN_TEST.md" "$STAGE/usr/share/doc/pendesk/LIVE_DEBIAN_TEST.md"

# Derive native shared-library dependencies from the release executable and add
# QML modules and the X11 platform plugin explicitly because they are loaded at run time.
SHLIB_DEPENDS=$(dpkg-shlibdeps -O -e"$STAGE/usr/bin/pendesk" | sed -n 's/^shlibs:Depends=//p')
QML_DEPENDS="qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-window, qml6-module-qtquick-templates, qml6-module-qtqml-workerscript, qt6-qpa-plugins"

if [ -z "$SHLIB_DEPENDS" ]; then
    echo "Unable to derive shared-library dependencies for the release executable." >&2
    exit 1
fi

cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Section: x11
Priority: optional
Architecture: $ARCHITECTURE
Maintainer: PenDesk Prototype <noreply@pendesk.local>
Depends: $SHLIB_DEPENDS, $QML_DEPENDS
Description: Stylus-first worksheet and clipart workspace
 PenDesk is a native Qt 6/QML desktop prototype for browsing learning
 references, drafting worksheets, creating clipart, and testing pen-oriented
 interactions on Debian X11 desktops.
EOF

desktop-file-validate "$STAGE/usr/share/applications/org.pendesk.PenDesk.desktop"
dpkg-deb --root-owner-group --build "$STAGE" "$OUTPUT"
dpkg-deb --info "$OUTPUT"
echo "Built $OUTPUT"
