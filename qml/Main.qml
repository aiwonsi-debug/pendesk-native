// PenDesk reference-driven desktop shell: native QML interpretation of the supplied stylus workspace.
// QML owns presentation; DesktopState (Rust) remains the authoritative UI state boundary.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.pendesk.desktop 1.0

ApplicationWindow {
    id: root
    minimumWidth: 900
    minimumHeight: 620
    width: Math.max(minimumWidth, Screen.width)
    height: Math.max(minimumHeight, Screen.height)
    visible: true
    title: "PenDesk — Debian Daily Desk"
    color: "#fffdf9"

    readonly property DesktopState desktop: DesktopState {}
    readonly property bool landscape: width >= height
    // compact breakpoint (compact = width ต่ำกว่า 1100 logical px): rail ยุบเหลือไอคอน, page-setup panel ซ่อน
    readonly property bool compact: width < 1100
    readonly property int railWidth: compact ? 88 : Math.max(280, Math.min(480, Math.round(width * 0.1875)))
    readonly property int contentGutter: landscape ? Math.max(32, Math.round(width * 0.022)) : 24
    readonly property int dockHeight: landscape ? 96 : 108
    readonly property real letterPortraitRatio: 8.5 / 11.0
    readonly property color navy: "#071d42"
    readonly property color navySoft: "#113363"
    readonly property color coral: "#ff8162"
    readonly property color sky: "#d6ecff"
    readonly property color mint: "#d5f0df"
    readonly property color lavender: "#e2dcff"
    readonly property color ink: "#0a1b3e"
    readonly property color muted: "#5e6574"

    function workspaceLabel() {
        if (desktop.workspace === "browse") return "Browse references"
        if (desktop.workspace === "worksheets") return "New Worksheet"
        if (desktop.workspace === "clipart") return "Clipart Studio"
        return "Daily Desk"
    }

    function workspaceDescription() {
        if (desktop.workspace === "browse") return "Keep reference material within easy reach."
        if (desktop.workspace === "worksheets") return "Start writing now; workspace tools stay close by."
        if (desktop.workspace === "clipart") return "Build visual teaching materials with your stylus."
        return "Choose a focused workspace for the next task."
    }

    component RailTile: Button {
        required property string keyName
        required property string label
        required property string glyph
        required property color activeColor
        implicitHeight: root.landscape ? (root.desktop.workspace === "daily" ? Math.max(160, Math.min(280, Math.round(root.height * 0.20))) : 124) : 72
        hoverEnabled: true
        onClicked: root.desktop.activateWorkspace(keyName)
        background: Rectangle {
            radius: 18
            color: root.desktop.workspace === keyName ? activeColor.darker(1.28) : (parent.hovered ? "#14376a" : root.navySoft)
            border.color: root.desktop.workspace === keyName ? "#66ffffff" : "#0bffffff"
            border.width: root.desktop.workspace === keyName ? 2 : 1
            scale: parent.down ? 0.96 : 1.0
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        }
        Accessible.role: Accessible.Button
        Accessible.name: label
        contentItem: Item {
            Column {
                visible: root.landscape && !root.compact
                anchors.centerIn: parent
                spacing: 4
                Text { text: glyph; color: "white"; font.pixelSize: 46; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                Text { text: label; color: "white"; font.pixelSize: 18; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; width: parent.width }
            }
            // compact landscape: icon only, ไม่แสดงข้อความ เพื่อประหยัดพื้นที่ rail
            Text {
                visible: root.landscape && root.compact
                anchors.centerIn: parent
                text: glyph
                color: "white"
                font.pixelSize: 30
                font.weight: Font.DemiBold
            }
            Row {
                visible: !root.landscape
                anchors.centerIn: parent
                spacing: 8
                Text { text: glyph; color: "white"; font.pixelSize: 24; font.weight: Font.DemiBold }
                Text { text: label; color: "white"; font.pixelSize: 14; font.weight: Font.Bold }
            }
        }
    }

    component DockButton: Button {
        required property string keyName
        required property string label
        required property string glyph
        required property color fill
        required property bool isPalm
        property bool isHistoryAction: false
        implicitHeight: root.landscape ? 58 : 64
        enabled: !isHistoryAction
        opacity: enabled ? 1.0 : 0.52
        Accessible.role: Accessible.Button
        Accessible.name: label
        Accessible.checked: (isPalm && root.desktop.palm_rest) || (!isPalm && !isHistoryAction && root.desktop.selected_tool === keyName)
        onClicked: {
            if (isPalm)
                root.desktop.togglePalmRest()
            else if (!isHistoryAction)
                root.desktop.selectTool(keyName)
        }
        background: Rectangle {
            radius: height / 2
            color: ((isPalm && root.desktop.palm_rest) || (!isPalm && !isHistoryAction && root.desktop.selected_tool === keyName)) ? fill.darker(1.08) : fill
            scale: parent.down ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        }
        contentItem: Row {
            anchors.centerIn: parent
            spacing: root.landscape ? 11 : 7
            Text { text: glyph; color: root.ink; font.pixelSize: root.landscape ? 25 : 22; font.weight: Font.DemiBold }
            Text { text: label; color: root.ink; font.pixelSize: root.landscape ? 16 : 14; font.weight: Font.Bold }
        }
    }

    component ActionTile: Button {
        required property string keyName
        required property string label
        required property string detail
        required property string glyph
        required property color fill
        required property color glyphColor
        property bool compact: false
        hoverEnabled: true
        onClicked: root.desktop.activateWorkspace(keyName)
        background: Rectangle {
            radius: 20
            color: fill
            border.color: "#99ffffff"
            border.width: 1
            scale: parent.down ? 0.975 : (parent.hovered ? 1.012 : 1.0)
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        }
        contentItem: Item {
            Column {
                visible: !compact
                anchors.centerIn: parent
                spacing: 8
                Text { text: glyph; color: glyphColor; font.pixelSize: 76; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                Text { text: label; color: root.ink; font.pixelSize: 27; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                Text { text: detail; color: root.muted; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; width: parent.width }
            }
            Row {
                visible: compact
                anchors.fill: parent
                anchors.margins: 20
                spacing: 18
                Text { anchors.verticalCenter: parent.verticalCenter; text: glyph; color: glyphColor; font.pixelSize: 48; font.weight: Font.DemiBold }
                Column { anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    Text { text: label; color: root.ink; font.pixelSize: 21; font.weight: Font.Bold }
                    Text { text: detail; color: root.muted; font.pixelSize: 13; font.weight: Font.DemiBold }
                }
            }
        }
    }

    component SummaryCell: Rectangle {
        required property string heading
        required property string detail
        required property string glyph
        required property color tint
        color: tint
        radius: 14
        Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.top: parent.top; anchors.topMargin: 14; text: glyph; color: root.ink; font.pixelSize: 27; font.weight: Font.DemiBold }
        Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 33; text: heading; color: root.ink; font.pixelSize: 16; font.weight: Font.Bold }
        Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; text: detail; color: root.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
    }

    component HomeLaunchTile: Button {
        required property string keyName
        required property string label
        required property string glyph
        required property color fill
        required property color glyphColor
        hoverEnabled: true
        Accessible.role: Accessible.Button
        Accessible.name: label
        onClicked: root.desktop.activateWorkspace(keyName)
        background: Rectangle {
            radius: 22
            color: fill
            border.color: "#80ffffff"
            border.width: 1
            scale: parent.down ? 0.985 : (parent.hovered ? 1.01 : 1.0)
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
        contentItem: Item {
            Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: root.landscape ? 27 : 18; text: glyph; color: glyphColor; font.pixelSize: root.landscape ? 110 : 68; font.weight: Font.DemiBold }
            Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: root.landscape ? 24 : 18; text: label; color: root.ink; font.pixelSize: root.landscape ? 30 : 22; font.weight: Font.Bold }
        }
    }

    component RecentWorkTile: Button {
        required property string titleText
        required property string glyph
        required property color artFill
        required property color artInk
        hoverEnabled: true
        background: Rectangle {
            radius: 16
            color: "#fffefa"
            border.color: parent.hovered ? "#a9bfd8" : "#e5e0d8"
            border.width: parent.hovered ? 2 : 1
            scale: parent.down ? 0.98 : 1.0
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        }
        contentItem: Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 14
            Rectangle { width: root.landscape ? 112 : 94; height: parent.height; radius: 12; color: artFill; Text { anchors.centerIn: parent; text: glyph; color: artInk; font.pixelSize: root.landscape ? 64 : 50; font.weight: Font.DemiBold } }
            Text { width: parent.width - (root.landscape ? 142 : 120); anchors.verticalCenter: parent.verticalCenter; text: titleText; color: root.ink; font.pixelSize: root.landscape ? 19 : 16; font.weight: Font.Bold; wrapMode: Text.WordWrap }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            visible: root.landscape
            Layout.preferredWidth: root.railWidth
            Layout.fillHeight: true
            color: root.navy
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14
                Row {
                    Layout.fillWidth: true
                    spacing: 10
                    Text { text: "◔"; color: root.coral; font.pixelSize: root.compact ? 40 : 70; font.weight: Font.Bold }
                    Column {
                        visible: !root.compact
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text { text: "Debian"; color: "white"; font.pixelSize: 32; font.weight: Font.Bold }
                        Text { text: "Daily Desk"; color: "#c7bbe9"; font.pixelSize: 18; font.weight: Font.DemiBold }
                    }
                }
                RailTile { Layout.fillWidth: true; keyName: "browse"; label: "Browse"; glyph: "◎"; activeColor: root.sky }
                RailTile { Layout.fillWidth: true; keyName: "worksheets"; label: "Worksheets"; glyph: "▤"; activeColor: root.coral }
                RailTile { Layout.fillWidth: true; keyName: "clipart"; label: "Clipart Studio"; glyph: "✎"; activeColor: root.mint }
                Item { Layout.fillHeight: true }
                Rectangle {
                    visible: !root.compact
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 12
                    color: "transparent"
                    border.color: "#40ffffff"
                    Text { anchors.centerIn: parent; text: "?   UX test tasks"; color: "white"; font.pixelSize: 12; font.weight: Font.Bold }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#fffdf9"
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.landscape ? 72 : 66
                    color: "#fffdf9"
                    border.color: "#eee9e1"
                    border.width: 1
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: root.contentGutter
                        anchors.right: parent.right
                        anchors.rightMargin: root.contentGutter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Text { text: root.desktop.workspace === "daily" && root.landscape ? "" : (root.landscape ? "PenDesk" : "◔  PenDesk"); color: root.ink; font.pixelSize: root.landscape ? 20 : 19; font.weight: Font.Bold }
                        Item { width: Math.max(0, parent.width - (root.landscape ? 390 : 260)); height: 1; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: root.landscape ? "Stylus connected" : "Stylus"; color: "#11151c"; font.pixelSize: 14; font.weight: Font.Bold }
                        Text { text: "●"; color: "#3ac49e"; font.pixelSize: 15 }
                        Text { visible: root.landscape; text: "⌁"; color: "#11151c"; font.pixelSize: 24; font.weight: Font.Bold }
                        Text { text: "▭ 88%"; color: "#11151c"; font.pixelSize: 14; font.weight: Font.Bold }
                        Text { visible: root.landscape; text: "9:41 AM"; color: "#11151c"; font.pixelSize: 14; font.weight: Font.Bold }
                    }
                }

                Rectangle {
                    visible: !root.landscape
                    Layout.fillWidth: true
                    Layout.preferredHeight: 84
                    color: root.navy
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10
                        RailTile { Layout.fillWidth: true; keyName: "browse"; label: "Browse"; glyph: "◎"; activeColor: root.sky }
                        RailTile { Layout.fillWidth: true; keyName: "worksheets"; label: "Worksheets"; glyph: "▤"; activeColor: root.coral }
                        RailTile { Layout.fillWidth: true; keyName: "clipart"; label: "Clipart"; glyph: "✎"; activeColor: root.mint }
                    }
                }

                Flickable {
                    id: workspaceScroller
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: workspaceContent.height + root.contentGutter * 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    Column {
                        id: workspaceContent
                        x: root.contentGutter
                        y: root.contentGutter
                        width: Math.min(workspaceScroller.width - root.contentGutter * 2, root.landscape && root.desktop.workspace === "daily" ? 1750 : workspaceScroller.width - root.contentGutter * 2)
                        spacing: root.landscape ? 18 : 16

                        Row {
                            visible: root.desktop.workspace !== "daily"
                            width: parent.width
                            spacing: 16
                            Column {
                                width: (root.landscape && !root.compact) ? parent.width - 250 : parent.width
                                spacing: 4
                                Text { text: root.workspaceLabel(); color: root.ink; font.pixelSize: root.landscape ? 46 : 40; font.weight: Font.Bold }
                                Text { text: root.workspaceDescription(); color: root.muted; font.pixelSize: root.landscape ? 19 : 18; font.weight: Font.DemiBold }
                            }
                            Rectangle {
                                visible: root.landscape && !root.compact
                                width: 234
                                height: 62
                                radius: 14
                                color: "#edf5ff"
                                border.color: "#d2e2f6"
                                Column { anchors.fill: parent; anchors.margins: 10; spacing: 3
                                    Text { text: root.desktop.palm_rest ? "Palm Rest on" : "Palm Rest off"; color: root.ink; font.pixelSize: 14; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                                    Text { text: "Quality: " + (worksheetInk.lowPower ? "Low power" : "Balanced"); color: root.muted; font.pixelSize: 11; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; width: parent.width }
                                }
                            }
                        }

                        Rectangle {
                            visible: root.desktop.workspace === "worksheets"
                            width: parent.width
                            height: root.landscape ? Math.max(760, workspaceScroller.height - 112) : Math.max(1280, workspaceScroller.height - 88)
                            radius: 22
                            color: "#edf2f7"
                            border.color: "#c8d3e2"
                            border.width: 1
                            clip: true
                            Row {
                                anchors.fill: parent
                                anchors.margins: root.landscape ? 28 : 20
                                spacing: root.landscape ? 28 : 0
                                Item {
                                    id: letterPageStage
                                    width: (root.landscape && !root.compact) ? parent.width - 296 : parent.width
                                    height: parent.height

                                    Rectangle {
                                        id: letterPage
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: height * root.letterPortraitRatio
                                        height: root.landscape ? Math.min(720, parent.height - 36) : Math.min(1180, parent.height - 40)
                                        radius: 5
                                        color: "#fffefd"
                                        border.color: "#d8d4cb"
                                        border.width: 1
                                        clip: true

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: root.landscape ? 30 : 26
                                            spacing: 8
                                            Item {
                                                width: parent.width
                                                height: root.landscape ? 38 : 44
                                                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Worksheet draft"; color: root.ink; font.pixelSize: root.landscape ? 17 : 19; font.weight: Font.Bold }
                                                Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "US Letter · Portrait"; color: root.muted; font.pixelSize: root.landscape ? 10 : 11; font.weight: Font.DemiBold }
                                                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: "#e8e3da" }
                                            }
                                            InkSurface {
                                                id: worksheetInk
                                                width: parent.width
                                                height: parent.height - (root.landscape ? 46 : 52)
                                                inkColor: "#173873"
                                                onPreviewStrokeFinished: function(pointCount) { root.desktop.commitPreviewStroke(pointCount) }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: root.landscape && !root.compact
                                    width: 268
                                    height: parent.height
                                    radius: 18
                                    color: "#f8fbff"
                                    border.color: "#d4e0ef"
                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 20
                                        spacing: 16
                                        Text { text: "Page setup"; color: root.ink; font.pixelSize: 19; font.weight: Font.Bold }
                                        Text { text: "US Letter\n8.5 × 11 in\nPortrait"; color: root.muted; font.pixelSize: 14; font.weight: Font.DemiBold; lineHeight: 1.45 }
                                        Rectangle { width: parent.width; height: 1; color: "#dce4ee" }
                                        Text { text: root.desktop.committed_strokes + " strokes handed to Rust"; color: root.ink; font.pixelSize: 14; font.weight: Font.Bold; wrapMode: Text.WordWrap; width: parent.width }
                                        Text { text: "The page preview is optimized for direct pen work. Quality controls stay on the sheet so you can tune lower-end hardware without leaving the canvas."; color: root.muted; font.pixelSize: 13; lineHeight: 1.35; wrapMode: Text.WordWrap; width: parent.width }
                                        Item { height: 1; width: 1; Layout.fillHeight: true }
                                        Rectangle { width: parent.width; height: 86; radius: 14; color: "#e8f3ff"; Text { anchors.centerIn: parent; width: parent.width - 22; text: worksheetInk.lowPower ? "Low power preview\n0.75× texture · 33 ms cap" : "Balanced preview\nFull sheet texture · smooth shader"; color: root.ink; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; lineHeight: 1.35 } }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: root.desktop.workspace === "worksheets"
                            width: parent.width
                            height: root.landscape ? 142 : 184
                            radius: 18
                            color: "#fffefa"
                            border.color: "#e7e1d8"
                            Row {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12
                                SummaryCell { width: (parent.width - 24) / 3; height: parent.height; heading: "US Letter sheet"; detail: "Portrait · pen-first"; glyph: "▯"; tint: "#d6ecff" }
                                SummaryCell { width: (parent.width - 24) / 3; height: parent.height; heading: "Rust bridge"; detail: root.desktop.committed_strokes + " committed strokes"; glyph: "↗"; tint: "#e2dcff" }
                                SummaryCell { width: (parent.width - 24) / 3; height: parent.height; heading: "Hardware profile"; detail: worksheetInk.lowPower ? "0.75x texture, 33 ms cap" : "Full texture, smooth shader"; glyph: "◒"; tint: "#d5f0df" }
                            }
                        }

                        Column {
                            visible: root.desktop.workspace === "daily"
                            width: parent.width
                            spacing: root.landscape ? 18 : 14
                            Text { text: "Good morning"; color: root.ink; font.pixelSize: root.landscape ? 54 : 42; font.weight: Font.Bold }
                            Text { text: "Pick up where you left off"; color: root.muted; font.pixelSize: root.landscape ? 22 : 19; font.weight: Font.DemiBold }
                            // จำนวนคอลัมน์คำนวณจากความกว้างจริง (ขั้นต่ำ 260px/tile) แทนการ fix 3 คอลัมน์เสมอ
                            // ป้องกัน tile แคบเกินไปที่ landscape แคบ (เช่น 900x620 ซึ่ง landscape ยังเป็น true)
                            Flow {
                                width: parent.width
                                spacing: root.landscape ? 22 : 14
                                property int columns: root.landscape ? Math.max(1, Math.min(3, Math.floor(width / 260))) : 1
                                property real tileW: root.landscape ? (width - spacing * (columns - 1)) / columns : width
                                HomeLaunchTile { width: parent.tileW; height: root.landscape ? 294 : 152; keyName: "browse"; label: "Browse"; glyph: "◎"; fill: "#cfe9fb"; glyphColor: "#416ab8" }
                                HomeLaunchTile { width: parent.tileW; height: root.landscape ? 294 : 152; keyName: "worksheets"; label: "New Worksheet"; glyph: "▤"; fill: "#ff9a78"; glyphColor: "#e8f5ff" }
                                HomeLaunchTile { width: parent.tileW; height: root.landscape ? 294 : 152; keyName: "clipart"; label: "Create Clipart"; glyph: "✦"; fill: "#c7edd9"; glyphColor: "#1b2e51" }
                            }
                            Text { text: "Recent Work"; color: root.ink; font.pixelSize: root.landscape ? 25 : 22; font.weight: Font.Bold }
                            Flow {
                                width: parent.width
                                spacing: root.landscape ? 16 : 12
                                property int columns: root.landscape ? Math.max(1, Math.min(3, Math.floor(width / 220))) : 1
                                property real tileW: root.landscape ? (width - spacing * (columns - 1)) / columns : width
                                RecentWorkTile { width: parent.tileW; height: root.landscape ? 142 : 118; titleText: "Rainforest\nworksheet"; glyph: "♣"; artFill: "#6caa7c"; artInk: "#f4fee8" }
                                RecentWorkTile { width: parent.tileW; height: root.landscape ? 142 : 118; titleText: "Animal\nclipart set"; glyph: "♞"; artFill: "#ffe4a9"; artInk: "#8a5b26" }
                                RecentWorkTile { width: parent.tileW; height: root.landscape ? 142 : 118; titleText: "Math\nreferences"; glyph: "△"; artFill: "#d9d2ff"; artInk: "#315396" }
                            }
                        }

                        Rectangle {
                            visible: root.desktop.workspace === "browse" || root.desktop.workspace === "clipart"
                            width: parent.width
                            height: root.landscape ? 430 : 620
                            radius: 22
                            color: root.desktop.workspace === "browse" ? "#f6fbff" : "#f8fff9"
                            border.color: root.desktop.workspace === "browse" ? "#cddbf1" : "#cfe9d8"
                            Column {
                                anchors.fill: parent
                                anchors.margins: root.landscape ? 30 : 22
                                spacing: 14
                                Text { text: root.desktop.workspace === "browse" ? "Reference shelf" : "Clipart sketch space"; color: root.ink; font.pixelSize: root.landscape ? 28 : 26; font.weight: Font.Bold }
                                Text { text: root.desktop.workspace === "browse" ? "Keep articles, saved resources, and worksheet prompts in a calm reading area." : "Use the worksheet tools to sketch a new classroom visual, then move the final asset into your library."; color: root.muted; font.pixelSize: 16; font.weight: Font.DemiBold; width: parent.width; wrapMode: Text.WordWrap }
                                Rectangle { width: parent.width; height: parent.height - 112; radius: 16; color: "#fffefd"; border.color: "#e7e1d8"; Text { anchors.centerIn: parent; text: root.desktop.workspace === "browse" ? "Saved reference area" : "Stylus clipart canvas"; color: root.muted; font.pixelSize: 18; font.weight: Font.DemiBold } }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.dockHeight
                    color: root.navy
                    Row {
                        id: toolRow
                        anchors.centerIn: parent
                        spacing: root.landscape ? 12 : 8
                        // Undo/Redo ซ่อนไว้ก่อนจนกว่า Rust จะมี stroke-history model จริง (ดู AUDIT.md P1: preview strokes are not persisted)
                        // การแสดงปุ่มที่ปิดใช้งานถาวรกินพื้นที่ touch dock โดยไม่มีประโยชน์
                        DockButton { width: root.landscape ? (toolRow.parent.width - root.contentGutter * 2 - 24) / 3 : (toolRow.parent.width - root.contentGutter * 2 - 16) / 3; keyName: "pen"; label: "Pen"; glyph: "✎"; fill: "#b9ddff"; isPalm: false }
                        DockButton { width: root.landscape ? (toolRow.parent.width - root.contentGutter * 2 - 24) / 3 : (toolRow.parent.width - root.contentGutter * 2 - 16) / 3; keyName: "eraser"; label: "Eraser"; glyph: "◇"; fill: "#ffb0a6"; isPalm: false }
                        DockButton { width: root.landscape ? (toolRow.parent.width - root.contentGutter * 2 - 24) / 3 : (toolRow.parent.width - root.contentGutter * 2 - 16) / 3; keyName: "palm"; label: "Palm Rest"; glyph: "✋"; fill: "#c8efd7"; isPalm: true }
                    }
                }
            }
        }
    }
}
