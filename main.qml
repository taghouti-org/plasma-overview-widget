// Overview: a panel button for KWin's Overview effect (all windows + all virtual
// desktops + app search, like GNOME's Activities). Invoking the registered global
// shortcut is the same path the Meta+W key takes.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string overviewCmd:
        "busctl --user call org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component invokeShortcut s Overview"
    readonly property string gridCmd:
        "busctl --user call org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component invokeShortcut s 'Grid View'"

    // What the bare Meta key should do. KWin only reads this at startup.
    readonly property string metaOverview:
        "org.kde.kglobalaccel,/component/kwin,org.kde.kglobalaccel.Component,invokeShortcut,Overview"
    readonly property string metaLauncher:
        "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu"

    preferredRepresentation: compactRepresentation
    Plasmoid.icon: Plasmoid.configuration.icon || "view-grid"
    toolTipMainText: "Overview"
    toolTipSubText: Plasmoid.configuration.middleClickGrid
        ? "Click: windows, desktops and app search\nMiddle-click: desktop grid"
        : "Windows, desktops and app search"

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
        }
    }

    function run(cmd) {
        executable.disconnectSource(cmd)
        executable.connectSource(cmd)
    }

    // Keep kwinrc in sync with the checkbox. Applied on change and at startup so
    // the setting survives even if it is edited elsewhere.
    // KWin ignores a custom ModifierOnlyShortcuts entry that carries arguments, so
    // bare Meta must stay on KWin's default action, activateLauncherMenu. This widget
    // declares itself the launcher (X-Plasma-Provides) and turns that activation into
    // "open Overview" below, which is why pressing Meta works at all.
    readonly property string metaDefault:
        "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu"

    function applyMetaBinding() {
        run("kwriteconfig6 --file kwinrc --group ModifierOnlyShortcuts --key Meta \"" + root.metaDefault
            + "\" && qdbus6 org.kde.KWin /KWin reconfigure")
    }

    // Plasma "expands" a launcher applet when Meta is pressed. Collapse it again and
    // trigger Overview instead of showing an empty popup.
    onExpandedChanged: {
        if (root.expanded) {
            root.expanded = false
            if (Plasmoid.configuration.metaKey) {
                run(root.overviewCmd)
            }
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onMetaKeyChanged() { root.applyMetaBinding() }
    }

    Component.onCompleted: applyMetaBinding()

    // Clicking triggers the effect instead of opening a popup
    fullRepresentation: Item {}

    // The icon is the root so the panel gets a real size hint from it
    compactRepresentation: Kirigami.Icon {
        source: Plasmoid.icon
        active: mouseArea.containsMouse

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton && Plasmoid.configuration.middleClickGrid) {
                    root.run(root.gridCmd)
                } else {
                    root.run(root.overviewCmd)
                }
            }
        }
    }
}
