// Full HD responsive ink preview. Visual samples remain transient; Rust owns committed state.
import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "#fffefd"
    radius: 14
    border.color: "#d8e2f0"
    clip: true

    property color inkColor: "#173873"
    property real smoothingAmount: 0.38
    property real positionSmoothing: 0.62
    property real minimumSampleDistance: 1.5
    property string qualityProfile: "balanced"
    property bool lowPower: qualityProfile === "lowPower"
    property real textureScale: lowPower ? 0.75 : 1.0
    property int textureUpdateIntervalMs: lowPower ? 33 : 0
    property var samples: []
    property bool strokeActive: false
    property int previewPointCount: samples.length
    property bool updatePending: false

    signal previewSample(real x, real y, real pressure, bool startsStroke)
    signal previewStrokeFinished(int pointCount)

    function requestTextureUpdate() {
        if (!lowPower) {
            inkTexture.scheduleUpdate()
            return
        }
        if (updatePending)
            return
        updatePending = true
        textureUpdateTimer.restart()
    }

    function addPreviewSample(x, y, pressure, startsStroke) {
        var next = { x: x, y: y, pressure: Math.max(0.2, Math.min(1.0, pressure)), startsStroke: startsStroke }
        if (!startsStroke && samples.length > 0) {
            var previous = samples[samples.length - 1]
            var deltaX = x - previous.x
            var deltaY = y - previous.y
            if (deltaX * deltaX + deltaY * deltaY < minimumSampleDistance * minimumSampleDistance)
                return
            next.x = previous.x + deltaX * positionSmoothing
            next.y = previous.y + deltaY * positionSmoothing
        }
        var updatedSamples = samples.slice(0)
        updatedSamples.push(next)
        samples = updatedSamples
        rawInk.requestPaint()
        requestTextureUpdate()
        previewSample(next.x, next.y, next.pressure, startsStroke)
    }

    function clearPreview() {
        samples = []
        rawInk.requestPaint()
        requestTextureUpdate()
    }

    onQualityProfileChanged: {
        rawInk.requestPaint()
        requestTextureUpdate()
    }

    Timer {
        id: textureUpdateTimer
        interval: Math.max(1, root.textureUpdateIntervalMs)
        repeat: false
        onTriggered: {
            root.updatePending = false
            inkTexture.scheduleUpdate()
        }
    }

    Canvas {
        id: rawInk
        width: Math.max(1, Math.round(root.width * root.textureScale))
        height: Math.max(1, Math.round(root.height * root.textureScale))
        visible: false
        onPaint: {
            var context = getContext("2d")
            context.reset()
            context.clearRect(0, 0, width, height)
            context.strokeStyle = root.inkColor
            context.lineCap = "round"
            context.lineJoin = "round"

            for (var index = 0; index < root.samples.length; ++index) {
                var point = root.samples[index]
                var drawX = point.x * root.textureScale
                var drawY = point.y * root.textureScale
                if (point.startsStroke || index === 0) {
                    context.beginPath()
                    context.arc(drawX, drawY, 2.4 * point.pressure * root.textureScale, 0, Math.PI * 2)
                    context.fillStyle = root.inkColor
                    context.fill()
                    continue
                }

                var previous = root.samples[index - 1]
                context.beginPath()
                context.lineWidth = 3.4 * point.pressure * root.textureScale
                context.moveTo(previous.x * root.textureScale, previous.y * root.textureScale)
                context.lineTo(drawX, drawY)
                context.stroke()
            }
        }
    }

    ShaderEffectSource {
        id: inkTexture
        anchors.fill: parent
        visible: false
        sourceItem: rawInk
        hideSource: true
        live: false
        mipmap: false
        samples: 0
        textureSize: Qt.size(rawInk.width, rawInk.height)
        textureMirroring: ShaderEffectSource.NoMirroring
    }

    ShaderEffect {
        id: smoothingEffect
        anchors.fill: parent
        property variant source: inkTexture
        property real smoothingAmount: root.smoothingAmount
        property real pixelStepX: 1 / Math.max(1, rawInk.width)
        property real pixelStepY: 1 / Math.max(1, rawInk.height)
        fragmentShader: root.lowPower
                        ? "qrc:/qt/qml/org/pendesk/desktop/shaders/ink_passthrough.frag.qsb"
                        : "qrc:/qt/qml/org/pendesk/desktop/shaders/ink_smooth.frag.qsb"
        blending: true
    }

    MouseArea {
        id: previewInput
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.CrossCursor
        preventStealing: true
        onPressed: function(mouse) {
            root.strokeActive = true
            root.addPreviewSample(mouse.x, mouse.y, 1.0, true)
        }
        onPositionChanged: function(mouse) {
            if (root.strokeActive)
                root.addPreviewSample(mouse.x, mouse.y, 1.0, false)
        }
        onReleased: {
            if (!root.strokeActive)
                return
            root.strokeActive = false
            root.previewStrokeFinished(root.previewPointCount)
        }
        onCanceled: {
            if (!root.strokeActive)
                return
            root.strokeActive = false
            root.previewStrokeFinished(root.previewPointCount)
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        spacing: 8
        Rectangle {
            width: root.width > root.height ? 172 : 154
            height: 32
            radius: 16
            color: "#e9f3ff"
            Text { anchors.centerIn: parent; text: root.previewPointCount + " samples · " + (root.lowPower ? "Low power" : "Balanced"); color: "#37547d"; font.pixelSize: 10; font.weight: Font.DemiBold }
        }
        Button {
            text: root.lowPower ? "Use Balanced" : "Use Low power"
            implicitHeight: 32
            onClicked: root.qualityProfile = root.lowPower ? "balanced" : "lowPower"
            background: Rectangle { radius: 16; color: "#dcecff" }
            contentItem: Text { text: parent.text; color: "#31577f"; font.pixelSize: 10; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; leftPadding: 10; rightPadding: 10 }
        }
        Button {
            text: "Clear"
            implicitHeight: 32
            onClicked: root.clearPreview()
            background: Rectangle { radius: 16; color: "#ffdfd4" }
            contentItem: Text { text: parent.text; color: "#9d4a35"; font.pixelSize: 10; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; leftPadding: 10; rightPadding: 10 }
        }
    }
}
