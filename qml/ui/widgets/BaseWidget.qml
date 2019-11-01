import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13
import Qt.labs.settings 1.0

BaseWidgetForm {
    id: widgetBase
    Drag.active: dragging
    Drag.dragType: Drag.Internal

    property string widgetIdentifier

    property int defaultAlignment: 0
    property int defaultXOffset: 0
    property int defaultYOffset: 0
    property bool defaultHCenter: false
    property bool defaultVCenter: false

    property int detailPanelFontPixels: 13

    property bool dragging: false

    property string alignmentIdentifier: "%1_align".arg(widgetIdentifier);
    property string xOffsetIdentifier: "%1_x_offset".arg(widgetIdentifier);
    property string yOffsetIdentifier: "%1_y_offset".arg(widgetIdentifier);
    property string hCenterIdentifier: "%1_h_center".arg(widgetIdentifier);
    property string vCenterIdentifier: "%1_v_center".arg(widgetIdentifier);

    Component.onCompleted: {
        loadAlignment();
    }

    SequentialAnimation {
        running: dragging
        onFinished: {
            if (dragging) {
                restart()
            }
        }
        alwaysRunToEnd: true
        animations: [
            RotationAnimator { target: widgetInner; from: 0; to: 2; duration: 200 * 0.4 },
            RotationAnimator { target: widgetInner; from: 2; to: 0; duration: 200 * 0.4 },
            RotationAnimator { target: widgetInner; from: 0; to: -2; duration: 200 * 0.4 },
            RotationAnimator { target: widgetInner; from: -2; to: 0; duration: 200 * 0.4 }
        ]
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent

        onClicked: {
            if (dragging) {
                drag.target = null
                widgetControls.close()
                saveAlignment()
                loadAlignment()
                dragging = false
                globalDragLock = false
            } else if (hasWidgetDetail) {
                if (widgetDetail.visible) {
                    widgetDetail.close()
                } else {
                    if (globalDragLock) {
                        return;
                    }
                    widgetDetail.open()
                }
            }
        }

        onPressAndHold: {
            if (!dragging) {
                if (globalDragLock) {
                    return;
                }
                globalDragLock = true
                dragging = true
                /*
                 * Unlock the element anchors so it can be dragged. They'll be enabled
                 * again when the widget is done being moved, if the selected alignment
                 * type requires them.
                 */
                resetAnchors()
                drag.target = parent
                widgetControls.open()
            } else {
                drag.target = null
                widgetControls.close()
                saveAlignment()
                loadAlignment()
                dragging = false
                globalDragLock = false
            }
        }
    }

    function saveAlignment() {
        var _xOffset;
        var _yOffset;

        switch (alignmentType) {
        case 0:
            _xOffset = x;
            _yOffset = y;
            break;
        case 1:
            _xOffset = parent.width - (x + width);
            _yOffset = y;
            break;
        case 2:
            _xOffset = parent.width - (x + width);
            _yOffset = parent.height - (y + height);
            break;
        case 3:
            _xOffset = x;
            _yOffset = parent.height - (y + height);
            break;
        }

        settings.setValue(alignmentIdentifier, alignmentType);
        settings.setValue(xOffsetIdentifier, _xOffset);
        settings.setValue(yOffsetIdentifier, _yOffset);
    }

    function loadAlignment() {
        alignmentType = settings.value(alignmentIdentifier, defaultAlignment);

        /*
         * This is completely absurd and shouldn't be necessary, but here we are...
         *
         * For some reason, this returns strings on Linux and booleans on every other platform.
         */
        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter);
        if (_hCenter === "true" || _hCenter === 1 || _hCenter === true) {
            _hCenter = true;
        } else {
            _hCenter = false;
        }

        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter);
        if (_vCenter === "true" || _vCenter === 1 || _vCenter === true) {
            _vCenter = true;
        } else {
            _vCenter = false;
        }

        /*
         * Anchors have to be cleared before any of them can be set again. This is documented
         * at https://doc.qt.io/qt-5/qtquick-positioning-anchors.html#changing-anchors
         */
        resetAnchors();

        if (alignmentType === 0) {
            if (_vCenter) {
                anchors.verticalCenter = parent.verticalCenter;
            } else {
                anchors.top = parent.top;
                anchors.topMargin = settings.value(yOffsetIdentifier, defaultYOffset);
            }
            if (_hCenter) {
                anchors.horizontalCenter = parent.horizontalCenter;
            } else {
                anchors.left = parent.left;
                anchors.leftMargin = settings.value(xOffsetIdentifier, defaultXOffset);
            }
        } else if (alignmentType === 1) {
            if (_vCenter) {
                anchors.verticalCenter = parent.verticalCenter;
            } else {
                anchors.top = parent.top;
                anchors.topMargin = settings.value(yOffsetIdentifier, defaultYOffset);
            }
            if (_hCenter) {
                anchors.horizontalCenter = parent.horizontalCenter;
            } else {
                anchors.right = parent.right;
                anchors.rightMargin = settings.value(xOffsetIdentifier, defaultXOffset);
            }
        } else if (alignmentType === 2) {
            if (_vCenter) {
                anchors.verticalCenter = parent.verticalCenter;
            } else {
                anchors.bottom = parent.bottom;
                anchors.bottomMargin = settings.value(yOffsetIdentifier, defaultYOffset);
            }
            if (_hCenter) {
                anchors.horizontalCenter = parent.horizontalCenter;
            } else {
                anchors.right = parent.right;
                anchors.rightMargin = settings.value(xOffsetIdentifier, defaultXOffset);
            }
        } else if (alignmentType === 3) {
            if (_vCenter) {
                anchors.verticalCenter = parent.verticalCenter;
            } else {
                anchors.bottom = parent.bottom;
                anchors.bottomMargin = settings.value(yOffsetIdentifier, defaultYOffset);
            }
            if (_hCenter) {
                anchors.horizontalCenter = parent.horizontalCenter;
            } else {
                anchors.left = parent.left;
                anchors.leftMargin = settings.value(xOffsetIdentifier, defaultXOffset);
            }
        }
    }


    function moveUp() { widgetBase.y -= 1; }
    function moveRight() { widgetBase.x += 1; }
    function moveLeft() { widgetBase.x -= 1; }
    function moveDown() { widgetBase.y += 1; }


    function resetAnchors() {
        widgetBase.anchors.top = undefined;
        widgetBase.anchors.topMargin = 0;
        widgetBase.anchors.right = undefined;
        widgetBase.anchors.rightMargin = 0;
        widgetBase.anchors.left = undefined;
        widgetBase.anchors.leftMargin = 0;
        widgetBase.anchors.bottom = undefined;
        widgetBase.anchors.bottomMargin = 0;
        widgetBase.anchors.verticalCenter = undefined;
        widgetBase.anchors.horizontalCenter = undefined;
    }
}
