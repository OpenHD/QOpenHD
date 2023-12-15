import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: arrowWidget
    width: 64
    height: 48
    defaultYOffset: 135

    visible: settings.show_arrow

    widgetIdentifier: "arrow_widget"
    bw_verbose_name: "HOME ARROW"

    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Invert Arrow")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                NewSwitch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.arrow_invert
                    onCheckedChanged: settings.arrow_invert = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        Item {
            anchors.fill: parent
            anchors.centerIn: parent
            transform: Scale { origin.x: 32; origin.y: 12; xScale: bw_current_scale ; yScale: bw_current_scale}


            Shape {
                id: arrow
                anchors.fill: parent
                antialiasing: true
                opacity: bw_current_opacity

                ShapePath {
                    capStyle: ShapePath.RoundCap
                    strokeColor: settings.color_glow
                    fillColor: settings.color_shape
                    strokeWidth: 1
                    strokeStyle: ShapePath.SolidLine

                    startX: 32
                    startY: 24
                    PathLine { x: 26;                  y: 24 }//bottom left edge
                    PathLine { x: 26;                  y: 12  }//inner left edge
                    PathLine { x: 20;                  y: 12  }//outer left
                    PathLine { x: 32;                  y: 0  }//point
                    PathLine { x: 44;                 y: 12  }//right edge of arrow
                    PathLine { x: 38;                 y: 12  }//inner right edge
                    PathLine { x: 38;                 y: 24 }//bottom right edge
                    PathLine { x: 32;                 y: 24 }//back to start

                }

                transform: Rotation {
                    origin.x: 32;
                    origin.y: 12;
                    angle: settings.arrow_invert ? _fcMavlinkSystem.home_course : _fcMavlinkSystem.home_course-180
                }
            }
        }
    }
}

