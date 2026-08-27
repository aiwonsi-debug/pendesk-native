# Live Debian-compatible package test

The rebuilt `pendesk_0.1.0-1_amd64.deb` was installed with `dpkg -i` into the available Ubuntu 24.04 environment, which is Debian-compatible. The package reached the installed state and provided the `/usr/bin/pendesk` executable, desktop entry, and application icon. It was then removed after testing so the sandbox was left clean.

| Check | Result |
| --- | --- |
| Debian package installation | Passed with `dpkg -i` |
| Offscreen runtime (`PENDESK_START_WORKSPACE=worksheets`) | Started for four seconds with no QML or shader-loading errors |
| X11 runtime at 900×620 | Started for four seconds with no QML or shader-loading errors |
| Desktop entry validation | Passed |
| Package documentation payload | Listed by `dpkg`; local installation intentionally removes it because `/etc/dpkg/dpkg.cfg.d/excludes` has `path-exclude=/usr/share/doc/*` except copyright and changelog files |
| Physical stylus tablet | Not available to this sandbox; `/dev/input` had no exposed device nodes and no tablet could be enumerated |

## Required physical-tablet validation

Physical stylus validation must be run on a Debian/X11 desktop with the actual pen display connected. Install the package with `sudo apt install ./pendesk_0.1.0-1_amd64.deb`, confirm the device appears in `xinput list`, launch PenDesk, choose **New Worksheet**, and draw a continuous stroke on the US Letter page. Confirm that the visible stroke follows the pen, the committed-stroke counter increments after pen-up, the three dock controls respond to pen taps, Palm Rest toggles, and the Low power control switches without a QML error. This prototype still treats pointer pressure as `1.0`; pressure, tilt, eraser identity, and barrel buttons remain native-tablet integration work.
