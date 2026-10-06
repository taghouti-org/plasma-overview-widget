import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: page

    // cfg_icon is a plain property (not an alias) because the icon dialog writes to it.
    property string cfg_icon: Plasmoid.configuration.icon
    property string cfg_iconDefault: "view-grid"
    property alias cfg_metaKey: metaCheck.checked
    property bool cfg_metaKeyDefault: true
    property alias cfg_middleClickGrid: gridCheck.checked
    property bool cfg_middleClickGridDefault: true

    KIconThemes.IconDialog {
        id: iconDialog
        onIconNameChanged: iconName => page.cfg_icon = iconName || page.cfg_iconDefault
    }

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Icon:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                icon.name: page.cfg_icon
                text: i18nc("@action:button Open icon chooser", "Choose…")
                onClicked: iconDialog.open()
            }

            QQC2.Button {
                icon.name: "edit-clear"
                text: i18nc("@action:button Reset icon to default", "Reset")
                enabled: page.cfg_icon !== page.cfg_iconDefault
                onClicked: page.cfg_icon = page.cfg_iconDefault
            }
        }

        QQC2.Label {
            text: page.cfg_icon
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: metaCheck
            Kirigami.FormData.label: i18n("Meta key:")
            text: i18n("Pressing Meta alone opens Overview")
        }

        QQC2.Label {
            text: i18n("Replaces the Application Launcher on the Meta key.\nTakes effect after you log out and back in.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: gridCheck
            Kirigami.FormData.label: i18n("Middle-click:")
            text: i18n("Opens Grid View instead")
        }
    }
}
