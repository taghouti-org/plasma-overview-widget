# Overview — a Plasma 6 panel button for KWin's Overview effect

A one-icon panel widget that opens **Overview**: all open windows, all virtual
desktops, and a search field that launches applications. It is Plasma's
equivalent of GNOME's Activities, and this widget makes it reachable with the
mouse — and, optionally, with the bare **Meta** key.

- **Click** — Overview (windows + desktops + app search)
- **Middle-click** — Grid View (all virtual desktops)
- **Meta** — opens Overview instead of the Application Launcher (optional, on by default)

Tested on Kubuntu 26.04 / Plasma 6.6 / Wayland.

## How it works

It does not reimplement anything. It invokes the global shortcut KWin already
registers, which is the exact code path the `Meta+W` key takes:

```sh
busctl --user call org.kde.kglobalaccel /component/kwin \
  org.kde.kglobalaccel.Component invokeShortcut s Overview
```

`plasmashell`'s environment carries `DBUS_SESSION_BUS_ADDRESS`, so `busctl --user`
works from the applet's `Plasma5Support` executable data source.

## Install

```sh
# download all files from this gist into one directory, then:
chmod +x install.sh
./install.sh
```

Then right-click the panel → **Add Widgets…** → search **Overview** → drag it
onto the panel.

To remove: delete `~/.local/share/plasma/plasmoids/org.taghouti.overview` and
restart `plasma-plasmashell.service`.

## Settings

Right-click the widget → **Configure Overview**:

| Setting | Default | Notes |
|---|---|---|
| Icon | `view-grid` | Opens KDE's icon picker |
| Pressing Meta alone opens Overview | on | Works immediately, no logout |
| Middle-click opens Grid View | on | |

## How the Meta key is taken over — and why the obvious way fails

The widely-repeated recipe for binding bare Meta is to put a custom D-Bus call in
`~/.config/kwinrc`:

```ini
[ModifierOnlyShortcuts]
Meta=org.kde.kglobalaccel,/component/kwin,org.kde.kglobalaccel.Component,invokeShortcut,Overview
```

**On Plasma 6.6 this silently does nothing.** Verified with a genuinely restarted
KWin (new PID), the correct value in `kwinrc`, nothing else bound to Meta and the
Overview effect loaded. KWin appears not to honour entries that carry arguments;
it falls back to its built-in default, `activateLauncherMenu`. If you have no
launcher applet in your panel, that shows an empty popup — which looks exactly
like the widget being broken.

So this widget goes the other way: it leaves Meta on KWin's default action and
makes itself the thing that action targets.

```json
"X-Plasma-Provides": ["org.kde.plasma.launchermenu"]
```

Plasma then "expands" this widget when Meta is pressed, and the widget converts
that into opening Overview:

```qml
onExpandedChanged: {
    if (root.expanded) {
        root.expanded = false
        if (Plasmoid.configuration.metaKey) {
            run(root.overviewCmd)
        }
    }
}
```

Because this rides the default binding, it needs **no logout** and no change to
KWin's configuration.

Note that this replaces the Application Launcher on `Meta`. Overview's own search
field launches apps the same way (type, press Enter), which is how GNOME behaves,
and a launcher widget remains usable from its own panel icon.

### Testing it without touching the keyboard

`activateLauncherMenu` is exactly what the Meta key invokes, and `activeEffects`
reports whether Overview is running:

```sh
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell activateLauncherMenu
busctl --user get-property org.kde.KWin /Effects org.kde.kwin.Effects activeEffects
```

First call turns Overview on, second turns it off.

## Notes for anyone writing a Plasma 6 applet

Four things cost me real time here:

- **`expanded = false` inside `onExpandedChanged` assigns to the signal's injected
  parameter, not the property.** The popup therefore never closes and the toggle
  desyncs — one press to show, two to hide. The log warns
  `Parameter "expanded" is not declared`. Write `root.expanded = false`.
- **`fullRepresentation` must exist and have a real size.** Removing it, or giving
  it `implicitWidth`/`implicitHeight` of 0 or 1, stops Plasma expanding the applet
  at all, so the Meta trigger silently dies. `fullRepresentation: Item {}` is right.
- A panel applet renders **nothing**, silently and with no log output, if the
  `Kirigami.Icon` used as `compactRepresentation` has explicit `implicitWidth`/
  `implicitHeight`, or if a bare `MouseArea` is the root (no implicit size, so the
  layout collapses it). Let `Kirigami.Icon` be the root and size itself.
- In the config page the root is `KCM.SimpleKCM`, but the inner
  `Kirigami.FormLayout` must **not** be anchored to its parent. Anchoring it yields
  `QML SimpleKCM: Created graphical object was not placed in the graphics scene`
  and a blank settings dialog.

## License

GPL-3.0-or-later
