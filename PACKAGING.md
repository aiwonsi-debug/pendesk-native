# Debian packaging

The native PenDesk prototype is packaged as a single architecture-specific Debian binary package named `pendesk`. The installer places the executable in `/usr/bin`, a desktop entry in `/usr/share/applications`, a scalable application icon in the standard hicolor icon tree, and user documentation under `/usr/share/doc/pendesk`.

The build script derives shared-library dependencies from the compiled Rust/Qt executable through `dpkg-shlibdeps`. The small `debian/control` source-metadata file allows that dependency scanner to resolve the target binary package. The installer additionally declares the QML modules and Qt platform plugin that Qt loads at runtime; these dependencies cannot be inferred solely from the executable’s ELF linkage. The package deliberately has no maintainer scripts because it does not manage a service, session, or system configuration.

Run the following from the project root to create the installer:

```bash
./scripts/build-deb.sh
sudo apt install ./dist/pendesk_0.1.0-1_amd64.deb
```

The desktop file conforms to the freedesktop desktop-entry structure: it declares an `Application` type, executable command, icon, and desktop categories. [1] The package control metadata declares the package identity, version, architecture, description, and required dependencies, as expected for a Debian binary package. [2]

## References

[1]: https://specifications.freedesktop.org/desktop-entry/latest-single "Desktop Entry Specification"
[2]: https://www.debian.org/doc/debian-policy/ch-binary.html "Debian Policy Manual: Binary packages"
