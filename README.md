# Overview — a Plasma 6 panel button for KWin's Overview effect

A one-icon panel widget that opens **Overview**: all open windows, all virtual
desktops, and a search field that launches applications. It is Plasma's
equivalent of GNOME's Activities, and this widget makes it reachable with the
mouse instead of only `Meta+W`.

- **Click** — Overview (windows + desktops + app search)
- **Middle-click** — Grid View (all virtual desktops)
- **Optional** — make the bare `Meta` key open Overview instead of the
  Application Launcher

Tested on Kubuntu 26.04 / Plasma 6.6 / Wayland.

## How it works

It does not reimplement anything. It invokes the global shortcut that KWin
already registers, which is the exact code path the `Meta+W` key takes:

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
| Pressing Meta alone opens Overview | on | See the caveat below |
| Middle-click opens Grid View | on | |

### The Meta key option

When enabled, the widget writes this to `~/.config/kwinrc`:

```ini
[ModifierOnlyShortcuts]
Meta=org.kde.kglobalaccel,/component/kwin,org.kde.kglobalaccel.Component,invokeShortcut,Overview
```

**This only takes effect after you log out and back in.** KWin reads
modifier-only shortcuts when it starts; `qdbus6 org.kde.KWin /KWin reconfigure`
is *not* enough, and on Wayland KWin cannot be restarted without ending the
session.

Unticking it restores the default:

```ini
Meta=org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu
```

Note that this replaces the Application Launcher on `Meta`. Overview's own
search field launches apps the same way (type, press Enter), which is how GNOME
behaves, and the launcher remains available from its panel icon.

## Notes for anyone writing a Plasma 6 applet

Two things cost me real time here:

- A panel applet renders **nothing**, silently and with no log output, if the
  `Kirigami.Icon` used as `compactRepresentation` has explicit `implicitWidth`/
  `implicitHeight`, or if a bare `MouseArea` is the root (no implicit size, so
  the layout collapses it). Let `Kirigami.Icon` be the root and size itself.
- In the config page, the root is `KCM.SimpleKCM`, but the inner
  `Kirigami.FormLayout` must **not** be anchored to its parent. Anchoring it
  yields `QML SimpleKCM: Created graphical object was not placed in the graphics
  scene` and a blank settings dialog.

## License

GPL-3.0-or-later
